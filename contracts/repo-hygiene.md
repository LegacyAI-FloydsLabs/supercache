# Repository Hygiene Contract
**Version:** 1.3.0
**Governance:** .supercache/ v1.3.0
**Owner:** Douglas Talley / Legacy AI

This contract governs cleanliness, organization, and what does not belong in a repository. It complements `contracts/repo-structure.md` (which defines where things go) and `contracts/document-management.md` (which defines document lifecycle).

It is READ-ONLY. The sole write path: Douglas Talley → GitHub PR → merge → git pull.

---

## Core Rule

**Leave the repository cleaner than you found it.**

Every agent task should end with the repository in a state at least as tidy as when it started. Preferably tidier. Mess accumulates if nobody is responsible for cleanup; this contract makes cleanup an explicit expectation for every agent on every task.

The enforcement posture in v1.3.0 is advisory — agents are asked to apply these rules proactively but not gated by pre-commit checks. v1.4.0 will add hard enforcement via `bootstrap.sh --verify-hygiene` and optional pre-commit hooks.

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

## Cleanup Triggers (Flag on Sight)

When an agent encounters any of the following, it is a cleanup signal. Do NOT auto-delete — flag the finding, check with the user, then act.

### Duplicate directories

- `foo/`, `foo copy/`, `foo copy 2/` — macOS Finder "Duplicate" artifacts that got committed
- `project/`, `project-old/`, `project-new/`, `project-v2/`, `project-backup/` — indicates uncertain refactor history
- `module/`, `module2/`, `module_new/`, `module_final/`, `module_final_2/` — same story, worse

**Protocol**: investigate which is canonical, archive or delete the others, update references.

### Empty placeholders

- `untitled folder/`, `untitled folder 2/`, `new folder/` — macOS default blank directories
- Empty `plans/`, `notes/`, `state/`, `locks/` dirs at project root
- Directories with only a `.DS_Store` or `.gitkeep`

**Protocol**: delete if truly empty and purposeless. If a `.gitkeep` exists, check whether the empty directory is intentional (some build tools need empty dirs).

### Stale root-level junk

- `TODO.md`, `NOTES.md`, `SCRATCH.md` at project root (should be moved or deleted per `contracts/document-management.md`)
- Orphaned `node_modules/` NOT inside a project (e.g., at drive root or wrong directory)
- Random loose scripts (`test_something.py`, `quick_fix.sh`) at repo root that belong in `scripts/` or `tests/`
- `.env.example.old`, `config.json.bak`, `settings.backup` — stale configs

**Protocol**: ask "does this belong somewhere structured?", move it if yes, flag for deletion if no.

### Committed secrets or backup files in git history

- `*.bak`, `*.swp`, `*.tmp` that made it into a commit
- `.env` that was committed (needs history rewrite to fully remove — flag as a security issue, not a cleanup item)
- Accidentally-committed credentials files

**Protocol**: if found in current commit, remove and add to `.gitignore`. If found in history, escalate to the user as a security issue — history rewrite may be needed, credentials may need rotation.

### Dead code

- Commented-out blocks larger than ~10 lines
- Unreferenced functions, classes, or modules
- `DEPRECATED` comments with no removal plan
- `XXX`, `FIXME`, `HACK` comments older than 6 months with no associated issue

**Protocol**: for small projects, delete with a clear commit message. For larger projects, confirm with the user first — there may be reasons.

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

## Safety Protocol Before Deleting Anything

Agents MUST NOT delete files or directories without following this protocol:

1. **Check git history** — does anything in the last 30 days reference this file?
2. **Check cross-references** — does any other file import, require, or link to this?
3. **Check test coverage** — does any test reference this file or directory?
4. **Check config** — does any config file (`tsconfig`, `webpack`, `package.json`, `Cargo.toml`, etc.) reference this path?
5. **Check CI/CD** — does any workflow file reference this path?
6. **Ask the user** — on any ambiguity, ask. Deletion is almost always cheap to defer; deleting something load-bearing is expensive to recover from.

**Rule of thumb**: if you're 99% sure it's safe to delete, you should still ask before deleting unless the user has explicitly authorized cleanup autonomy.

---

## User Override

If the user says **"don't clean up"**, **"leave it as is"**, **"stop tidying"**, or similar, respect it absolutely. Cleanliness is a default, not a mandate. The user owns the repository and owns the trade-offs.

Similarly, if the user says "clean this up aggressively" or "authorized to delete anything you think is stale", that is a temporary scope expansion for that task only — do not carry it into future sessions.

---

## Dead Code and Commented-Out Blocks

### Default policy: delete

Commented-out code is generally dead weight. Git history preserves it. Delete with a clear commit message:

```
refactor: remove commented-out legacy implementation

The old pre-refactor implementation remained as commented blocks
in src/auth/session.ts. Removing now that the new flow has shipped
and been in production for 2+ weeks. History is preserved in git.
```

### Exception: explanatory comments

Do NOT delete comments that explain **why** code is the way it is. Delete only comments that are dead **code**. The distinction matters:

**Dead code** (delete):
```
// function oldParse(input) {
//   return input.split(',').map(s => s.trim());
// }
```

**Load-bearing comment** (keep):
```
// NOTE: we use a manual split here instead of a regex because the
// V8 regex engine has a pathological case for this input shape.
// See: issue #234, benchmark at bench/parser-regex-vs-split.ts
function parse(input) { ... }
```

---

## Relationship to Other Contracts

- **`repo-structure.md`** — together define "where files go and what doesn't belong"
- **`document-management.md`** — anti-cruft rules for documents specifically; this contract covers everything else
- **`git-discipline.md`** — pre-commit checklist includes secret hygiene, which is the most critical hygiene rule
- **`execution-contract.md`** — evidence rules apply to cleanup: don't claim "cleaned up" without evidence of what was removed

---

## Enforcement Posture (v1.3.0)

This contract is **advisory** in v1.3.0. Agents should apply these rules proactively, but nothing blocks a commit for hygiene violations. v1.4.0 will add:

- `bootstrap.sh --verify-hygiene [dir]` — scans a project for hygiene violations and reports
- Optional pre-commit hook for secret scanning
- Optional CI integration for gitignore baseline checking

Until v1.4.0 ships, agents are the primary enforcement mechanism. Use this contract as your checklist on every task.

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
