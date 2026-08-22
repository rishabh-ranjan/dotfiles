#!/bin/bash
# Watch your jobs on ILC: an edge-triggered loop that speaks only on a change
# (a tier or a b200 with room while something of yours is pending, a pending
# reason that will never clear, a job that restarted, the queue going empty)
# plus a quarter-hour heartbeat so silence is never a dead watcher.
#
#   bash ilc-watch.sh [poll-seconds]     # default 120; ends when the queue is empty
#
# Edit the counters to the sweep at hand; the shape is the point.
set -uo pipefail
poll=${1:-120}
prev=""; last_beat=0; declare -A elapsed

# slurm's %M is [[d-]h:]m:s; compare as seconds, not as strings
secs() { local s=${1##*-} d=0; [[ $1 == *-* ]] && d=${1%%-*}; local IFS=:; set -- $s; local t=0; for p in "$@"; do t=$((t*60 + 10#$p)); done; echo $((d*86400 + t)); }

round() {
    local q il int ilb pend bw bwfree state="" line
    q=$(squeue -u "$USER" -h -o "%i %j %q %T %b %R %M" | grep -v dev-node)
    [[ -z $q ]] && { echo "$(date +%T) queue empty: watch over"; exit 0; }
    il=$(echo "$q" | awk '$3=="il"' | wc -l)                 # claimed: running + pending
    int=$(echo "$q" | awk '$3=="il-interactive"' | wc -l)
    ilb=$(echo "$q" | awk '$3=="il" && $5 ~ /b200/' | wc -l)
    pend=$(echo "$q" | grep -c PENDING)
    bw=$(scontrol show node blackwell1)
    bwfree=$(( 8 - $(echo "$bw" | grep -oE "b200=[0-9]+" | tail -1 | cut -d= -f2) ))
    echo "$bw" | grep -q "State=.*RESERVED" && bwfree=0     # not yours to take

    (( pend > 0 && (10 - il) + (2 - int) > 0 )) && state+="PROMOTE: tier room il=$il/10 int=$int/2 with $pend pending\n"
    (( pend > 0 && bwfree > 0 && ilb < 2 ))       && state+="PROMOTE: $bwfree b200 free, il-b200 $ilb/2\n"
    while read -r id name qos st gres reason el; do
        case "$reason" in
            *ReqNodeNotAvail*|*QOSMax*|*AssocMax*|*TimeLimit*|*WallDuration*|*Held*|*requeued*)
                state+="STUCK: $id $name $qos $reason\n" ;;
        esac
        if [[ $st == RUNNING && -n ${elapsed[$id]:-} ]] && (( $(secs "$el") < $(secs "${elapsed[$id]}") )); then
            state+="RESTARTED: $id $name elapsed ${elapsed[$id]} -> $el\n"
        fi
        elapsed[$id]=$el
    done <<< "$q"

    if [[ $state != "$prev" ]]; then
        printf "%s change:\n%b" "$(date +%T)" "${state:-  (clear)\n}"
        prev=$state
    fi
    if (( $(date +%s) - last_beat >= 900 )); then
        echo "$(date +%T) heartbeat: $(echo "$q" | wc -l) jobs, $pend pending, il=$il int=$int b200free=$bwfree"
        last_beat=$(date +%s)
    fi
}

while :; do round; sleep "$poll"; done
