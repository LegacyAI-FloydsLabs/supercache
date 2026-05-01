# Repository Hygiene Contract
**Version:** 1.6.0
**Governance:** .supercache/ v1.6.0
**Owner:** Douglas Talley / Legacy AI

This contract governs cleanliness, organization, and what does not belong in a repository. It complements `contracts/repo-structure.md` (which defines where things go) and `contracts/document-management.md` (which defines document lifecycle).

It is READ-ONLY. The sole write path: Douglas Talley → GitHub PR → merge → git pull.

> **v1.6.0 supersession notice.** All removal flows in this contract route through `contracts/repo-sanitation.md`. The previous "Safety Protocol Before Deleting Anything", "User Override" (deletion-autonomy clause), and the "Default policy: delete" for dead code are **superseded by `repo-sanitation.md` §6.2 and §6.3**. Agents do not delete code or files — they quarantine to `<project>/.floyd/quarantine/<YYYY-MM-DD>/<original-relative-path>` with a `WHY.md` companion and a `LEDGER.jsonl` append. Only Douglas empties quarantine.

---

## Core Rule

**Leave the repository cleaner than you found it.**

Every agent task should end with the repository in a state at least as tidy as when it started. Preferably tidier. Mess accumulates if nobody is responsible for cleanup; this contract makes cleanup an explicit expectation for every agent on every task.

The enforcement posture in v1.6.0 remains advisory at the contract level — agents apply these rules proactively. Hard mechanical enforcement (PreToolUse hook + `floyd-quarantine` helper) ships in v1.6.1.

---

## `.gitignore` Baselines by Language

Every repository MUST have a `.gitignore`. If a project has no `.gitignore`, agents MUST create one on first contact using the language-appropriate baseline below (combine multiple baselines for polyglot projects).

### Universal baseline (always include)

```
# OS
.DS_Store
Thumbs.db
*.swp
*.swo
*~

# IDE
.vscode/*
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json
!.vscode/extensions.json
.idea/
*.iml
.vs/

# Secrets (NEVER COMMIT)
.env
.env.*
!.env.example
*.key
*.pem
*.p12
secrets.json

# Logs
*.log
logs/
npm-debug.log*
yarn-debug.log*

# Governance agent state
.floyd/
```

Note on `.vscode/`: the pattern above excludes everything except a specific allowlist of shared settings files. This lets teams share useful VS Code configuration while keeping personal preferences out of git.

### TypeScript / Node.js

```
# Dependencies
node_modules/
.pnp/
.pnp.*
.yarn/*
!.yarn/patches
!.yarn/plugins
!.yarn/releases
!.yarn/versions

# Build output
dist/
build/
out/
.next/
.nuxt/
.svelte-kit/
.turbo/
.vite/

# Test coverage
coverage/
*.lcov
.nyc_output/

# TypeScript
*.tsbuildinfo
.tsc/

# Environment
.env.local
.env.development.local
.env.test.local
.env.production.local
```

### Python

```
# Byte-compiled
__pycache__/
*.py[cod]
*$py.class

# Distribution / packaging
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
share/python-wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Virtual environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# Testing
.pytest_cache/
.coverage
.coverage.*
htmlcov/
.tox/
.nox/
coverage.xml
*.cover

# Type checking
.mypy_cache/
.dmypy.json
dmypy.json
.pyre/
.pytype/

# Jupyter
.ipynb_checkpoints
profile_default/
ipython_config.py

# Poetry / Pipenv
.poetry/
Pipfile.lock
```

### Go

```
# Build output
/bin/
/build/
*.exe
*.exe~
*.dll
*.so
*.dylib

# Test output
*.test
*.out
/coverage.*

# Dependency vendor (optional — depends on vendor policy)
# vendor/

# Module cache (usually outside repo, but just in case)
.cache/

# Delve debugger
__debug_bin
```

### Rust

```
# Build output
/target/
**/target/

# Lockfile policy varies:
# - Binaries: commit Cargo.lock
# - Libraries: commit it if you ship with a specific pin, otherwise gitignore

# IDE
*.rs.bk

# Rust analyzer
.cargo/
```

### Swift (SwiftPM + Xcode)

```
# SwiftPM
.build/
.swiftpm/
Packages/
*.xcodeproj/xcuserdata/
*.xcworkspace/xcuserdata/

# Xcode
xcuserdata/
*.xcscmblueprint
*.xccheckout
DerivedData/
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3

# CocoaPods (if used)
Pods/

# Carthage (if used)
Carthage/Build/

# Fastlane (if used)
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output
```

---

## Forbidden in Git

The following categories of files MUST NEVER be committed:

### Secrets and credentials

- `.env`, `.env.local`, `.env.production`, etc. (commit only `.env.example`)
- API keys, tokens, passwords, session cookies
- Private keys (`.key`, `.pem`, `.p12`, `id_rsa`, `id_ed25519`)
- OAuth client secrets, JWT signing secrets
- Database connection strings with embedded credentials
- Cloud provider credentials (`~/.aws/credentials`, `~/.gcp/credentials.json`, etc.)

### Build artifacts

- `node_modules/`, `target/`, `__pycache__/`, `.venv/`, `dist/`, `build/`, `.build/`, `DerivedData/`
- Compiled binaries unless explicitly needed (and then via Git LFS with `.gitattributes`)
- Test coverage reports (`coverage/`, `.nyc_output/`)

### OS and IDE artifacts

- `.DS_Store`, `Thumbs.db`, `desktop.ini`
- `*.swp`, `*.swo`, editor backups (`*~`)
- IDE-specific settings folders unless explicitly shared (`.idea/`, parts of `.vscode/`)

### Backups and temporaries

- `*.bak`, `*.orig`, `*.rej`, `*.tmp`
- Editor recovery files
- Merge conflict remnants (`*.orig` from merge tool)

### Binary blobs (without `.gitattributes` declaration)

- Images, videos, large datasets committed without Git LFS setup
- Compiled libraries (`.so`, `.dylib`, `.dll`, `.a`) unless explicitly part of distribution

---

## Cleanup Triggers (Flag and Quarantine on Sight)

When an agent encounters any of the following, it is a cleanup signal. **The disposition is always quarantine per `repo-sanitation.md §3`** — agents do not auto-delete and do not delete after asking.

### Duplicate directories

- `foo/`, `foo copy/`, `foo copy 2/` — macOS Finder "Duplicate" artifacts that got committed
- `project/`, `project-old/`, `project-new/`, `project-v2/`, `project-backup/` — indicates uncertain refactor history
- `module/`, `module2/`, `module_new/`, `module_final/`, `module_final_2/` — same story, worse

**Protocol**: investigate which is canonical. Quarantine the others per `repo-sanitation.md §3` with `reason_category: duplicate`. Update references in active code to point to the canonical copy. Open an Issue documenting the choice.

### Empty placeholders

- `untitled folder/`, `untitled folder 2/`, `new folder/` — macOS default blank directories
- Empty `plans/`, `notes/`, `state/`, `locks/` dirs at project root
- Directories with only a `.DS_Store` or `.gitkeep`

**Protocol**: quarantine the directory if truly empty and purposeless (`reason_category: stale`). If a `.gitkeep` exists, check whether the empty directory is intentional (some build tools need empty dirs); if intentional, leave alone.

### Stale root-level junk

- `TODO.md`, `NOTES.md`, `SCRATCH.md` at project root (should be moved or quarantined per `contracts/document-management.md`)
- Orphaned `node_modules/` NOT inside a project (e.g., at drive root or wrong directory)
- Random loose scripts (`test_something.py`, `quick_fix.sh`) at repo root that belong in `scripts/` or `tests/`
- `.env.example.old`, `config.json.bak`, `settings.backup` — stale configs

**Protocol**: ask "does this belong somewhere structured?", move it if yes, quarantine per `repo-sanitation.md §3` if no (`reason_category: cleanup-trigger`).

### Committed secrets or backup files in git history

- `*.bak`, `*.swp`, `*.tmp` that made it into a commit
- `.env` that was committed (needs history rewrite to fully remove — escalate as a security issue)
- Accidentally-committed credentials files

**Protocol**: if found in current commit, quarantine and add to `.gitignore`. If found in history, **escalate to Douglas** as a security issue per `repo-sanitation.md §8.1` — history rewrite may be needed, credentials may need rotation. Quarantine alone does NOT remove a secret from git history; escalation is mandatory.

### Dead code

- Commented-out blocks larger than ~10 lines
- Unreferenced functions, classes, or modules
- `DEPRECATED` comments with no removal plan
- `XXX`, `FIXME`, `HACK` comments older than 6 months with no associated issue

**Protocol**: extract per `repo-sanitation.md §6.3` — quarantine the snippet to `.floyd/quarantine/<date>/dead-code/<original-file>__<line-range>.snippet` with WHY.md, then remove the comment from the active source file. Open an Issue to document the choice.

---

## Project Root Tidiness

### Soft rule: 20+ loose files at repo root is a cleanup signal

If a project's root directory has more than ~20 loose files (counting Markdown, scripts, configs, etc. but not directories), it is probably accumulating cruft. Flag as a cleanup target.

### What belongs at the root

- **Manifests**: `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `Package.swift`, etc.
- **Lockfiles**: `package-lock.json`, `pnpm-lock.yaml`, `Cargo.lock`, `go.sum`, `Pipfile.lock`, `poetry.lock`, `Package.resolved`
- **Primary docs**: `README.md`, `LICENSE`, `CHANGELOG.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`
- **Governance**: `FLOYD.md`, `CLAUDE.md` (optional)
- **Dotfiles**: `.gitignore`, `.gitattributes`, `.editorconfig`, `.env.example`
- **CI config**: `.github/` directory (not files directly at root), `.gitlab-ci.yml`, etc.
- **Build tooling**: `Makefile`, `CMakeLists.txt`, `Dockerfile`, `docker-compose.yml`
- **Formatter/linter config**: `tsconfig.json`, `biome.json`, `eslint.config.mjs`, `.prettierrc`, `pyproject.toml`, `rustfmt.toml`, `.swiftlint.yml`, etc.

### What does NOT belong at the root

- Random `.py`/`.js`/`.sh`/`.ts` scripts without clear purpose
- Session notes or scratch files
- Backup files or config backups
- Session handoffs (those go in `.floyd/`)
- Multiple competing architecture docs
- Auto-generated files without a regeneration script

---

## Loose Scripts: Where They Belong

If an agent finds loose scripts at a project root, they should typically be moved to:

- **`scripts/`** — build, deploy, and utility scripts for developer use
- **`bin/`** — executable entry points for the project (if not using a language-native binary location like Go's `cmd/` or Rust's `src/bin/`)
- **`tools/`** — standalone tools that aren't part of the main binary
- **`tests/`** or **`tests/integration/`** — test scripts, fixtures, test data
- **`.github/workflows/`** — CI/CD scripts

Language-specific:
- **Rust**: use `src/bin/` for additional binaries in a Cargo project, not `bin/`
- **Python**: use `scripts/` for utility scripts, `bin/` only if installable as console_scripts
- **Go**: use `cmd/myapp/main.go` for entry points, `scripts/` for shell utilities
- **Node**: use `scripts/` for `package.json` script targets; keep inline in `package.json` when short

---

## Soft Size Limits

These are guidelines, not hard rules. They flag candidates for refactoring.

### File size

- **Soft limit**: ~800 lines per source file
- Above 800 lines is a signal that the file should be split into smaller modules
- Exceptions: generated files, large tables of data, vendored code

### Directory depth

- **Soft limit**: 4 levels of nesting from project root
- `src/features/auth/components/LoginForm.tsx` is 5 levels from `src/`, which is fine
- `src/shared/common/utils/helpers/stringUtils/formatters/dateFormatter.ts` is too deep — flatten

### Function/method size

- **Soft limit**: ~50 lines per function
- Above 50 lines is a signal that the function is doing too much
- Exceptions: well-structured state machines, parsers, some algorithms

---

## Quarantine over deletion (replaces "Safety Protocol Before Deleting Anything")

**This section replaces the prior "Safety Protocol Before Deleting Anything" entirely.** The full quarantine-only protocol lives in `contracts/repo-sanitation.md §6.2`. Summary:

When a sanitation pass identifies a candidate for removal:

1. **Move it to quarantine** per `repo-sanitation.md §3` with appropriate `reason_category`
2. **Append a LEDGER entry** per `repo-sanitation.md §3.4`
3. **Open an Issue** in `Issues/<PROJECT>_ISSUES.md` describing the candidate and why quarantine was chosen
4. **Continue the task** — do not block on deletion approval; quarantine is the disposition

The agent never reaches a step where it asks "should I delete this?" Quarantine is the answer in 100% of cases. The pre-quarantine checks (git history, cross-references, test coverage, config, CI/CD) remain useful for **deciding what to quarantine**, but they do not gate deletion — they inform the WHY.md.

---

## User Override (replaces prior "User Override" deletion clause)

If the user says **"don't clean up"**, **"leave it as is"**, **"stop tidying"**, or similar, respect it absolutely. Cleanliness is a default, not a mandate. The user owns the repository and owns the trade-offs.

If the user says "clean this up aggressively" or "authorized to delete anything you think is stale", that override grants **scope** (what to clean) but **never operation** (deletion vs quarantine). Under v1.6.0, even an explicit user override does not authorize agent deletion. Quarantine is always the operation; the override only expands which items the agent considers cleanup candidates. If Douglas wants something deleted, Douglas deletes it himself.

---

## Dead Code and Commented-Out Blocks (replaces prior "Default policy: delete")

**The prior "Default policy: delete" for dead code is rescinded.** Full quarantine-extract protocol in `contracts/repo-sanitation.md §6.3`. Summary:

- **Commented-out code blocks** larger than ~10 lines: extract the block into a quarantined file at `.floyd/quarantine/<date>/dead-code/<original-file>__<line-range>.snippet` with WHY.md, then remove the comment from the active source file.
- **Unreferenced functions/classes/modules**: same treatment — extract to quarantine, remove from active source.
- **Load-bearing comments** that explain *why* code is the way it is: leave alone (the distinction below remains authoritative).

The agent's commit message references the quarantine path, not "deleted dead code".

### Exception: explanatory comments

Do NOT touch comments that explain **why** code is the way it is. Quarantine only dead **code** snippets; leave load-bearing prose comments alone. The distinction matters:

**Dead code** (extract → quarantine → remove from active source):
```
// function oldParse(input) {
//   return input.split(',').map(s => s.trim());
// }
```

**Load-bearing comment** (keep, do not touch):
```
// NOTE: we use a manual split here instead of a regex because the
// V8 regex engine has a pathological case for this input shape.
// See: issue #234, benchmark at bench/parser-regex-vs-split.ts
function parse(input) { ... }
```

---

## Relationship to Other Contracts

- **`repo-sanitation.md`** — authoritative on removal flows. This contract's cleanup triggers, dead-code handling, user override semantics, and safety protocol all defer to `repo-sanitation.md §3` (quarantine), §6.2 (quarantine over deletion), §6.3 (dead code), and §8.2 (user override).
- **`repo-structure.md`** — together define "where files go and what doesn't belong"
- **`document-management.md`** — anti-cruft rules for documents specifically; this contract covers everything else
- **`git-discipline.md`** — pre-commit checklist includes secret hygiene, which is the most critical hygiene rule
- **`execution-contract.md`** — evidence rules apply to cleanup: don't claim "cleaned up" without evidence of what was quarantined

---

## Enforcement Posture (v1.6.0)

This contract is **advisory** in v1.6.0. Agents apply these rules proactively, but nothing blocks a commit for hygiene violations at the contract layer. v1.6.1 adds:

- **PreToolUse no-delete hook** — pattern-matches deletion commands (`rm`, `rm -rf`, `git clean`, `unlink`, `os.remove`, `shutil.rmtree`, `fs.unlink`, `Remove-Item`) at the harness layer and blocks them with a pointer to `floyd-quarantine`
- **`floyd-quarantine` helper** — atomic move + WHY.md authoring + LEDGER append, callable as `floyd-quarantine <path> --reason <category> --note "<one-liner>"`
- **SessionStart bootstrap** — runs the daily routine A→F from `repo-sanitation.md §7` mechanically before the session does any other work

Until v1.6.1 ships, agents are the primary enforcement mechanism. Use this contract and `repo-sanitation.md` as the runtime checklist on every task.

---

## Mandatory execution contract
For EACH requested item:
1) Show exact action taken
2) Show direct evidence (file/line/command/output)
3) Show verification result
4) Mark status only after proof

## Forbidden behaviors
- Declaring "done" without evidence
- Collapsing multiple requested items into one vague summary
- Skipping failed steps without explicit blocker report

## Required output structure
A) Requested items checklist
B) Per-item evidence ledger
C) Verification receipts
D) Completeness matrix (item -> done/blocked -> evidence)

## Hard gate
If any requested item has no evidence row, final status MUST be INCOMPLETE.
