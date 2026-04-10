#!/usr/bin/env bash
# log-rotate.sh — Nightly log compression and archival
set -euo pipefail

export TZ="America/Indiana/Indianapolis"
TIMESTAMP="$(date +%Y-%m-%dT%H:%M:%S%z)"
LOG_DIR="/Volumes/SanDisk1Tb/SSOT"
LOG_FILE="$LOG_DIR/log_rotate.log"
LOCK="/tmp/log-rotate.lock"
MAX_AGE_DAYS=14
ARCHIVE_DIR="/Volumes/SanDisk1Tb/SSOT/log_archive"

if [ -f "$LOCK" ]; then
    PID=$(cat "$LOCK")
    if kill -0 "$PID" 2>/dev/null; then
        echo "$TIMESTAMP [SKIP] Previous run still active (PID $PID)" >> "$LOG_FILE"
        exit 0
    fi
fi
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT

mkdir -p "$ARCHIVE_DIR"

echo "$TIMESTAMP [START] Log rotation" >> "$LOG_FILE"

ROTATED=0
BYTES_FREED=0

# CaptainPhantasy logs
for f in ~/20260*.log; do
    [ -f "$f" ] || continue
    age=$(( ($(date +%s) - $(stat -f %m "$f")) / 86400 ))
    if [ "$age" -gt "$MAX_AGE_DAYS" ]; then
        size=$(stat -f %z "$f")
        gzip -c "$f" > "$ARCHIVE_DIR/$(basename "$f").gz" && rm "$f"
        ROTATED=$((ROTATED + 1))
        BYTES_FREED=$((BYTES_FREED + size))
    fi
done

# .floyd/ logs over 14 days in all projects
for mount in /Volumes/SanDisk1Tb /Volumes/Storage; do
    find "$mount" -maxdepth 3 -path "*/.floyd/*.log" -mtime +$MAX_AGE_DAYS 2>/dev/null | while read -r f; do
        size=$(stat -f %z "$f")
        gzip -c "$f" > "$ARCHIVE_DIR/$(basename "$f").gz" && rm "$f"
        ROTATED=$((ROTATED + 1))
        BYTES_FREED=$((BYTES_FREED + size))
    done
done

MB_FREED=$((BYTES_FREED / 1048576))
echo "$TIMESTAMP [END] Rotated $ROTATED files, freed ~${MB_FREED}MB" >> "$LOG_FILE"
