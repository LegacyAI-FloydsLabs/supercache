#!/usr/bin/env bash
# critic-runner.sh — Automatic post-implementation critique sweep
# Scans governed projects, checks compliance, logs violations.
set -euo pipefail

export TZ="America/Indiana/Indianapolis"
TIMESTAMP="$(date +%Y-%m-%dT%H:%M:%S%z)"
SC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="/Volumes/SanDisk1Tb/SSOT"
LOG_FILE="$LOG_DIR/critic_sweep.log"
LOCK="/tmp/critic-runner.lock"

# Idempotency — no concurrent runs
if [ -f "$LOCK" ]; then
    PID=$(cat "$LOCK")
    if kill -0 "$PID" 2>/dev/null; then
        echo "$TIMESTAMP [SKIP] Previous run still active (PID $PID)" >> "$LOG_FILE"
        exit 0
    fi
fi
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT

echo "$TIMESTAMP [START] Critic sweep" >> "$LOG_FILE"

VIOLATIONS=0
CHECKED=0

for mount in /Volumes/SanDisk1Tb /Volumes/Storage; do
    [ -d "$mount" ] || continue
    for project in "$mount"/*/; do
        [ -d "$project" ] || continue
        name="$(basename "$project")"

        # Skip non-project dirs and untouchable zones
        case "$name" in
            Applications|InferenceCache|Library|LAIAS_AGENT_OUTPUT|SSOT|archive|PSI|.*) continue ;;
        esac

        CHECKED=$((CHECKED + 1))

        # Check FLOYD.md exists
        if [ ! -f "$project/FLOYD.md" ]; then
            echo "$TIMESTAMP [FAIL] $name — missing FLOYD.md" >> "$LOG_FILE"
            VIOLATIONS=$((VIOLATIONS + 1))
            continue
        fi

        # Check SSOT/ exists
        if [ ! -d "$project/SSOT" ]; then
            echo "$TIMESTAMP [FAIL] $name — missing SSOT/" >> "$LOG_FILE"
            VIOLATIONS=$((VIOLATIONS + 1))
        fi

        # Check Issues/ exists
        if [ ! -d "$project/Issues" ]; then
            echo "$TIMESTAMP [FAIL] $name — missing Issues/" >> "$LOG_FILE"
            VIOLATIONS=$((VIOLATIONS + 1))
        fi

        # Check for forbidden ports in common config files
        for portfile in "$project"/.env "$project"/server.py "$project"/server.js "$project"/package.json "$project"/docker-compose.yml "$project"/Makefile; do
            [ -f "$portfile" ] || continue
            if grep -qE '(port[=: ]*)(3000|3001|5000|8000|8080|8888|9000)' "$portfile" 2>/dev/null; then
                echo "$TIMESTAMP [FAIL] $name — forbidden port in $(basename "$portfile")" >> "$LOG_FILE"
                VIOLATIONS=$((VIOLATIONS + 1))
            fi
        done
    done
done

echo "$TIMESTAMP [END] Checked $CHECKED projects, $VIOLATIONS violations" >> "$LOG_FILE"
