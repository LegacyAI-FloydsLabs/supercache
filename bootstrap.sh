#!/usr/bin/env bash
# =============================================================================
# Legacy AI — bootstrap.sh
# Zero-assumption entry point for project initialization and governance.
# READS from .supercache/ (never writes to it). WRITES to the target project dir.
#
# Usage:
#   bootstrap.sh --init [dir]      Initialize governance in a project directory
#   bootstrap.sh --info [dir]      Show project orientation (SSOT, issues, agents)
#   bootstrap.sh --verify [dir]    Compliance check — pass/fail per artifact
#   bootstrap.sh --repair [dir]    Fix missing/outdated artifacts
#   bootstrap.sh --archive [dir]   Graceful project shutdown
#   bootstrap.sh --health          Scan all drives for compliance
#   bootstrap.sh --version         Print .supercache/ version
#
# Environment:
#   SUPERCACHE_ROOT   Override .supercache/ location (default: auto-detect)
# =============================================================================
set -euo pipefail

# --- Locate .supercache/ ---
find_supercache() {
    if [[ -n "${SUPERCACHE_ROOT:-}" ]]; then
        echo "$SUPERCACHE_ROOT"
        return
    fi
    local dir="$1"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/.supercache/VERSION" ]]; then
            echo "$dir/.supercache"
            return
        fi
        dir="$(dirname "$dir")"
    done
    # Check common mount points
    for mount in /Volumes/SanDisk1Tb /Volumes/Storage /Volumes/T7; do
        if [[ -f "$mount/.supercache/VERSION" ]]; then
            echo "$mount/.supercache"
            return
        fi
    done
    echo ""
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SC_ROOT="${SUPERCACHE_ROOT:-$SCRIPT_DIR}"

if [[ ! -f "$SC_ROOT/VERSION" ]]; then
    SC_ROOT="$(find_supercache "$(pwd)")"
fi

if [[ -z "$SC_ROOT" || ! -f "$SC_ROOT/VERSION" ]]; then
    echo "[FATAL] Cannot locate .supercache/. Set SUPERCACHE_ROOT or run from a governed drive."
    exit 1
fi

SC_VERSION="$(cat "$SC_ROOT/VERSION")"
TEMPLATES="$SC_ROOT/templates"
CONTRACTS="$SC_ROOT/contracts"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# --- Commands ---

cmd_version() {
    echo "Legacy AI .supercache/ v${SC_VERSION}"
    echo "Location: $SC_ROOT"
}

cmd_init() {
    local target="${1:-.}"
    target="$(cd "$target" && pwd)"
    local project_name="$(basename "$target")"

    info "Initializing governance in: $target"
    info "Using .supercache/ v${SC_VERSION} at: $SC_ROOT"

    # Create project directories
    mkdir -p "$target/SSOT" "$target/Issues" "$target/.floyd"

    # FLOYD.md — only if it doesn't exist (never overwrite project-specific content)
    if [[ ! -f "$target/FLOYD.md" ]]; then
        sed "s/{{PROJECT_NAME}}/$project_name/g; s/{{VERSION}}/$SC_VERSION/g; s|{{SUPERCACHE_PATH}}|$SC_ROOT|g; s/{{DATE}}/$(date +%Y-%m-%d)/g" \
            "$TEMPLATES/floyd-md-template.md" > "$target/FLOYD.md"
        ok "Created FLOYD.md"
    else
        warn "FLOYD.md already exists — skipping (will not overwrite project-specific content)"
    fi

    # SSOT
    if [[ ! -f "$target/SSOT/README.md" ]]; then
        sed "s/{{PROJECT_NAME}}/$project_name/g; s/{{DATE}}/$(date +%Y-%m-%d)/g" \
            "$TEMPLATES/ssot-template.md" > "$target/SSOT/README.md"
        ok "Created SSOT/README.md"
    else
        warn "SSOT/README.md already exists — skipping"
    fi

    # Issues
    if [[ ! -f "$target/Issues/README.md" ]]; then
        sed "s/{{PROJECT_NAME}}/$project_name/g; s/{{DATE}}/$(date +%Y-%m-%d)/g" \
            "$TEMPLATES/issues-template.md" > "$target/Issues/README.md"
        ok "Created Issues/README.md"
    else
        warn "Issues/README.md already exists — skipping"
    fi

    # Agent log
    if [[ ! -f "$target/.floyd/agent_log.jsonl" ]]; then
        touch "$target/.floyd/agent_log.jsonl"
        ok "Created .floyd/agent_log.jsonl"
    fi

    # Version stamp
    echo "$SC_VERSION" > "$target/.floyd/.supercache_version"
    ok "Stamped .supercache/ version: $SC_VERSION"

    echo ""
    ok "Governance initialized for '$project_name'"
    info "Run 'bootstrap.sh --verify $target' to confirm compliance."
}

cmd_info() {
    local target="${1:-.}"
    target="$(cd "$target" && pwd)"
    local project_name="$(basename "$target")"

    echo ""
    echo "=== Project: $project_name ==="
    echo "Path: $target"
    echo ".supercache/ version: $SC_VERSION"
    echo ""

    # FLOYD.md
    if [[ -f "$target/FLOYD.md" ]]; then
        ok "FLOYD.md present ($(wc -l < "$target/FLOYD.md") lines)"
    else
        fail "FLOYD.md missing"
    fi

    # SSOT
    if [[ -d "$target/SSOT" ]]; then
        local ssot_count
        ssot_count=$(find "$target/SSOT" -type f | wc -l | tr -d ' ')
        ok "SSOT/ present ($ssot_count files)"
    else
        fail "SSOT/ missing"
    fi

    # Issues
    if [[ -d "$target/Issues" ]]; then
        local issue_count
        issue_count=$(find "$target/Issues" -type f | wc -l | tr -d ' ')
        ok "Issues/ present ($issue_count files)"
    else
        fail "Issues/ missing"
    fi

    # Agent log
    if [[ -f "$target/.floyd/agent_log.jsonl" ]]; then
        local log_lines
        log_lines=$(wc -l < "$target/.floyd/agent_log.jsonl" | tr -d ' ')
        ok "Agent log present ($log_lines entries)"
    else
        warn "No agent log found"
    fi

    # Version check
    if [[ -f "$target/.floyd/.supercache_version" ]]; then
        local proj_ver
        proj_ver="$(cat "$target/.floyd/.supercache_version")"
        if [[ "$proj_ver" == "$SC_VERSION" ]]; then
            ok "Version match: $proj_ver"
        else
            warn "Version drift: project=$proj_ver, .supercache=$SC_VERSION"
        fi
    else
        warn "No version stamp — run --init or --repair"
    fi
}

cmd_verify() {
    local target="${1:-.}"
    target="$(cd "$target" && pwd)"
    local project_name="$(basename "$target")"
    local pass=0
    local total=0

    echo ""
    echo "=== Compliance Check: $project_name ==="

    check() {
        total=$((total + 1))
        if eval "$2"; then
            ok "$1"
            pass=$((pass + 1))
        else
            fail "$1"
        fi
    }

    check "FLOYD.md exists" "[[ -f '$target/FLOYD.md' ]]"
    check "SSOT/ directory exists" "[[ -d '$target/SSOT' ]]"
    check "Issues/ directory exists" "[[ -d '$target/Issues' ]]"
    check ".floyd/ directory exists" "[[ -d '$target/.floyd' ]]"
    check "Agent log exists" "[[ -f '$target/.floyd/agent_log.jsonl' ]]"
    check "Version stamp exists" "[[ -f '$target/.floyd/.supercache_version' ]]"

    if [[ -f "$target/.floyd/.supercache_version" ]]; then
        local proj_ver
        proj_ver="$(cat "$target/.floyd/.supercache_version")"
        check "Version current ($proj_ver == $SC_VERSION)" "[[ '$proj_ver' == '$SC_VERSION' ]]"
    fi

    echo ""
    if [[ $pass -eq $total ]]; then
        ok "PASS: $pass/$total checks passed"
        return 0
    else
        fail "INCOMPLETE: $pass/$total checks passed"
        return 1
    fi
}

cmd_repair() {
    local target="${1:-.}"
    target="$(cd "$target" && pwd)"

    info "Repairing governance in: $target"

    # Run init (it's idempotent — skips existing files)
    cmd_init "$target"

    # Update version stamp
    echo "$SC_VERSION" > "$target/.floyd/.supercache_version"
    ok "Version stamp updated to $SC_VERSION"
}

cmd_archive() {
    local target="${1:-.}"
    target="$(cd "$target" && pwd)"
    local project_name="$(basename "$target")"
    local archive_date="$(date +%Y-%m-%d)"

    info "Archiving project: $project_name"

    # Write archive marker
    cat > "$target/.floyd/ARCHIVED" <<EOF
Project: $project_name
Archived: $archive_date
.supercache/ version: $SC_VERSION
Archived by: $(whoami)
EOF

    ok "Archive marker written to .floyd/ARCHIVED"
    info "To complete archival, move this directory to Google Drive Floyd_Ecosystem/archives/"
}

cmd_health() {
    echo ""
    echo "=== Legacy AI Governance Health Check ==="
    echo ".supercache/ v${SC_VERSION}"
    echo "Date: $(date)"
    echo ""

    local total_projects=0
    local compliant=0
    local non_compliant=0

    for mount in /Volumes/SanDisk1Tb /Volumes/Storage /Volumes/T7; do
        if [[ ! -d "$mount" ]]; then
            warn "Drive not mounted: $mount"
            continue
        fi

        echo ""
        info "Scanning: $mount"

        # Check drive-level governance
        if [[ -f "$mount/FLOYD.md" ]]; then
            ok "  Drive-level FLOYD.md present"
        else
            fail "  Drive-level FLOYD.md missing"
        fi

        # Find project directories (those with FLOYD.md)
        while IFS= read -r floyd_file; do
            local proj_dir="$(dirname "$floyd_file")"
            # Skip drive root and .supercache
            if [[ "$proj_dir" == "$mount" ]] || [[ "$proj_dir" == *".supercache"* ]]; then
                continue
            fi
            total_projects=$((total_projects + 1))
            local proj_name="$(basename "$proj_dir")"

            if cmd_verify "$proj_dir" > /dev/null 2>&1; then
                ok "  $proj_name — compliant"
                compliant=$((compliant + 1))
            else
                fail "  $proj_name — non-compliant"
                non_compliant=$((non_compliant + 1))
            fi
        done < <(find "$mount" -maxdepth 2 -name "FLOYD.md" -type f 2>/dev/null)
    done

    echo ""
    echo "=== Summary ==="
    echo "Total projects scanned: $total_projects"
    echo "Compliant: $compliant"
    echo "Non-compliant: $non_compliant"

    if [[ $non_compliant -eq 0 && $total_projects -gt 0 ]]; then
        ok "All projects compliant"
    elif [[ $total_projects -eq 0 ]]; then
        warn "No governed projects found. Run --init on project directories."
    else
        fail "$non_compliant project(s) need attention. Run --repair on each."
    fi
}

# --- Main ---
case "${1:-}" in
    --init)    cmd_init "${2:-.}" ;;
    --info)    cmd_info "${2:-.}" ;;
    --verify)  cmd_verify "${2:-.}" ;;
    --repair)  cmd_repair "${2:-.}" ;;
    --archive) cmd_archive "${2:-.}" ;;
    --health)  cmd_health ;;
    --version) cmd_version ;;
    *)
        echo "Legacy AI bootstrap.sh v${SC_VERSION:-unknown}"
        echo ""
        echo "Usage: bootstrap.sh <command> [directory]"
        echo ""
        echo "Commands:"
        echo "  --init [dir]     Initialize governance in a project directory"
        echo "  --info [dir]     Show project orientation"
        echo "  --verify [dir]   Compliance check (pass/fail)"
        echo "  --repair [dir]   Fix missing/outdated artifacts"
        echo "  --archive [dir]  Mark project for archival"
        echo "  --health         Scan all drives for compliance"
        echo "  --version        Print version"
        exit 1
        ;;
esac
