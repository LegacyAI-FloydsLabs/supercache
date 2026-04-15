#!/usr/bin/env bash
# supercache-repo-precommit.sh
#
# Pre-commit hook for the .supercache/ governance repo itself.
# Blocks commits that introduce version drift across the version-bearing files:
#   - VERSION
#   - README.md                             (**Version:** X.Y.Z)
#   - contracts/agent-contract.md           (**Version:** X.Y.Z, **Governance:** .supercache/ vX.Y.Z)
#   - contracts/execution-contract.md       (**Version:** X.Y.Z)
#
# Install (from repo root):
#   ln -sf ../../hooks/supercache-repo-precommit.sh .git/hooks/pre-commit
#
# This hook is ONLY for the governance repo. It auto-detects context and exits 0
# as a no-op if run in a non-governance git repo — safe to install in any repo.
#
# Defense in depth:
#   1. bootstrap.sh --bump-version X.Y.Z updates all four files atomically (prevents drift)
#   2. This hook catches drift at commit time (catches manual edits that bypass the command)
#
# If this hook blocks a commit: run 'bootstrap.sh --bump-version <canonical_version>'
# to bring everything back into lockstep.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_ROOT" ]]; then
    exit 0  # not in a git repo — no-op
fi

# Detect governance context: presence of VERSION + bootstrap.sh at repo root
if [[ ! -f "$REPO_ROOT/VERSION" ]] || [[ ! -f "$REPO_ROOT/bootstrap.sh" ]]; then
    exit 0  # not the governance repo, skip silently
fi

CANONICAL_VER="$(cat "$REPO_ROOT/VERSION" 2>/dev/null || echo "")"
if [[ -z "$CANONICAL_VER" ]]; then
    echo "[supercache-precommit] FAIL: VERSION file is empty or missing" >&2
    exit 1
fi

if ! [[ "$CANONICAL_VER" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "[supercache-precommit] FAIL: VERSION file does not contain valid semver: '$CANONICAL_VER'" >&2
    exit 1
fi

mismatches=()

check_file_version() {
    local file="$1"
    local pattern="$2"
    local label="$3"
    local path="$REPO_ROOT/$file"

    if [[ ! -f "$path" ]]; then
        echo "[supercache-precommit] WARN: expected file missing: $file" >&2
        return
    fi

    local found
    found="$(grep -Eo "$pattern" "$path" 2>/dev/null | head -1 | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' || true)"

    if [[ -z "$found" ]]; then
        echo "[supercache-precommit] WARN: no version string matching pattern in $file" >&2
        return
    fi

    if [[ "$found" != "$CANONICAL_VER" ]]; then
        mismatches+=("$label ($file): $found ≠ $CANONICAL_VER")
    fi
}

check_file_version "README.md"                       '\*\*Version:\*\* [0-9]+\.[0-9]+\.[0-9]+'                    "README.md"
check_file_version "contracts/agent-contract.md"     '\*\*Version:\*\* [0-9]+\.[0-9]+\.[0-9]+'                    "agent-contract.md (Version)"
check_file_version "contracts/agent-contract.md"     '\*\*Governance:\*\* \.supercache/ v[0-9]+\.[0-9]+\.[0-9]+'  "agent-contract.md (Governance)"
check_file_version "contracts/execution-contract.md" '\*\*Version:\*\* [0-9]+\.[0-9]+\.[0-9]+'                    "execution-contract.md"

if [[ ${#mismatches[@]} -gt 0 ]]; then
    echo "" >&2
    echo "[supercache-precommit] BLOCKED: .supercache/ version drift detected" >&2
    echo "[supercache-precommit] Canonical version (from VERSION file): $CANONICAL_VER" >&2
    echo "" >&2
    echo "[supercache-precommit] Drifted files:" >&2
    for m in "${mismatches[@]}"; do
        echo "  - $m" >&2
    done
    echo "" >&2
    echo "[supercache-precommit] Fix:  ./bootstrap.sh --bump-version $CANONICAL_VER" >&2
    echo "[supercache-precommit] Or edit the drifted files by hand to match the canonical version." >&2
    echo "" >&2
    exit 1
fi

exit 0
