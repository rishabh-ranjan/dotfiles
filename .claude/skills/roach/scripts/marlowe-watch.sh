#!/bin/bash
# Watch your jobs on Marlowe from anywhere: an edge-triggered loop that speaks
# only on a change (a job requeued, a pending reason that will never clear,
# the allocation running dry, the queue going empty) plus a quarter-hour
# heartbeat so silence is never a dead watcher. Everything goes over ssh.
#
#   bash marlowe-watch.sh [poll-seconds]     # default 120; ends when the queue is empty
set -uo pipefail
poll=${1:-120}
M='ssh -o BatchMode=yes marlowe export PATH=/cm/shared/apps/slurm/current/bin:$PATH SLURM_CONF=/cm/shared/apps/slurm/var/etc/slurm/slurm.conf;'
prev=""; last_beat=0; declare -A elapsed restarts

# slurm's %M is [[d-]h:]m:s; compare as seconds, not as strings
secs() { local s=${1##*-} d=0; [[ $1 == *-* ]] && d=${1%%-*}; local IFS=:; set -- $s; local t=0; for p in "$@"; do t=$((t*60 + 10#$p)); done; echo $((d*86400 + t)); }

round() {
    local q pend state="" left
    q=$($M squeue -u '$USER' -h -o '"%i %j %P %T %M %R"') || { echo "$(date +%T) ssh failed: is the ControlMaster up? (ssh -O check marlowe)"; return; }
    [[ -z $q ]] && { echo "$(date +%T) queue empty: watch over"; exit 0; }
    pend=$(echo "$q" | grep -c PENDING)
    left=$($M sshare -A marlowe-m000137-pm06 -l -n -o GrpTRESMins,GrpTRESRaw%200 | head -1 |
           awk '{match($1,/gres\/gpu=[0-9]+/); l=substr($1,RSTART+9,RLENGTH-9); match($2,/gres\/gpu=[0-9]+/); u=substr($2,RSTART+9,RLENGTH-9); printf "%d", (l-u)/60}')
    (( left < 500 )) && state+="BUDGET: ${left} GPU-h left on pm06\n"
    while read -r id name part st el reason; do
        case "$reason" in
            *AssocGrp*|*QOSMax*|*PartitionTimeLimit*|*Held*|*requeued*|*DependencyNever*)
                state+="STUCK: $id $name $part $reason\n" ;;
        esac
        if [[ $st == RUNNING && -n ${elapsed[$id]:-} ]] && (( $(secs "$el") < $(secs "${elapsed[$id]}") )); then
            state+="RESTARTED: $id $name elapsed ${elapsed[$id]} -> $el\n"
        fi
        if [[ $st == PENDING && ${elapsed[$id]:-} == *:* && ${elapsed[$id]} != 0:00 ]]; then
            state+="REQUEUED: $id $name was running ${elapsed[$id]}, now pending ($reason) -- done already? cancel it\n"
        fi
        elapsed[$id]=$el
    done <<< "$q"

    if [[ $state != "$prev" ]]; then
        printf "%s change:\n%b" "$(date +%T)" "${state:-  (clear)\n}"
        prev=$state
    fi
    if (( $(date +%s) - last_beat >= 900 )); then
        echo "$(date +%T) heartbeat: $(echo "$q" | wc -l) jobs, $pend pending, ${left} GPU-h left on pm06"
        last_beat=$(date +%s)
    fi
}

while :; do round; sleep "$poll"; done
