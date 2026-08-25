---
name: email
description: Use this skill when the user wants to read, search, send, or draft Stanford Office 365 email from the command line or via an agent. Works via the Microsoft Graph API — does NOT require Stanford IT to enable IMAP on the mailbox. Syncs to a local Maildir for use with notmuch, mutt, or similar tools.
---

# Stanford Office 365 Email (via Microsoft Graph API)

This skill lets the agent read, search, send, and draft Stanford email without requiring IMAP to be enabled by Stanford IT. It uses Microsoft Graph API with device-code auth.

> **TODO:** This skill is currently untested end-to-end. The underlying script (`scripts/office365_sync.py`) was contributed by Marcel and works in principle, but the full agent workflow (auth flow, cache location, notmuch integration) needs validation. If you hit issues, report them and/or update this skill.

## Script location

The sync script is bundled with this skill at `scripts/office365_sync.py` (relative to the skill's base directory, which the Skill runtime injects as `Base directory for this skill: <absolute-path>` at the top of this file when loaded).

**Always invoke it via that absolute path**, e.g.:

```bash
uv run "<skill-base-dir>/scripts/office365_sync.py" <command>
```

Do NOT ask the user to copy the script to `~/Mail/` — it should be run in-place from the skill cache. User-specific state (token cache, Maildir, sync state) lives under `~/Mail/` regardless of where the script itself sits.

## What this skill provides

- **Sync**: Download all mail folders into a local Maildir (`~/Mail/Stanford/`) for indexing with `notmuch`.
- **Search**: Query the mailbox via the Graph `$search` endpoint.
- **Send**: Send plain or HTML email with optional CC/BCC.
- **Read**: Fetch and display a single message by ID.
- **Folders**: List all mail folders with unread counts.

## Setup (one-time, user-side)

Before the agent can use this skill, the user must:

### 1. Install Python dependencies

The script uses `uv`'s inline script metadata (PEP 723), so you can run it directly with `uv run` and dependencies (`msal`, `requests`) install automatically on first run.

Verify `uv` is installed:

```bash
uv --version
```

If not, install it: https://docs.astral.sh/uv/getting-started/installation/

### 2. Authenticate (device-code flow)

Run the `auth` command. It prints a sign-in URL; open it in a browser, sign in, then paste the resulting `...nativeclient?code=...` URL back into the terminal (one-time).

```bash
mkdir -p ~/Mail
uv run "<skill-base-dir>/scripts/office365_sync.py" auth
```

The token cache is stored at `$OFFICE365_TOKEN_CACHE` (default `~/scratch/.secrets/office365`, alongside the other API tokens) and auto-refreshed on subsequent runs. **No password is ever stored.**

### 3. (Optional) Set up notmuch indexing

After the first sync, point `notmuch` at the Maildir:

```bash
notmuch setup    # set database.path = ~/Mail/Stanford
notmuch new
```

### 4. (Optional) Schedule periodic sync

Add a systemd timer or cron job to run `uv run "<skill-base-dir>/scripts/office365_sync.py" sync` every 10 minutes. For cron, hardcode the resolved absolute path — the skill cache path is stable across skill versions but changes on upgrade, so pin to a specific version or re-install the timer when upgrading.

## Agent usage

**Privacy principle:** This skill should only read/search email when the user **explicitly asks**. Do NOT proactively scan the mailbox — prompt injection risk is significant.

### Reading recent mail / searching

```bash
uv run "<skill-base-dir>/scripts/office365_sync.py" search "grants office"
uv run "<skill-base-dir>/scripts/office365_sync.py" folders
```

For arbitrary text queries, prefer `notmuch search` after a sync (faster, richer query syntax):

```bash
uv run "<skill-base-dir>/scripts/office365_sync.py" sync
notmuch search "from:someone@stanford.edu and date:last-week"
```

### Incremental sync

```bash
uv run "<skill-base-dir>/scripts/office365_sync.py" sync
```

Uses the stored timestamp in `~/Mail/.office365/sync_state.json` to only fetch new messages. Use `--full` to ignore the timestamp and re-check all messages (they will not be re-downloaded if the filename hash already exists locally).

### Sending mail

```bash
uv run "<skill-base-dir>/scripts/office365_sync.py" send \
  --to "recipient@stanford.edu" \
  --subject "Subject here" \
  --body "Body text"
```

For HTML emails, add `--html`. For CC/BCC, use `--cc` / `--bcc`.

**Confirm with the user before sending.** Always show the composed message and ask "Send this?" before running the command.

### Reading a specific message

```bash
uv run "<skill-base-dir>/scripts/office365_sync.py" read <message-id>
```

Message IDs are Graph API IDs (long opaque strings). You typically get them from the search output or from notmuch results.

## What to do if the skill fails

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `Auth failed` on `auth` command | Stanford O365 tenant blocks the default MSAL public client | User needs to register their own app at https://entra.microsoft.com and replace `CLIENT_ID` in the script |
| `403 Forbidden` on any Graph call | Token expired or lacks scopes | Re-run `auth` |
| `Throttled, waiting Xs...` | Rate limit (harmless, script handles it) | Wait for retry |
| `ModuleNotFoundError: msal` | uv's inline dep management not picking up the script | Run with `uv run --script "<skill-base-dir>/scripts/office365_sync.py" ...` explicitly |
| Sync runs but `notmuch` sees no mail | Maildir permissions or notmuch config | Check `~/Mail/Stanford/{new,cur,tmp}` exist, and `notmuch config` |
| Send fails with `insufficient privileges` | User declined `Mail.Send` scope during auth | Re-run `auth` and approve all scopes |

## Files and locations

- **Sync script:** `scripts/office365_sync.py` (resolved against the skill base directory — do not copy out)
- **Maildir:** `~/Mail/Stanford/` (created by the script)
- **Token cache:** `$OFFICE365_TOKEN_CACHE` (default `~/scratch/.secrets/office365`)
- **Sync state:** `~/Mail/.office365/sync_state.json`

## Security notes

- **Token is stored on disk** (encrypted by MSAL's default cache, but still sensitive). Do not commit the token cache to git.
- **The Maildir is plaintext mail.** Do not sync it to a shared location.
- **Never log or echo the access token.** The script avoids this, but be careful with `set -x` or verbose shells.
- **Stanford Confidential and HIPAA data** may be in your inbox — review Stanford's policies before storing mail locally.

## What this skill does NOT cover

- **Calendar access** — not implemented in the script.
- **Contacts** — not implemented.
- **OAuth refresh beyond token cache** — if the refresh token expires (rare, but happens after ~90 days of inactivity), re-run `auth`.
- **Multi-account support** — the script assumes one Stanford account. For personal + Stanford, run two separate copies with different `CONFIG_DIR` and `MAIL_DIR` paths.
