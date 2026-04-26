#!/usr/bin/env bash
# governance-bump.sh — single-command deploy for Legacy AI .supercache/ governance bumps.
#
# Driven by a "pending plan" written by the legacy-governance-assistant skill.
# Idempotent: each operation checks current state and skips if already applied.
#
# Usage:
#   governance-bump.sh status        # show current state and pending plan
#   governance-bump.sh simulate      # dry-run: print what would happen
#   governance-bump.sh apply         # execute the plan (edits, commit, push, sweep)
#   governance-bump.sh verify        # post-apply verification (100% confidence gate)
#   governance-bump.sh clean         # remove pending/ after successful apply
#   governance-bump.sh help          # show this message
#
# Plan layout: /Volumes/SanDisk1Tb/.supercache/scripts/pending/
#   metadata.yaml          target_version, previous_version, scope
#   changelog.md           entry to prepend to CHANGELOG.md (newest first)
#   commit-message.txt     full git commit message body
#   verify-rules.txt       optional — additional grep checks for verify step
#
# Governance: this script is itself part of .supercache/. Modifications go through
# the same PR path as any contract change.

set -euo pipefail

SUPERCACHE="/Volumes/SanDisk1Tb/.supercache"
PENDING="$SUPERCACHE/scripts/pending"
SCRIPTS="$SUPERCACHE/scripts"
SWEEP="$SCRIPTS/post-bump-sweep.sh"

# tput-style colors with no-tty fallback
if [ -t 1 ]; then
  GREEN="\033[0;32m"; YELLOW="\033[0;33m"; RED="\033[0;31m"
  BLUE="\033[0;34m"; DIM="\033[2m"; RESET="\033[0m"
else
  GREEN=""; YELLOW=""; RED=""; BLUE=""; DIM=""; RESET=""
fi

log()  { printf "${BLUE}[gov]${RESET}  %s\n" "$*"; }
ok()   { printf "${GREEN}[ok]${RESET}   %s\n" "$*"; }
warn() { printf "${YELLOW}[warn]${RESET} %s\n" "$*"; }
err()  { printf "${RED}[err]${RESET}  %s\n" "$*" >&2; }
skip() { printf "${DIM}[skip]${RESET} %s\n" "$*"; }

usage() {
  cat <<'EOF'
governance-bump.sh — Legacy AI governance deploy harness

Usage:
  governance-bump.sh <subcommand>

Subcommands:
  status     Show current VERSION and pending plan target
  simulate   Dry-run: show what would change, don't write anything
  apply      Apply the pending plan (edits + commit + push + sweep)
  verify     Run verification queries against current state (100% gate)
  clean      Remove pending/ directory after successful apply
  help       Show this message

Plan directory:
  /Volumes/SanDisk1Tb/.supercache/scripts/pending/

The legacy-governance-assistant skill (under ~/.claude/skills/) writes the plan;
this harness executes it. Run `simulate` first if you want to see the plan
without applying.
EOF
}

require_pending() {
  if [ ! -d "$PENDING" ]; then
    err "No pending bump found at $PENDING"
    err "Have an instance of Claude with the legacy-governance-assistant skill prepare a plan first."
    exit 1
  fi
  for f in metadata.yaml changelog.md commit-message.txt; do
    if [ ! -f "$PENDING/$f" ]; then
      err "Missing required plan file: $PENDING/$f"
      exit 1
    fi
  done
}

read_metadata() {
  TARGET_VERSION=$(grep -E '^target_version:' "$PENDING/metadata.yaml" \
    | head -1 | sed -E 's/^target_version: *//; s/^"//; s/"$//' | tr -d "'")
  PREVIOUS_VERSION=$(grep -E '^previous_version:' "$PENDING/metadata.yaml" \
    | head -1 | sed -E 's/^previous_version: *//; s/^"//; s/"$//' | tr -d "'")
  if [ -z "${TARGET_VERSION:-}" ] || [ -z "${PREVIOUS_VERSION:-}" ]; then
    err "metadata.yaml must define target_version and previous_version"
    exit 1
  fi
}

# Idempotent header bump using literal substring match
# Usage: bump_header <relative_file> <prev_text> <new_text>
bump_header() {
  local rel="$1" prev="$2" new="$3"
  local full="$SUPERCACHE/$rel"
  if [ ! -f "$full" ]; then
    err "$rel: not found"
    return 1
  fi
  if grep -qF "$new" "$full"; then
    skip "$rel: already has '$new'"
    return 0
  fi
  if grep -qF "$prev" "$full"; then
    # Use a delimiter unlikely to appear in either string
    local pe ne
    pe=$(printf '%s' "$prev" | sed 's/[][\.*^$/&]/\\&/g')
    ne=$(printf '%s' "$new"  | sed 's/[][\.*^$/&]/\\&/g')
    sed -i '' "s|$pe|$ne|g" "$full"
    ok "$rel: bumped — '$prev' → '$new'"
  else
    warn "$rel: neither '$prev' nor '$new' present — skipping"
  fi
}

# Prepend the changelog.md entry to CHANGELOG.md, idempotently
prepend_changelog() {
  local cl="$SUPERCACHE/CHANGELOG.md"
  local entry="$PENDING/changelog.md"
  if [ ! -f "$cl" ]; then
    err "CHANGELOG.md not found"
    return 1
  fi
  local first
  first=$(head -1 "$entry")
  if grep -qF "$first" "$cl"; then
    skip "CHANGELOG.md: entry already present (matches '$first')"
    return 0
  fi
  local marker
  marker=$(awk '/^Newest first\./{print NR; exit}' "$cl")
  if [ -z "$marker" ]; then
    err "CHANGELOG.md: 'Newest first.' marker not found"
    return 1
  fi
  local sep
  sep=$(awk -v s="$marker" 'NR>s && /^---$/ {print NR; exit}' "$cl")
  if [ -z "$sep" ]; then
    err "CHANGELOG.md: '---' separator after 'Newest first.' not found"
    return 1
  fi
  local tmp
  tmp=$(mktemp)
  awk -v sep="$sep" -v ef="$entry" '
    NR == sep {
      print
      print ""
      while ((getline line < ef) > 0) print line
      print ""
      next
    }
    { print }
  ' "$cl" > "$tmp"
  mv "$tmp" "$cl"
  ok "CHANGELOG.md: prepended entry"
}

# ------- subcommands -------

cmd_status() {
  local current
  current=$(cat "$SUPERCACHE/VERSION" 2>/dev/null || echo "?")
  log "Current .supercache/VERSION: $current"
  if [ -d "$PENDING" ] && [ -f "$PENDING/metadata.yaml" ]; then
    read_metadata
    log "Pending plan: $PREVIOUS_VERSION → $TARGET_VERSION"
    log "Plan files:"
    ls -la "$PENDING" | sed 's/^/    /'
  else
    log "No pending bump."
  fi
}

cmd_simulate() {
  require_pending
  read_metadata
  log "SIMULATE: $PREVIOUS_VERSION → $TARGET_VERSION"
  echo
  log "Would update:"
  echo "    VERSION → $TARGET_VERSION (current: $(cat "$SUPERCACHE/VERSION" 2>/dev/null || echo '?'))"
  echo "    README.md header → $TARGET_VERSION"
  echo "    contracts/agent-contract.md headers → $TARGET_VERSION (Version + Governance)"
  echo
  log "Would prepend to CHANGELOG.md (first 8 lines):"
  echo "    ----"
  head -8 "$PENDING/changelog.md" | sed 's/^/    /'
  echo "    [...]"
  echo "    ----"
  echo
  log "Would commit + push with message:"
  echo "    ----"
  sed 's/^/    /' "$PENDING/commit-message.txt"
  echo "    ----"
  echo
  log "Would then run: $SWEEP --repair"
  echo
  log "(simulation complete — no changes made)"
}

cmd_apply() {
  require_pending
  read_metadata

  log "APPLY: $PREVIOUS_VERSION → $TARGET_VERSION"

  # 1. VERSION
  if [ "$(cat "$SUPERCACHE/VERSION" 2>/dev/null || echo '')" = "$TARGET_VERSION" ]; then
    skip "VERSION: already at $TARGET_VERSION"
  else
    echo "$TARGET_VERSION" > "$SUPERCACHE/VERSION"
    ok "VERSION: $PREVIOUS_VERSION → $TARGET_VERSION"
  fi

  # 2. README.md header
  bump_header "README.md" "**Version:** $PREVIOUS_VERSION" "**Version:** $TARGET_VERSION"

  # 3. agent-contract.md headers (only if file declares previous version)
  bump_header "contracts/agent-contract.md" "**Version:** $PREVIOUS_VERSION" "**Version:** $TARGET_VERSION"
  bump_header "contracts/agent-contract.md" "**Governance:** .supercache/ v$PREVIOUS_VERSION" "**Governance:** .supercache/ v$TARGET_VERSION"

  # 4. CHANGELOG.md
  prepend_changelog

  # 5. git: stage tracked changes only
  cd "$SUPERCACHE"
  log "Staging tracked changes (excludes untracked credentials-manifest.yaml)…"
  # Stage everything that's already tracked AND modified, plus any explicitly listed manifest files
  git add -u VERSION README.md CHANGELOG.md contracts/agent-contract.md 2>/dev/null || true
  # Add any new manifest files (likely v1.5.0 voice-registry.yaml and similar)
  git add manifests/*.yaml 2>/dev/null || true

  if git diff --cached --quiet; then
    skip "git: nothing to commit (already committed?)"
  else
    log "Committing…"
    git commit -F "$PENDING/commit-message.txt"
    ok "Commit landed: $(git rev-parse --short HEAD)"

    log "Pushing to origin/$(git branch --show-current)…"
    if git push origin "$(git branch --show-current)"; then
      ok "Pushed."
    else
      err "Push failed. The local commit landed; resolve remote and retry git push."
      return 1
    fi
  fi

  # 6. Sweep
  if [ -x "$SWEEP" ]; then
    log "Running post-bump-sweep.sh --repair to stamp downstream projects…"
    "$SWEEP" --repair
    ok "Sweep complete."
  else
    warn "post-bump-sweep.sh not executable; skipping (would have stamped downstream projects)."
  fi

  echo
  ok "v$TARGET_VERSION deployed. Now run '$(basename "$0") verify' for the 100% gate."
}

cmd_verify() {
  require_pending
  read_metadata

  log "VERIFY: $TARGET_VERSION"
  local fail=0

  # VERSION
  if [ "$(cat "$SUPERCACHE/VERSION" 2>/dev/null || echo '')" = "$TARGET_VERSION" ]; then
    ok "VERSION = $TARGET_VERSION"
  else
    err "VERSION mismatch (got: $(cat "$SUPERCACHE/VERSION" 2>/dev/null || echo '?'))"
    fail=1
  fi

  # README header
  if grep -qF "**Version:** $TARGET_VERSION" "$SUPERCACHE/README.md"; then
    ok "README.md header at $TARGET_VERSION"
  else
    err "README.md header not at $TARGET_VERSION"
    fail=1
  fi

  # agent-contract headers
  for h in "**Version:** $TARGET_VERSION" "**Governance:** .supercache/ v$TARGET_VERSION"; do
    if grep -qF "$h" "$SUPERCACHE/contracts/agent-contract.md"; then
      ok "agent-contract.md has '$h'"
    else
      err "agent-contract.md missing '$h'"
      fail=1
    fi
  done

  # CHANGELOG entry presence
  local first
  first=$(head -1 "$PENDING/changelog.md")
  if grep -qF "$first" "$SUPERCACHE/CHANGELOG.md"; then
    ok "CHANGELOG.md has the v$TARGET_VERSION entry"
  else
    err "CHANGELOG.md missing v$TARGET_VERSION entry (looking for: '$first')"
    fail=1
  fi

  # git head references the version (loose check)
  cd "$SUPERCACHE"
  if git log -1 --pretty=%B 2>/dev/null | grep -qF "v$TARGET_VERSION"; then
    ok "HEAD commit references v$TARGET_VERSION"
  else
    warn "HEAD commit doesn't reference v$TARGET_VERSION literally — check 'git log -1' manually if uncertain"
  fi

  # Optional extra rules from verify-rules.txt — one grep per line:
  # format: <relative_file>::<literal_grep_string>
  if [ -f "$PENDING/verify-rules.txt" ]; then
    while IFS= read -r rule; do
      [ -z "$rule" ] && continue
      rel="${rule%%::*}"
      needle="${rule#*::}"
      if grep -qF "$needle" "$SUPERCACHE/$rel" 2>/dev/null; then
        ok "$rel contains '$needle'"
      else
        err "$rel missing '$needle'"
        fail=1
      fi
    done < "$PENDING/verify-rules.txt"
  fi

  # downstream stamps (best-effort: count repos at $TARGET_VERSION)
  local stamped=0 unstamped=0
  while read -r f; do
    if [ -f "$f" ]; then
      if [ "$(cat "$f")" = "$TARGET_VERSION" ]; then
        stamped=$((stamped+1))
      else
        unstamped=$((unstamped+1))
      fi
    fi
  done < <(find /Volumes/SanDisk1Tb /Volumes/Storage -maxdepth 4 -type f -name '.supercache_version' 2>/dev/null)
  log "Downstream projects: $stamped at v$TARGET_VERSION, $unstamped at older versions"

  echo
  if [ "$fail" -eq 0 ]; then
    ok "VERIFY PASSED — v$TARGET_VERSION at 100% confidence"
    return 0
  else
    err "VERIFY FAILED — $fail check(s) failed"
    return 1
  fi
}

cmd_clean() {
  if [ -d "$PENDING" ]; then
    rm -rf "$PENDING"
    ok "Cleared pending bump at $PENDING"
  else
    skip "No pending bump to clean"
  fi
}

# ------- dispatch -------

case "${1:-help}" in
  status)   cmd_status ;;
  simulate) cmd_simulate ;;
  apply)    cmd_apply ;;
  verify)   cmd_verify ;;
  clean)    cmd_clean ;;
  help|--help|-h) usage ;;
  *) usage; exit 1 ;;
esac
