#!/bin/bash

LOG_FILE="$(dirname "$0")/health_log.txt"
THRESHOLD=80

get_cpu_usage() {
    local total1 idle1 total2 idle2
    read -r total1 idle1 < <(awk '/^cpu / {idle=$5+$6; total=0; for (i=2;i<=NF;i++) total+=$i; print total, idle}' /proc/stat)
    sleep 1
    read -r total2 idle2 < <(awk '/^cpu / {idle=$5+$6; total=0; for (i=2;i<=NF;i++) total+=$i; print total, idle}' /proc/stat)

    local total_diff=$((total2 - total1))
    local idle_diff=$((idle2 - idle1))

    if [ "$total_diff" -le 0 ]; then
        echo "0.0"
        return
    fi
    awk -v t="$total_diff" -v i="$idle_diff" 'BEGIN {printf "%.1f", (t - i) / t * 100}'
}

get_mem_usage() {
    free | awk '/^Mem:/ {
        if (NF >= 7) printf "%.1f", ($2 - $7) / $2 * 100
        else printf "%.1f", ($2 - $4 - $6) / $2 * 100
    }'
}

get_disk_usage() {
    df -P / | awk 'NR==2 {gsub(/%/, "", $5); print $5}'
}

cpu_usage="$(get_cpu_usage)"
mem_usage="$(get_mem_usage)"
disk_usage="$(get_disk_usage)"

timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
entry="[$timestamp] CPU: ${cpu_usage}% | Memory: ${mem_usage}% | Disk: ${disk_usage}%"

echo "$entry" >> "$LOG_FILE"
echo "$entry"

if [ "$disk_usage" -gt "$THRESHOLD" ]; then
    echo "[WARNING] Disk space high!"
fi
