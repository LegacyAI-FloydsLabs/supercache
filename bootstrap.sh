#!/usr/bin/env bash
# =============================================================================
# Legacy AI — bootstrap.sh
# Zero-assumption entry point for project initialization and governance.
# READS from .supercache/ (never writes to it). WRITES to the target project dir.
#
# Usage:
#   bootstrap.sh --init [dir]                   Initialize governance in a project directory
#   bootstrap.sh --info [dir]                   Show project orientation (SSOT, issues, agents)
#   bootstrap.sh --verify [dir]                 Compliance check — pass/fail per artifact
#   bootstrap.sh --doctor [dir]                 Alias for --verify (backward compatibility)
#   bootstrap.sh --repair [dir]                 Fix missing/outdated artifacts
#   bootstrap.sh --bump-version X.Y.Z           Bump .supercache/ version in lockstep across all files
#   bootstrap.sh --archive [dir]                Graceful project shutdown
#   bootstrap.sh --health                       Scan all drives for compliance
#   bootstrap.sh --version                      Print .supercache/ version
#
# Agent model:
#   FLOYD.md is the canonical project spec. Required for every project.
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
    # Check common mount points (T7 is OFF LIMITS — Time Machine target, never scan)
    for mount in /Volumes/SanDisk1Tb /Volumes/Storage; do
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

valid_supercache_path() {
    local target="$1"
    local path="$target/.supercache"

    if [[ -L "$path" ]]; then
        [[ "$(cd -P "$path" && pwd)" == "$SC_ROOT" ]]
        return
    fi

    if [[ -d "$path" && -f "$path/VERSION" ]]; then
        [[ "$(cat "$path/VERSION")" == "$SC_VERSION" ]]
        return
    fi

    return 1
}

sync_supercache_path() {
    local target="$1"
    local path="$target/.supercache"
    local archive
    local suffix=0

    if valid_supercache_path "$target"; then
        ok ".supercache path current"
        return 0
    fi

    if [[ ! -e "$path" && ! -L "$path" ]]; then
        ln -s "$SC_ROOT" "$path"
        ok "Linked .supercache -> $SC_ROOT"
        return 0
    fi

    warn ".supercache exists but is not a current canonical symlink/copy: $path"
    archive="$target/.supercache.retired-$(date +%Y%m%d-%H%M%S)"
    while [[ -e "$archive" || -L "$archive" ]]; do
        suffix=$((suffix + 1))
        archive="$target/.supercache.retired-$(date +%Y%m%d-%H%M%S)-$suffix"
    done

    mv "$path" "$archive"
    ok "Retired stale .supercache artifact to: $archive"
    ln -s "$SC_ROOT" "$path"
    ok "Linked .supercache -> $SC_ROOT"
    return 0
}

sync_governance_headers() {
    local target="$1"
    local -a files=()

    [[ -f "$target/FLOYD.md" ]] && files+=("$target/FLOYD.md")

    local f
    if [[ -d "$target/SSOT" ]]; then
        for f in "$target"/SSOT/*.md; do
            [[ -f "$f" ]] && files+=("$f")
        done
    fi
    if [[ -d "$target/Issues" ]]; then
        for f in "$target"/Issues/*.md; do
            [[ -f "$f" ]] && files+=("$f")
        done
    fi

    if [[ ${#files[@]} -eq 0 ]]; then
        warn "No markdown governance headers found to refresh"
        return 0
    fi

    python3 - "$SC_VERSION" "${files[@]}" <<'PY'
import re
import stat
import sys
from pathlib import Path

version = sys.argv[1]
updated = []

for raw in sys.argv[2:]:
    path = Path(raw)
    try:
        lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    except OSError:
        continue

    changed = False
    has_version = False
    has_governance = False
    limit = min(40, len(lines))
    for idx in range(limit):
        newline = "\n" if lines[idx].endswith("\n") else ""
        text = lines[idx].rstrip("\n")
        if re.match(r"^\*\*Version:\*\*\s*.+$", text):
            has_version = True
        next_text = re.sub(r"^\*\*Version:\*\*\s*.+$", f"**Version:** {version}", text)
        if re.match(r"^\*\*Governance:\*\*\s*\.supercache/\s*v.+$", text):
            has_governance = True
        next_text = re.sub(
            r"^\*\*Governance:\*\*\s*\.supercache/\s*v.+$",
            f"**Governance:** .supercache/ v{version}",
            next_text,
        )
        if next_text != text:
            lines[idx] = next_text + newline
            changed = True

    if path.name in {"FLOYD.md"} and (not has_version or not has_governance):
        insert_at = 0
        if lines and lines[0].strip() == "---":
            for idx in range(1, min(40, len(lines))):
                if lines[idx].strip() == "---":
                    insert_at = idx + 1
                    break
        elif lines and lines[0].lstrip().startswith("#"):
            insert_at = 1

        insert = []
        if insert_at > 0 and lines[insert_at - 1].strip():
            insert.append("\n")
        if not has_version:
            insert.append(f"**Version:** {version}\n")
        if not has_governance:
            insert.append(f"**Governance:** .supercache/ v{version}\n")
        if insert_at < len(lines) and lines[insert_at].strip():
            insert.append("\n")
        lines[insert_at:insert_at] = insert
        changed = True

    if changed:
        mode = path.stat().st_mode
        if not (mode & stat.S_IWUSR):
            path.chmod(mode | stat.S_IWUSR)
        path.write_text("".join(lines), encoding="utf-8")
        if path.stat().st_mode != mode:
            path.chmod(mode)
        updated.append(str(path))

for item in updated:
    print(f"header-updated: {item}")
PY
}

install_governed_precommit_hook() {
    local target="$1"
    local git_dir="$target/.git"
    local hook_dir="$git_dir/hooks"
    local hook="$hook_dir/pre-commit"

    if [[ ! -d "$git_dir" ]]; then
        info "No .git directory — skipping pre-commit hook install"
        return 0
    fi

    mkdir -p "$hook_dir"

    if [[ -e "$hook" || -L "$hook" ]]; then
        if ! grep -q "Installed by .supercache/bootstrap.sh repair." "$hook" 2>/dev/null; then
            info "pre-commit hook already exists — leaving unchanged"
            return 0
        fi
    fi

    cat > "$hook" <<'HOOK'
#!/usr/bin/env bash
# Legacy AI governed pre-commit hook.
# Installed by .supercache/bootstrap.sh repair.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

if [[ -x "$REPO_ROOT/.supercache/hooks/pre-commit.sh" ]]; then
    "$REPO_ROOT/.supercache/hooks/pre-commit.sh"
fi

if [[ -x "$HOME/.local/share/legacy-ai/hooks/pre-commit-secret-scan.sh" ]]; then
    "$HOME/.local/share/legacy-ai/hooks/pre-commit-secret-scan.sh"
fi

if [[ -x "$REPO_ROOT/scripts/secret-scan.sh" ]]; then
    "$REPO_ROOT/scripts/secret-scan.sh" --staged
fi

while IFS= read -r nested_secret_scan; do
    [[ "$nested_secret_scan" == "$REPO_ROOT/scripts/secret-scan.sh" ]] && continue
    [[ -x "$nested_secret_scan" ]] || continue
    "$nested_secret_scan" --staged
done < <(
    find "$REPO_ROOT" \
        -path '*/.git/*' -prune -o \
        -path '*/node_modules/*' -prune -o \
        -path '*/.supercache/*' -prune -o \
        -path '*/scripts/secret-scan.sh' -type f -perm -u+x -print 2>/dev/null
)
HOOK
    chmod +x "$hook"
    ok "Installed/updated governed pre-commit hook"
}

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

    # Sanitize project name for use in filenames (replace spaces with underscores)
    local safe_name
    safe_name="$(echo "$project_name" | tr ' ' '_')"
    local now
    now="$(date +%Y-%m-%dT%H:%M:%S%z)"

    # FLOYD.md — only if it doesn't exist (never overwrite project-specific content)
    if [[ ! -f "$target/FLOYD.md" ]]; then
        sed "s/{{PROJECT_NAME}}/$safe_name/g; s/{{VERSION}}/$SC_VERSION/g; s|{{SUPERCACHE_PATH}}|$SC_ROOT|g; s/{{DATE}}/$now/g" \
            "$TEMPLATES/floyd-md-template.md" > "$target/FLOYD.md"
        ok "Created FLOYD.md"
    else
        warn "FLOYD.md already exists — skipping (will not overwrite project-specific content)"
    fi

    # SSOT — uses <PROJECT_NAME>_SSOT.md filename convention (v1.3.0+)
    local ssot_file="$target/SSOT/${safe_name}_SSOT.md"
    if [[ ! -f "$ssot_file" ]]; then
        sed "s/{{PROJECT_NAME}}/$safe_name/g; s/{{VERSION}}/$SC_VERSION/g; s/{{DATE}}/$now/g" \
            "$TEMPLATES/ssot-template.md" > "$ssot_file"
        ok "Created SSOT/${safe_name}_SSOT.md"
    else
        warn "SSOT/${safe_name}_SSOT.md already exists — skipping"
    fi

    # Issues — uses <PROJECT_NAME>_ISSUES.md filename convention (v1.3.0+)
    local issues_file="$target/Issues/${safe_name}_ISSUES.md"
    if [[ ! -f "$issues_file" ]]; then
        sed "s/{{PROJECT_NAME}}/$safe_name/g; s/{{VERSION}}/$SC_VERSION/g; s/{{DATE}}/$now/g" \
            "$TEMPLATES/issues-template.md" > "$issues_file"
        ok "Created Issues/${safe_name}_ISSUES.md"
    else
        warn "Issues/${safe_name}_ISSUES.md already exists — skipping"
    fi

    # Agent log
    if [[ ! -f "$target/.floyd/agent_log.jsonl" ]]; then
        touch "$target/.floyd/agent_log.jsonl"
        ok "Created .floyd/agent_log.jsonl"
    fi

    # Repository report template — agents must fill this via code review at bootstrap
    local report_file="$target/.floyd/repository_report_template.md"
    if [[ ! -f "$report_file" ]]; then
        cp "$TEMPLATES/repository-report-template.md" "$report_file"
        ok "Created .floyd/repository_report_template.md"
    else
        warn ".floyd/repository_report_template.md already exists — skipping"
    fi

    # Rules contract — mandatory reading at every session
    local rules_file="$target/.floyd/rules.md"
    if [[ ! -f "$rules_file" ]]; then
        cp "$CONTRACTS/rules.md" "$rules_file"
        ok "Created .floyd/rules.md"
    else
        warn ".floyd/rules.md already exists — skipping"
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

    # FLOYD.md (canonical, required)
    if [[ -f "$target/FLOYD.md" ]]; then
        ok "FLOYD.md present ($(wc -l < "$target/FLOYD.md") lines) [canonical]"
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

    # Repository report template
    if [[ -f "$target/.floyd/repository_report_template.md" ]]; then
        ok "Repository report template present"
    else
        info "Repository report template not present — run --repair to deploy"
    fi

    # Rules contract
    if [[ -f "$target/.floyd/rules.md" ]]; then
        ok "Rules contract present"
    else
        info "Rules contract not present — run --repair to deploy"
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

    # Sanitized name used in per-project filenames (v1.3.0+ convention)
    local safe_name
    safe_name="$(echo "$project_name" | tr ' ' '_')"

    check "FLOYD.md exists (canonical)" "[[ -f '$target/FLOYD.md' ]]"
    check "SSOT/ directory exists" "[[ -d '$target/SSOT' ]]"
    check "SSOT/${safe_name}_SSOT.md present (v1.3.0+ naming)" \
        "[[ -f '$target/SSOT/${safe_name}_SSOT.md' ]] || [[ -f '$target/SSOT/README.md' ]]"
    check "Issues/ directory exists" "[[ -d '$target/Issues' ]]"
    check "Issues/${safe_name}_ISSUES.md present (v1.3.0+ naming)" \
        "[[ -f '$target/Issues/${safe_name}_ISSUES.md' ]] || [[ -f '$target/Issues/README.md' ]]"
    check ".floyd/ directory exists" "[[ -d '$target/.floyd' ]]"
    check "Agent log exists" "[[ -f '$target/.floyd/agent_log.jsonl' ]]"
    check "Version stamp exists" "[[ -f '$target/.floyd/.supercache_version' ]]"
    check "Repository report template deployed" "[[ -f '$target/.floyd/repository_report_template.md' ]]"
    check "Rules contract deployed" "[[ -f '$target/.floyd/rules.md' ]]"
    check ".supercache path resolves to current governance" "valid_supercache_path '$target'"
    check "FLOYD.md governance header current" "grep -q '^\\*\\*Governance:\\*\\* \\.supercache/ v$SC_VERSION$' '$target/FLOYD.md'"


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

    sync_supercache_path "$target"
    sync_governance_headers "$target"
    install_governed_precommit_hook "$target"
}

cmd_bulk_init() {
    local parent="${1:-}"
    if [[ $# -gt 0 ]]; then
        shift
    fi

    if [[ -z "$parent" ]]; then
        fail "Usage: bootstrap.sh --bulk-init <parent-dir> [--dry-run]"
        fail "Example: bootstrap.sh --bulk-init /Volumes/Storage/Development"
        fail ""
        fail "Walks the parent directory and runs --init on every directory that looks"
        fail "like a project (has a recognizable manifest file like package.json, Cargo.toml,"
        fail "pyproject.toml, go.mod, Package.swift, etc.) and lacks FLOYD.md."
        fail ""
        fail "Use --dry-run to preview the target list without creating any files."
        exit 1
    fi

    if [[ ! -d "$parent" ]]; then
        fail "Parent directory does not exist: $parent"
        exit 1
    fi

    parent="$(cd "$parent" && pwd)"

    local is_dry_run="no"
    for arg in "$@"; do
        case "$arg" in
            --dry-run)   is_dry_run="yes" ;;
            *)           fail "Unknown --bulk-init flag: $arg"; exit 2 ;;
        esac
    done

    info "Bulk-init scanning: $parent"
    info "Mode: $([ "$is_dry_run" = "yes" ] && echo "DRY RUN (preview only)" || echo "EXECUTE")"
    echo ""

    local -a skipped_existing=()
    local -a skipped_not_project=()
    local -a skipped_excluded=()
    local -a to_init=()

    # Exclusion list — directories that should never get governance
    local exclude_pattern='^(node_modules|\.git|\.floyd|\.supercache|\.Trashes|\.Spotlight-V100|\.fseventsd|\.DocumentRevisions-V100|\.TemporaryItems|Media\.localized|.*\.photoslibrary|.*\.musiclibrary|backup-storage-.*|canonical_sources|scraped_repos|reference|SSOT|Issues)$'

    for dir in "$parent"/*/; do
        [[ -d "$dir" ]] || continue
        local name
        name="$(basename "$dir")"

        # Skip excluded directories
        if [[ "$name" =~ $exclude_pattern ]]; then
            skipped_excluded+=("$name")
            continue
        fi

        # Skip if already governed
        if [[ -f "$dir/FLOYD.md" ]]; then
            skipped_existing+=("$name")
            continue
        fi

        # Project detection: look for a recognizable manifest or a .git directory
        local is_project="no"
        for manifest in package.json Cargo.toml pyproject.toml setup.py go.mod Package.swift Gemfile pom.xml build.gradle CMakeLists.txt Makefile requirements.txt mix.exs composer.json; do
            if [[ -f "$dir/$manifest" ]]; then
                is_project="yes"
                break
            fi
        done
        if [[ "$is_project" = "no" ]] && [[ -d "$dir/.git" ]]; then
            is_project="yes"
        fi

        if [[ "$is_project" = "no" ]]; then
            skipped_not_project+=("$name")
            continue
        fi

        to_init+=("$dir")
    done

    # Report
    echo "=== Bulk init target list ==="
    echo "Will initialize (${#to_init[@]} projects):"
    for d in "${to_init[@]}"; do
        echo "  + $(basename "$d")"
    done
    echo ""

    if [[ ${#skipped_existing[@]} -gt 0 ]]; then
        echo "Already governed (skipped ${#skipped_existing[@]}):"
        for n in "${skipped_existing[@]}"; do
            echo "  = $n"
        done
        echo ""
    fi

    if [[ ${#skipped_not_project[@]} -gt 0 ]]; then
        echo "Not recognized as projects (skipped ${#skipped_not_project[@]}):"
        for n in "${skipped_not_project[@]}"; do
            echo "  - $n"
        done
        echo ""
    fi

    if [[ ${#skipped_excluded[@]} -gt 0 ]]; then
        echo "Excluded by rule (skipped ${#skipped_excluded[@]}):"
        for n in "${skipped_excluded[@]}"; do
            echo "  x $n"
        done
        echo ""
    fi

    if [[ "$is_dry_run" = "yes" ]]; then
        info "DRY RUN complete — no files created. Re-run without --dry-run to apply."
        return 0
    fi

    if [[ ${#to_init[@]} -eq 0 ]]; then
        info "Nothing to do — no projects needed initialization."
        return 0
    fi

    # Execute
    echo "=== Executing bulk init ==="
    local success_count=0
    local fail_count=0
    for d in "${to_init[@]}"; do
        local n
        n="$(basename "$d")"
        echo ""
        info "Initializing: $n"
        if cmd_init "$d" > /dev/null 2>&1; then
            ok "  FLOYD.md + SSOT + Issues + .floyd created"
            success_count=$((success_count + 1))
        else
            fail "  init failed for $n (continuing with remaining projects)"
            fail_count=$((fail_count + 1))
        fi
    done

    echo ""
    echo "=== Bulk init summary ==="
    ok "Initialized: $success_count projects"
    if [[ $fail_count -gt 0 ]]; then
        fail "Failed: $fail_count projects"
    fi
    info "Skipped (already governed): ${#skipped_existing[@]}"
    info "Skipped (not a project): ${#skipped_not_project[@]}"
    info "Skipped (excluded): ${#skipped_excluded[@]}"
}

cmd_bump_version() {
    local new_ver="${1:-}"
    local dry_run="${2:-}"

    if [[ -z "$new_ver" ]]; then
        fail "Usage: bootstrap.sh --bump-version X.Y.Z [--dry-run]"
        fail "Example: bootstrap.sh --bump-version 1.3.0"
        exit 1
    fi

    if ! [[ "$new_ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        fail "Invalid version format: '$new_ver'"
        fail "Expected semver: X.Y.Z (e.g., 1.3.0)"
        exit 1
    fi

    if [[ ! -f "$SC_ROOT/VERSION" ]] || [[ ! -d "$SC_ROOT/.git" ]]; then
        fail "Not inside a .supercache/ git repo. SC_ROOT=$SC_ROOT"
        exit 1
    fi

    local old_ver
    old_ver="$(cat "$SC_ROOT/VERSION")"

    info "Bumping .supercache/ version: $old_ver → $new_ver"

    if [[ "$dry_run" != "--dry-run" ]]; then
        # Require clean working tree — prevent mixing version bumps with unrelated edits
        if ! git -C "$SC_ROOT" diff --quiet || ! git -C "$SC_ROOT" diff --cached --quiet; then
            fail "Working tree has uncommitted changes. Commit or stash before bumping version."
            fail "Run 'git -C $SC_ROOT status' to see what's pending."
            exit 1
        fi
    else
        info "DRY RUN — no files will be modified"
    fi

    # Files that must all carry the version string in lockstep
    # ALL contracts/ files with **Version:** headers must be bumped together.
    local version_files=(
        "$SC_ROOT/VERSION"
        "$SC_ROOT/.floyd/.supercache_version"
        "$SC_ROOT/FLOYD.md"
        "$SC_ROOT/README.md"
        "$SC_ROOT/contracts/agent-contract.md"
        "$SC_ROOT/contracts/execution-contract.md"
        "$SC_ROOT/contracts/governance-entry.md"
        "$SC_ROOT/contracts/document-management.md"
        "$SC_ROOT/contracts/git-discipline.md"
        "$SC_ROOT/contracts/repo-hygiene.md"
        "$SC_ROOT/contracts/repo-sanitation.md"
        "$SC_ROOT/contracts/repo-structure.md"
        "$SC_ROOT/contracts/repository-report-spec.md"
        "$SC_ROOT/contracts/rules.md"
    )

    for f in "${version_files[@]}"; do
        if [[ ! -f "$f" ]]; then
            fail "Expected file missing: $f"
            exit 1
        fi
    done

    # VERSION file
    if [[ "$dry_run" != "--dry-run" ]]; then
        echo "$new_ver" > "$SC_ROOT/VERSION"
        echo "$new_ver" > "$SC_ROOT/.floyd/.supercache_version"
    fi
    ok "VERSION: $old_ver → $new_ver"
    ok ".floyd/.supercache_version: $old_ver → $new_ver"

    # All markdown files: bump **Version:** and **Governance:** strings
    local md_files=()
    for f in "${version_files[@]}"; do
        [[ "$f" == *.md ]] && md_files+=("$f")
    done

    for f in "${md_files[@]}"; do
        local basename="$(basename "$f")"
        if [[ "$dry_run" != "--dry-run" ]]; then
            sed -i '' "s/\*\*Version:\*\* $old_ver/\*\*Version:\*\* $new_ver/" "$f"
            sed -i '' "s|\*\*Governance:\*\* \.supercache/ v$old_ver|\*\*Governance:\*\* .supercache/ v$new_ver|" "$f"
        fi
        ok "$basename: Version + Governance → $new_ver"
    done

    echo ""
    if [[ "$dry_run" == "--dry-run" ]]; then
        info "Dry run complete. No files modified. Re-run without --dry-run to apply."
    else
        ok "Version bumped in lockstep across ${#version_files[@]} files: $old_ver → $new_ver"
        info "Review the diff:  git -C $SC_ROOT diff"
        info "Commit manually with a message like:  'chore: bump version to $new_ver'"
    fi
}

cmd_archive() {
    local target="${1:-.}"
    target="$(cd "$target" && pwd)"
    local project_name="$(basename "$target")"
    local archive_date="$(date +%Y-%m-%dT%H:%M:%S%z)"

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

    # T7 is OFF LIMITS — Time Machine target for Mac mini backups. Never scan it.
    for mount in /Volumes/SanDisk1Tb /Volumes/Storage; do
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
    --init)         cmd_init "${2:-.}" ;;
    --info)         cmd_info "${2:-.}" ;;
    --verify|--doctor) cmd_verify "${2:-.}" ;;
    --repair)       cmd_repair "${2:-.}" ;;
    --bulk-init)    shift; cmd_bulk_init "$@" ;;
    --bump-version) cmd_bump_version "${2:-}" "${3:-}" ;;
    --archive)      cmd_archive "${2:-.}" ;;
    --health)       cmd_health ;;
    --version)      cmd_version ;;
    *)
        echo "Legacy AI bootstrap.sh v${SC_VERSION:-unknown}"
        echo ""
        echo "Usage: bootstrap.sh <command> [args]"
        echo ""
        echo "Project commands:"
        echo "  --init [dir]                  Initialize governance in a project directory"
        echo "  --info [dir]                  Show project orientation"
        echo "  --verify [dir]                Compliance check (pass/fail)"
        echo "  --doctor [dir]                Alias for --verify"
        echo "  --repair [dir]                Fix missing/outdated artifacts"
        echo "  --bulk-init <parent> [flags]  Retrofit --init across every project under a parent dir"
        echo "                                Flags: --dry-run"
        echo "  --archive [dir]               Mark project for archival"
        echo ""
        echo "Governance commands:"
        echo "  --bump-version X.Y.Z          Bump .supercache/ version in lockstep across all files"
        echo "  --health                      Scan all drives for compliance"
        echo "  --version                     Print .supercache/ version"
        echo ""
        echo "Agent model:"
        echo "  FLOYD.md is required (canonical project spec)."
        exit 1
        ;;
esac
