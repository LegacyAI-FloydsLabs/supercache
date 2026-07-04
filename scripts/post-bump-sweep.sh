#!/usr/bin/env bash
# post-bump-sweep.sh — walk all governed projects after a supercache VERSION bump
#   and run `bootstrap.sh --verify` (detect drift) + `--repair` (update stamp)
#   against each one.
#
# Usage:
#   bash post-bump-sweep.sh                # dry-run (--verify only, no repair)
#   bash post-bump-sweep.sh --repair       # verify + repair (updates stamps live)
#   bash post-bump-sweep.sh --repair --yes # skip confirmation prompt
#
# Intended cadence: run after every supercache PR merges and a `git pull` has
# updated .supercache/VERSION. Lives under .supercache/scripts/ post-merge.
#
# Discovery model: find FLOYD.md across known drives, minus obvious exclusions.
# A project registry (v1.5.0) will replace find-based discovery.
#
# Legacy AI governance — v1.7.2 —

set -euo pipefail

# -------- config --------

# Drives to scan. Matches agent-contract.md § Drive Topology.
SCAN_ROOTS=(
  "/Volumes/SanDisk1Tb"
  "/Volumes/Storage"
)

# Match AXIOM governed-root inventory depth unless overridden by env.
MAX_DEPTH="${MAX_DEPTH:-7}"

# Discovery backend:
#   auto/find      use pruned find traversal
#   spotlight      use macOS metadata index
DISCOVERY_BACKEND="${DISCOVERY_BACKEND:-spotlight}"

# Patterns to exclude from project discovery.
EXCLUDE_PATTERNS=(
  "(^|/)node_modules(/|$)"
  "(^|/)\\.git(/|$)"
  "(^|/)\\.supercache(/|$)"        # the governance dir itself
  "reference/"                     # read-only reference tier
  "references/"
  "docs/source/"                   # documentation source snapshots
  "\\.claude/worktrees"            # Claude worktree copies
  "worktrees/"
  "quarantine"                     # forensic/reference quarantine copies
  "\\.floyd/supercache-staging"    # generated staging copy
  "omp-harness-storage/tmp"        # generated test/runtime artifacts
  "pytest-of-"                     # pytest temporary governed roots
  "pytest-"                        # pytest temporary governed roots
  "supercache.retired-"            # any retired backup
  "retired"
  "floyd-v5-backup-"               # time-stamped backups
  "floyd_doc_backup_"
  "backup-storage-"                # drive-root backup snapshots (e.g. backup-storage-2026-04-15)
  "backup"
  "(^|/)dist(/|$)"
  "(^|/)build(/|$)"
  "(^|/)target(/|$)"               # rust
  "(^|/)vendor(/|$)"
  ".floyd-docs-backup"
  "\\.floyd/agent"                 # agent scaffolds/templates; not real projects
  "\\.omp/skills"                  # embedded skill/tooling package, not project root
)

# Directory names to prune during find traversal. EXCLUDE_PATTERNS remains the
# final guard for path-fragment exclusions after discovery.
PRUNE_DIR_NAMES=(
  ".git"
  ".supercache"
  "node_modules"
  "reference"
  "references"
  "worktrees"
  "quarantine"
  "dist"
  "build"
  "target"
  "vendor"
  "retired"
  "backup"
)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUPERCACHE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BOOTSTRAP="$SUPERCACHE_ROOT/bootstrap.sh"
MODE="doctor-only"
ASSUME_YES="no"

# -------- cli --------

for arg in "$@"; do
  case "$arg" in
    --doctor) MODE="doctor-only" ;;
    --repair) MODE="doctor-and-repair" ;;
    --yes|-y) ASSUME_YES="yes" ;;
    -h|--help)
      sed -n '2,20p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown arg: $arg" >&2
      exit 2
      ;;
  esac
done

# -------- pre-flight --------

if [[ ! -x "$BOOTSTRAP" ]]; then
  echo "ERROR: bootstrap.sh not found or not executable: $BOOTSTRAP" >&2
  exit 1
fi

SC_VERSION="$(cat "$SUPERCACHE_ROOT/VERSION")"
echo ".supercache/ canonical version: $SC_VERSION"
echo "Mode: $MODE"
echo "Max depth: $MAX_DEPTH"
echo "Discovery backend: $DISCOVERY_BACKEND"
echo ""

# -------- discovery --------

# Build exclusion regex for grep
EXCLUDE_REGEX="$(IFS='|'; echo "${EXCLUDE_PATTERNS[*]}")"

should_skip_project() {
  local project_dir="$1"
  local lower_dir
  lower_dir="$(printf '%s' "$project_dir" | tr '[:upper:]' '[:lower:]')"
  echo "$lower_dir" | grep -qE "$EXCLUDE_REGEX"
}

discover_floyd_files() {
  local root="$1"
  local prune_expr=()
  local name

  if [[ "$DISCOVERY_BACKEND" == "spotlight" ]]; then
    if ! command -v mdfind >/dev/null 2>&1; then
      echo "ERROR: DISCOVERY_BACKEND=spotlight but mdfind is not available" >&2
      return 1
    fi
    mdfind -onlyin "$root" 'kMDItemFSName == "FLOYD.md"' 2>/dev/null
    return
  elif [[ "$DISCOVERY_BACKEND" != "auto" && "$DISCOVERY_BACKEND" != "find" ]]; then
    echo "ERROR: unsupported DISCOVERY_BACKEND: $DISCOVERY_BACKEND" >&2
    return 2
  fi

  for name in "${PRUNE_DIR_NAMES[@]}"; do
    if [[ ${#prune_expr[@]} -gt 0 ]]; then
      prune_expr+=("-o")
    fi
    prune_expr+=("-name" "$name")
  done

  prune_expr+=(
    "-o" "-path" "*/docs/source"
    "-o" "-path" "*/.claude/worktrees"
    "-o" "-path" "*/.floyd/agent"
    "-o" "-path" "*/.floyd/supercache-staging"
    "-o" "-path" "*/.omp/skills"
    "-o" "-path" "*/omp-harness-storage/tmp"
    "-o" "-name" "pytest-of-*"
    "-o" "-name" "pytest-*"
    "-o" "-name" "supercache.retired-*"
    "-o" "-name" "floyd-v5-backup-*"
    "-o" "-name" "floyd_doc_backup_*"
    "-o" "-name" "backup-storage-*"
    "-o" "-name" ".floyd-docs-backup"
  )

  find "$root" -maxdepth "$MAX_DEPTH" \
    \( "${prune_expr[@]}" \) -prune \
    -o -name "FLOYD.md" -type f -print 2>/dev/null
}

PROJECTS=()
for root in "${SCAN_ROOTS[@]}"; do
  if [[ ! -d "$root" ]]; then
    echo "WARN: scan root not present: $root (skipping)"
    continue
  fi
  while IFS= read -r floyd_path; do
    project_dir="$(dirname "$floyd_path")"
    # Skip if path matches any exclude pattern
    if should_skip_project "$project_dir"; then
      continue
    fi
    PROJECTS+=("$project_dir")
  done < <(discover_floyd_files "$root")
done

# Deduplicate (bash 3.2-compatible; macOS ships bash 3.2 by default)
TMP_PROJECTS=()
if [[ ${#PROJECTS[@]} -gt 0 ]]; then
  while IFS= read -r line; do
    [[ -n "$line" ]] && TMP_PROJECTS+=("$line")
  done < <(printf '%s\n' "${PROJECTS[@]}" | sort -u)
fi
PROJECTS=()
if [[ ${#TMP_PROJECTS[@]} -gt 0 ]]; then
  PROJECTS=("${TMP_PROJECTS[@]}")
fi

if [[ ${#PROJECTS[@]} -eq 0 ]]; then
  echo "No governed projects discovered. Nothing to do."
  exit 0
fi

echo "Discovered ${#PROJECTS[@]} governed project(s):"
for p in "${PROJECTS[@]}"; do
  stamp_file="$p/.floyd/.supercache_version"
  if [[ -f "$stamp_file" ]]; then
    proj_ver="$(cat "$stamp_file")"
    if [[ "$proj_ver" == "$SC_VERSION" ]]; then
      status="CURRENT ($proj_ver)"
    else
      status="DRIFT ($proj_ver → $SC_VERSION)"
    fi
  else
    status="UNSTAMPED"
  fi
  printf "  %-60s %s\n" "$p" "$status"
done
echo ""

# -------- confirmation --------

if [[ "$MODE" == "doctor-and-repair" && "$ASSUME_YES" != "yes" ]]; then
  read -rp "Proceed with --repair against all ${#PROJECTS[@]} projects? [y/N] " ans
  case "$ans" in
    y|Y|yes|YES) ;;
    *) echo "Aborted."; exit 0 ;;
  esac
fi

# -------- sweep --------

FAIL_COUNT=0
OK_COUNT=0

for p in "${PROJECTS[@]}"; do
  echo "━━━ $p ━━━"
  if "$BOOTSTRAP" --verify "$p"; then
    :
  else
    echo "  (verify reported issues)"
  fi

  if [[ "$MODE" == "doctor-and-repair" ]]; then
    if "$BOOTSTRAP" --repair "$p"; then
      OK_COUNT=$((OK_COUNT + 1))
    else
      echo "  REPAIR FAILED"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  fi
  echo ""
done

# -------- summary --------

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Sweep complete."
echo "  Projects visited:  ${#PROJECTS[@]}"
if [[ "$MODE" == "doctor-and-repair" ]]; then
  echo "  Repaired OK:       $OK_COUNT"
  echo "  Repair failures:   $FAIL_COUNT"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $FAIL_COUNT -gt 0 ]]; then
  exit 1
fi
