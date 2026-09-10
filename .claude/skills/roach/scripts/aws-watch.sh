#!/bin/bash
# Watch your jobs on AWS: an edge-triggered loop that speaks only on a change
# (a job requeued from a reclaimed spot node, a pending job EC2 is not
# fulfilling, a node down, the queue going empty) plus a quarter-hour
# heartbeat with this month's spend so silence is never a dead watcher.
#
#   bash aws-watch.sh [poll-seconds]     # default 120; ends when the queue is empty
set -uo pipefail
poll=${1:-120}
A='ssh -o BatchMode=yes aws'
set -a; . ~/scratch/.secrets/aws; set +a
prev=""; last_beat=0; declare -A elapsed pending_since

secs() { local s=${1##*-} d=0; [[ $1 == *-* ]] && d=${1%%-*}; local IFS=:; set -- $s; local t=0; for p in "$@"; do t=$((t*60 + 10#$p)); done; echo $((d*86400 + t)); }

spend() {
    aws ce get-cost-and-usage --time-period "Start=$(date +%Y-%m-01),End=$(date -d tomorrow +%Y-%m-%d)" \
        --granularity MONTHLY --metrics UnblendedCost --query 'ResultsByTime[0].Total.UnblendedCost.Amount' --output text 2>/dev/null | cut -c1-8
}

round() {
    local q state="" now down
    q=$($A squeue -h -o '"%i %j %P %T %M %R"') || { echo "$(date +%T) ssh aws failed"; return; }
    [[ -z $q ]] && { echo "$(date +%T) queue empty: watch over (nodes scale down in 5 min; spend this month \$$(spend))"; exit 0; }
    now=$(date +%s)
    down=$($A sinfo -h -o '"%D %t %E"' | grep -E 'down|drain' || true)
    [[ -n $down ]] && state+="NODES: $down\n"
    while read -r id name part st el reason; do
        if [[ $st == PENDING ]]; then
            : "${pending_since[$id]:=$now}"
            (( now - pending_since[$id] > 600 )) && state+="NOT LAUNCHING: $id $name $part pending $(( (now - pending_since[$id]) / 60 )) min ($reason) -- EC2 capacity or quota? check clustermgtd\n"
        else
            unset "pending_since[$id]"
        fi
        if [[ $st == RUNNING && -n ${elapsed[$id]:-} ]] && (( $(secs "$el") < $(secs "${elapsed[$id]}") )); then
            state+="RESTARTED: $id $name elapsed ${elapsed[$id]} -> $el\n"
        fi
        if [[ $st == PENDING && ${elapsed[$id]:-} == *:* && ${elapsed[$id]} != 0:00 ]]; then
            state+="REQUEUED: $id $name was running ${elapsed[$id]}, now pending ($reason) -- spot reclaimed? resumes if it checkpointed\n"
        fi
        elapsed[$id]=$el
    done <<< "$q"

    if [[ $state != "$prev" ]]; then
        printf "%s change:\n%b" "$(date +%T)" "${state:-  (clear)\n}"
        prev=$state
    fi
    if (( now - last_beat >= 900 )); then
        echo "$(date +%T) heartbeat: $(echo "$q" | wc -l) jobs, $(echo "$q" | grep -c PENDING) pending, spend this month \$$(spend)"
        last_beat=$now
    fi
}

while :; do round; sleep "$poll"; done
