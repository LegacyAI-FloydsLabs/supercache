#!/usr/bin/env bash
# Pre-commit hook — READS execution contract from .supercache/, enforces at commit time.
# Install: symlink or copy to .git/hooks/pre-commit in any governed project.
set -euo pipefail

SC_ROOT="${SUPERCACHE_ROOT:-}"
if [[ -z "$SC_ROOT" ]]; then
    dir="$(pwd)"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/.supercache/VERSION" ]]; then
            SC_ROOT="$dir/.supercache"
            break
        fi
        dir="$(dirname "$dir")"
    done
fi

if [[ -z "$SC_ROOT" ]]; then
    echo "[pre-commit] Warning: .supercache/ not found. Skipping governance check."
    exit 0
fi

# Check that staged files don't include anything in .supercache/
SUPERCACHE_CHANGES=$(git diff --cached --name-only | grep "^\.supercache/" || true)
if [[ -n "$SUPERCACHE_CHANGES" ]]; then
    echo "[pre-commit] BLOCKED: Attempted to commit changes to .supercache/"
    echo "[pre-commit] .supercache/ is READ-ONLY. Changes go through GitHub PR only."
    echo "[pre-commit] Files blocked:"
    echo "$SUPERCACHE_CHANGES" | sed 's/^/  /'
    exit 1
fi

echo "[pre-commit] Governance check passed."
exit 0
