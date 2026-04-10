#!/usr/bin/env bash
# state-monitor.sh — Detect orphaned session_state.json files and log for resume
set -euo pipefail

export TZ="America/Indiana/Indianapolis"
TIMESTAMP="$(date +%Y-%m-%dT%H:%M:%S%z)"
LOG_DIR="/Volumes/SanDisk1Tb/SSOT"
LOG_FILE="$LOG_DIR/state_monitor.log"
LOCK="/tmp/state-monitor.lock"
STALE_MINUTES=30

if [ -f "$LOCK" ]; then
    PID=$(cat "$LOCK")
    if kill -0 "$PID" 2>/dev/null; then
        echo "$TIMESTAMP [SKIP] Previous run still active (PID $PID)" >> "$LOG_FILE"
        exit 0
    fi
fi
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT

ORPHANED=0

for mount in /Volumes/SanDisk1Tb /Volumes/Storage; do
    [ -d "$mount" ] || continue
    find "$mount" -maxdepth 3 -path "*/.floyd/session_state.json" -mmin +$STALE_MINUTES 2>/dev/null | while read -r f; do
        project="$(dirname "$(dirname "$f")")"
        project_name="$(basename "$project")"
        echo "$TIMESTAMP [ORPHAN] $project_name — stale session_state.json (>$STALE_MINUTES min)" >> "$LOG_FILE"
        ORPHANED=$((ORPHANED + 1))
    done
done

echo "$TIMESTAMP [END] Found $ORPHANED orphaned sessions" >> "$LOG_FILE"
