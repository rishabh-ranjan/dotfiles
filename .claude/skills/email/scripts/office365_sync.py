#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "msal>=1.28",
#     "requests>=2.31",
# ]
# ///
"""
Office 365 Mail Sync via Microsoft Graph API.

Syncs emails to local Maildir format for use with notmuch, and supports
sending and searching without IMAP.

Usage:
    uv run ~/Mail/office365_sync.py auth
    uv run ~/Mail/office365_sync.py sync [--full]
    uv run ~/Mail/office365_sync.py send --to <addr> --subject <subj> --body <body>
    uv run ~/Mail/office365_sync.py search <query>
    uv run ~/Mail/office365_sync.py folders
    uv run ~/Mail/office365_sync.py read <message-id>
"""

import argparse
import hashlib
import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import msal
import requests

# --- Configuration -----------------------------------------------------------

MAIL_DIR = Path.home() / "Mail" / "Stanford"
CONFIG_DIR = Path.home() / "Mail" / ".office365"
TOKEN_CACHE = Path(os.environ.get("OFFICE365_TOKEN_CACHE", Path.home() / "scratch" / ".secrets" / "office365"))
STATE_FILE = CONFIG_DIR / "sync_state.json"

# Microsoft Office public client — works with most O365 tenants.
# If your org blocks this, register your own app at https://entra.microsoft.com
# and replace this ID.
CLIENT_ID = "d3590ed6-52b3-4102-aeff-aad2292ab01c"
AUTHORITY = "https://login.microsoftonline.com/organizations"
SCOPES = ["Mail.ReadWrite", "Mail.Send"]

GRAPH = "https://graph.microsoft.com/v1.0"
PAGE_SIZE = 250  # max messages per API page (Graph allows up to 1000)

# --- Auth --------------------------------------------------------------------


def get_app():
    """Create MSAL app with persistent token cache."""
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)

    cache = msal.SerializableTokenCache()
    if TOKEN_CACHE.exists():
        cache.deserialize(TOKEN_CACHE.read_text())

    app = msal.PublicClientApplication(
        CLIENT_ID,
        authority=AUTHORITY,
        token_cache=cache,
    )
    return app, cache


def save_cache(cache):
    TOKEN_CACHE.parent.mkdir(parents=True, exist_ok=True)
    TOKEN_CACHE.write_text(cache.serialize())
    TOKEN_CACHE.chmod(0o600)


def get_token():
    """Get a valid access token, refreshing or re-authenticating as needed."""
    app, cache = get_app()

    accounts = app.get_accounts()
    if accounts:
        result = app.acquire_token_silent(SCOPES, account=accounts[0])
        if result and "access_token" in result:
            save_cache(cache)
            return result["access_token"]

    redirect_uri = "https://login.microsoftonline.com/common/oauth2/nativeclient"
    flow = app.initiate_auth_code_flow(scopes=SCOPES, redirect_uri=redirect_uri)
    print()
    print("Open this URL in a browser and sign in:")
    print(flow["auth_uri"])
    print()
    print("After signing in, the browser lands on a blank page whose URL contains ?code=...")
    print("Copy the full URL from the address bar and paste it here.", flush=True)
    pasted = input("Redirect URL: ").strip()
    from urllib.parse import urlparse, parse_qs
    resp = {k: v[0] for k, v in parse_qs(urlparse(pasted).query).items()}
    result = app.acquire_token_by_auth_code_flow(flow, resp)
    if "access_token" not in result:
        print(f"Auth failed: {result.get('error_description', result)}")
        sys.exit(1)

    save_cache(cache)
    return result["access_token"]


def headers(token):
    return {"Authorization": f"Bearer {token}"}


# --- Graph helpers -----------------------------------------------------------


def graph_get(token, url, params=None, retries=3):
    """GET with retry on throttle."""
    for attempt in range(retries):
        resp = requests.get(url, headers=headers(token), params=params)
        if resp.status_code == 429:
            wait = int(resp.headers.get("Retry-After", 5))
            print(f"  Throttled, waiting {wait}s...")
            time.sleep(wait)
            continue
        resp.raise_for_status()
        return resp
    resp.raise_for_status()


def paginate(token, url, params=None, key="value"):
    """Iterate through all pages of a Graph collection."""
    while url:
        resp = graph_get(token, url, params=params)
        data = resp.json()
        yield from data.get(key, [])
        url = data.get("@odata.nextLink")
        params = None  # nextLink already has params


# --- Maildir -----------------------------------------------------------------


def ensure_maildir(path):
    for sub in ("new", "cur", "tmp"):
        (path / sub).mkdir(parents=True, exist_ok=True)


def msg_filename(graph_id, is_read=False):
    """Stable filename from Graph message ID."""
    h = hashlib.sha256(graph_id.encode()).hexdigest()[:24]
    flags = "S" if is_read else ""
    return f"{h}:2,{flags}"


def msg_exists(maildir, graph_id):
    """Check if a message is already stored locally."""
    h = hashlib.sha256(graph_id.encode()).hexdigest()[:24]
    return (
        any((maildir / "cur").glob(f"{h}*"))
        or any((maildir / "new").glob(f"{h}*"))
    )


def save_message(maildir, graph_id, mime_bytes, is_read=False):
    """Write a message to Maildir using the tmp→target atomic move."""
    ensure_maildir(maildir)
    fname = msg_filename(graph_id, is_read)
    target_dir = maildir / ("cur" if is_read else "new")
    tmp_path = maildir / "tmp" / fname
    target_path = target_dir / fname
    tmp_path.write_bytes(mime_bytes)
    tmp_path.rename(target_path)


# --- Sync --------------------------------------------------------------------


FOLDER_NAME_MAP = {
    "Inbox": "",  # root maildir IS the Inbox
    "Sent Items": ".Sent",
    "Drafts": ".Drafts",
    "Deleted Items": ".Trash",
    "Junk Email": ".Junk",
    "Archive": ".Archive",
}


def folder_to_maildir_path(display_name):
    """Map an O365 folder name to a Maildir subdirectory."""
    if display_name in FOLDER_NAME_MAP:
        suffix = FOLDER_NAME_MAP[display_name]
    else:
        suffix = "." + display_name.replace("/", ".").replace(" ", "_")
    return MAIL_DIR / suffix.lstrip(".") if suffix == "" else MAIL_DIR / suffix


def get_folders(token):
    """Get all mail folders (including one level of children)."""
    folders = list(
        paginate(token, f"{GRAPH}/me/mailFolders", params={"$top": 100})
    )
    parents = list(folders)
    for f in parents:
        children = list(
            paginate(
                token,
                f"{GRAPH}/me/mailFolders/{f['id']}/childFolders",
                params={"$top": 100},
            )
        )
        for c in children:
            c["displayName"] = f"{f['displayName']}/{c['displayName']}"
        folders.extend(children)
    return folders


def sync_folder(token, folder_id, folder_name, maildir_path, state, full=False):
    """Sync one folder. Returns (new_count, skipped_count)."""
    ensure_maildir(maildir_path)

    state_key = f"folder:{folder_id}"
    last_sync = state.get(state_key)

    params = {
        "$top": PAGE_SIZE,
        "$orderby": "receivedDateTime desc",
        "$select": "id,receivedDateTime,isRead",
    }
    if last_sync and not full:
        params["$filter"] = f"receivedDateTime ge {last_sync}"

    url = f"{GRAPH}/me/mailFolders/{folder_id}/messages"

    synced = 0
    skipped = 0

    for msg in paginate(token, url, params=params):
        mid = msg["id"]
        if msg_exists(maildir_path, mid):
            skipped += 1
            continue

        # Download raw MIME
        try:
            mime_resp = graph_get(token, f"{GRAPH}/me/messages/{mid}/$value")
            save_message(maildir_path, mid, mime_resp.content, msg.get("isRead", False))
            synced += 1
        except Exception as e:
            print(f"    Failed to download message: {e}")

    state[state_key] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    return synced, skipped


def cmd_sync(token, full=False):
    state = {}
    if STATE_FILE.exists():
        state = json.loads(STATE_FILE.read_text())

    folders = get_folders(token)
    print(f"Found {len(folders)} mail folders\n")

    total_new = 0
    total_skip = 0

    for f in folders:
        name = f["displayName"]
        count = f.get("totalItemCount", "?")
        mdir = folder_to_maildir_path(name)

        label = f"  {name} ({count} items)"
        print(label, end="", flush=True)

        try:
            n, s = sync_folder(token, f["id"], name, mdir, state, full=full)
            total_new += n
            total_skip += s
            if n:
                print(f" -> {n} new")
            else:
                print(" (up to date)")
        except Exception as e:
            print(f" ERROR: {e}")

    STATE_FILE.write_text(json.dumps(state, indent=2))
    print(f"\nDone: {total_new} new messages, {total_skip} already local")
    if total_new:
        print("Run `notmuch new` to index new messages.")


# --- Send --------------------------------------------------------------------


def cmd_send(token, to, subject, body, cc=None, bcc=None, html=False):
    message = {
        "subject": subject,
        "body": {
            "contentType": "HTML" if html else "Text",
            "content": body,
        },
        "toRecipients": [
            {"emailAddress": {"address": a.strip()}} for a in to.split(",")
        ],
    }
    if cc:
        message["ccRecipients"] = [
            {"emailAddress": {"address": a.strip()}} for a in cc.split(",")
        ]
    if bcc:
        message["bccRecipients"] = [
            {"emailAddress": {"address": a.strip()}} for a in bcc.split(",")
        ]

    resp = requests.post(
        f"{GRAPH}/me/sendMail",
        headers={**headers(token), "Content-Type": "application/json"},
        json={"message": message, "saveToSentItems": True},
    )
    resp.raise_for_status()
    print("Sent!")


# --- Search ------------------------------------------------------------------


def cmd_search(token, query, top=25):
    params = {
        "$search": f'"{query}"',
        "$top": top,
        "$select": "id,subject,from,receivedDateTime,bodyPreview",
        "$orderby": "receivedDateTime desc",
    }
    # $search and $orderby can't combine on all tenants; fall back if needed
    try:
        msgs = list(paginate(token, f"{GRAPH}/me/messages", params=params))
    except requests.HTTPError:
        del params["$orderby"]
        msgs = list(paginate(token, f"{GRAPH}/me/messages", params=params))

    if not msgs:
        print("No results.")
        return

    for m in msgs:
        date = m.get("receivedDateTime", "")[:16].replace("T", " ")
        sender = m.get("from", {}).get("emailAddress", {}).get("address", "?")
        subj = m.get("subject", "(no subject)")
        preview = (m.get("bodyPreview") or "")[:120]
        print(f"[{date}]  {sender}  <id:{m['id']}>")
        print(f"  {subj}")
        if preview:
            print(f"  {preview}")
        print()


# --- Folders -----------------------------------------------------------------


def cmd_folders(token):
    folders = get_folders(token)
    for f in folders:
        count = f.get("totalItemCount", "?")
        unread = f.get("unreadItemCount", 0)
        tag = f" ({unread} unread)" if unread else ""
        print(f"  {f['displayName']}  [{count}]{tag}")


# --- Read a message ----------------------------------------------------------


def cmd_markread(token, message_id):
    resp = requests.patch(f"{GRAPH}/me/messages/{message_id}", headers={**headers(token), "Content-Type": "application/json"}, json={"isRead": True})
    resp.raise_for_status()
    print("Marked read.")


def cmd_read(token, message_id):
    """Fetch and print a single message by Graph ID or search for it."""
    params = {"$select": "subject,from,toRecipients,ccRecipients,receivedDateTime,body"}
    resp = graph_get(token, f"{GRAPH}/me/messages/{message_id}", params=params)
    m = resp.json()

    print(f"From: {m['from']['emailAddress']['address']}")
    to = ", ".join(r["emailAddress"]["address"] for r in m.get("toRecipients", []))
    print(f"To: {to}")
    cc = ", ".join(r["emailAddress"]["address"] for r in m.get("ccRecipients", []))
    if cc:
        print(f"Cc: {cc}")
    print(f"Date: {m['receivedDateTime']}")
    print(f"Subject: {m['subject']}")
    print()
    # Print plain text from body (strip basic HTML if needed)
    body = m.get("body", {}).get("content", "")
    if m.get("body", {}).get("contentType") == "html":
        # Basic HTML stripping — good enough for terminal display
        import re

        body = re.sub(r"<br\s*/?>", "\n", body, flags=re.I)
        body = re.sub(r"<[^>]+>", "", body)
        body = body.replace("&nbsp;", " ").replace("&amp;", "&")
        body = body.replace("&lt;", "<").replace("&gt;", ">")
    print(body.strip())


# --- CLI ---------------------------------------------------------------------


def main():
    p = argparse.ArgumentParser(
        description="Office 365 ↔ local Maildir sync via Graph API"
    )
    sub = p.add_subparsers(dest="cmd")

    sub.add_parser("auth", help="Authenticate (or re-authenticate)")
    sub.add_parser("folders", help="List mail folders")

    sp_sync = sub.add_parser("sync", help="Sync mail to local Maildir")
    sp_sync.add_argument(
        "--full", action="store_true", help="Full sync (ignore last-sync timestamp)"
    )

    sp_send = sub.add_parser("send", help="Send an email")
    sp_send.add_argument("--to", required=True)
    sp_send.add_argument("--subject", required=True)
    sp_send.add_argument("--body", required=True)
    sp_send.add_argument("--cc")
    sp_send.add_argument("--bcc")
    sp_send.add_argument("--html", action="store_true")

    sp_search = sub.add_parser("search", help="Search emails via Graph API")
    sp_search.add_argument("query")
    sp_search.add_argument("--top", type=int, default=25)

    sp_read = sub.add_parser("read", help="Read a message by Graph ID")
    sp_read.add_argument("message_id")
    sp_mr = sub.add_parser("markread", help="Mark a message as read by Graph ID")
    sp_mr.add_argument("message_id")

    args = p.parse_args()
    if not args.cmd:
        p.print_help()
        return

    token = get_token()

    match args.cmd:
        case "auth":
            print("Authenticated successfully!")
        case "sync":
            cmd_sync(token, full=args.full)
        case "send":
            cmd_send(token, args.to, args.subject, args.body, args.cc, args.bcc, args.html)
        case "markread":
            cmd_markread(token, args.message_id)
        case "search":
            cmd_search(token, args.query, args.top)
        case "folders":
            cmd_folders(token)
        case "read":
            cmd_read(token, args.message_id)


if __name__ == "__main__":
    main()
