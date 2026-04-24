#!/usr/bin/env bash
# post-bump-sweep.sh — walk all governed projects after a supercache VERSION bump
#   and run `bootstrap.sh --doctor` (detect drift) + `--repair` (update stamp)
#   against each one.
#
# Usage:
#   bash post-bump-sweep.sh                # dry-run (--doctor only, no repair)
#   bash post-bump-sweep.sh --repair       # doctor + repair (updates stamps live)
#   bash post-bump-sweep.sh --repair --yes # skip confirmation prompt
#
# Intended cadence: run after every supercache PR merges and a `git pull` has
# updated .supercache/VERSION. Lives under .supercache/scripts/ post-merge.
#
# Discovery model: find FLOYD.md across known drives, minus obvious exclusions.
# A project registry (v1.5.0) will replace find-based discovery.
#
# Legacy AI governance — v1.4.0 —

set -euo pipefail

# -------- config --------

# Drives to scan. Matches agent-contract.md § Drive Topology.
SCAN_ROOTS=(
  "/Volumes/SanDisk1Tb"
  "/Volumes/Storage"
)

# Patterns to exclude from project discovery.
EXCLUDE_PATTERNS=(
  "node_modules"
  ".git"
  ".supercache"                    # the governance dir itself
  "reference/"                     # read-only reference tier
  "supercache.retired-"            # any retired backup
  "floyd-v5-backup-"               # time-stamped backups
  "floyd_doc_backup_"
  "dist"
  "build"
  "target"                         # rust
  "vendor"
  ".floyd-docs-backup"
)

BOOTSTRAP="/Volumes/SanDisk1Tb/.supercache/bootstrap.sh"
MODE="doctor-only"
ASSUME_YES="no"

# -------- cli --------

for arg in "$@"; do
  case "$arg" in
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

SC_VERSION="$(cat /Volumes/SanDisk1Tb/.supercache/VERSION)"
echo ".supercache/ canonical version: $SC_VERSION"
echo "Mode: $MODE"
echo ""

# -------- discovery --------

# Build exclusion regex for grep
EXCLUDE_REGEX="$(IFS='|'; echo "${EXCLUDE_PATTERNS[*]}")"

PROJECTS=()
for root in "${SCAN_ROOTS[@]}"; do
  if [[ ! -d "$root" ]]; then
    echo "WARN: scan root not present: $root (skipping)"
    continue
  fi
  while IFS= read -r floyd_path; do
    project_dir="$(dirname "$floyd_path")"
    # Skip if path matches any exclude pattern
    if echo "$project_dir" | grep -qE "$EXCLUDE_REGEX"; then
      continue
    fi
    PROJECTS+=("$project_dir")
  done < <(find "$root" -maxdepth 4 -name "FLOYD.md" -type f 2>/dev/null)
done

# Deduplicate (bash 3.2-compatible; macOS ships bash 3.2 by default)
TMP_PROJECTS=()
while IFS= read -r line; do
  [[ -n "$line" ]] && TMP_PROJECTS+=("$line")
done < <(printf '%s\n' "${PROJECTS[@]}" | sort -u)
PROJECTS=("${TMP_PROJECTS[@]}")

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
  if "$BOOTSTRAP" --doctor "$p"; then
    :
  else
    echo "  (doctor reported issues)"
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
