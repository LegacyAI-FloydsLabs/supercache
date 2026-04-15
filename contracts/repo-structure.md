# Repository Structure Contract
**Version:** 1.3.0
**Governance:** .supercache/ v1.3.0
**Owner:** Douglas Talley / Legacy AI

This contract governs the structural layout of every repository under Legacy AI. It is the authoritative reference for how source code, tests, docs, configs, and build artifacts are organized, and it is the playbook for migrating non-compliant repositories into compliance.

It is READ-ONLY. The sole write path: Douglas Talley → GitHub PR → merge → git pull.

---

## Core Rule

Every repository SHOULD follow the canonical structure for its primary language, unless a documented project-specific exception exists in that project's `FLOYD.md` Project Rules section.

When a repository deviates from the canonical structure, one of two things must be true:
1. The deviation is **intentional, documented, and justified** in `FLOYD.md` with a rationale, OR
2. The repository is **flagged for migration** via an Issue entry and a migration plan is produced using the workflow in this contract.

Undocumented structural drift is a governance violation.

---

## Four Structural Anti-Patterns

Agents working on repositories MUST recognize these four patterns and flag them on first contact:

### 1. Nested Platform Syndrome

**Symptom**: The actual application lives in a subfolder (e.g., `starter-app/`, `my-project/`, `template/`) instead of at repo root.

**Example**:
```
repo-root/
├── README.md
└── my-app/          ← Everything is here, one level deeper than it should be
    ├── src/
    ├── package.json
    └── ...
```

**Correct**:
```
repo-root/
├── README.md
├── src/             ← At repo root, where build tools expect it
├── package.json
└── ...
```

**Why it matters**: Build tools, IDEs, CI/CD, and most language toolchains expect the project root to contain the primary manifest file (`package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`). When the actual project is nested, every tool requires custom configuration.

### 2. Starter Folder Confusion

**Symptom**: Multiple starter templates, examples, or candidate folders exist at repo root, and it's unclear which should become the authoritative project.

**Example**:
```
repo-root/
├── starter-basic/
├── starter-advanced/
├── examples/
└── README.md
```

**Correct**: Pick one canonical starter, promote it to repo root, move other starters to `examples/` or delete them.

**Why it matters**: Future agents (and humans) cannot reliably answer "where is the real code?" and waste context on exploration.

### 3. Mixed Concerns at Root

**Symptom**: Source code, build artifacts, documentation, tooling, and configs all at root level with no organization.

**Example**:
```
repo-root/
├── utils.js
├── helper.js
├── README.md
├── docs.md
├── build.sh
├── main.go
└── output.bin
```

**Correct**: Move source to `src/`, docs to `docs/`, scripts to `scripts/`, gitignore build outputs.

**Why it matters**: Root should contain only top-level manifests, README, LICENSE, `.gitignore`, and governance files. Everything else is cargo-culted clutter.

### 4. Multi-Language Chaos

**Symptom**: Multiple language implementations in one repo with no clear separation.

**Correct**: Either split into separate repos OR use a monorepo structure (`packages/`, `apps/`, `crates/`, or `services/`) with one language per subdirectory.

**Why it matters**: Mixed languages at root break every language's native tooling assumptions.

---

## Canonical Layouts by Language

These are the structures agents should target when creating new repositories or migrating non-compliant ones. Deviations require documented rationale.

### TypeScript / Node.js

```
project/
├── src/                         # All source code
├── tests/ or __tests__/         # Test files
├── dist/ or build/              # Compiled output (gitignored)
├── docs/                        # Documentation
├── scripts/                     # Build/utility scripts
├── public/                      # Static assets (for web apps)
├── node_modules/                # Dependencies (gitignored)
├── package.json
├── package-lock.json or pnpm-lock.yaml or yarn.lock
├── tsconfig.json                # If TypeScript
├── .gitignore
├── .env.example                 # Template only — never .env
├── README.md
├── FLOYD.md                     # Governance spec
└── SSOT/, Issues/, .floyd/      # Governance write zones
```

**Conventions**:
- Source in `src/`, never at root
- Tests colocated (`__tests__/`) or separate (`tests/`), pick one
- `dist/` or `build/` always gitignored
- Never commit `.env`; commit `.env.example` instead
- Lockfile MUST be committed

### Python

**Option A — `src/` layout (recommended for packages)**:
```
project/
├── src/
│   └── mypackage/
│       ├── __init__.py
│       └── module.py
├── tests/
├── docs/
├── scripts/
├── pyproject.toml or setup.py
├── requirements.txt or Pipfile or poetry.lock
├── .python-version              # If using pyenv
├── .gitignore
├── README.md
├── FLOYD.md
└── SSOT/, Issues/, .floyd/
```

**Option B — flat layout (for simple scripts)**:
```
project/
├── mypackage/
│   ├── __init__.py
│   └── module.py
├── tests/
├── setup.py
├── README.md
└── FLOYD.md
```

**Conventions**:
- Use `src/` layout for anything that will be packaged/distributed — it prevents import issues
- Flat layout is fine for scripts and small tools
- `__pycache__/`, `*.pyc`, `.venv/`, `venv/`, `*.egg-info/` always gitignored
- `requirements.txt` or `pyproject.toml` (PEP 621) committed

### Go

```
project/
├── cmd/
│   └── myapp/
│       └── main.go              # Each executable in its own subfolder
├── internal/                    # Private application code (not importable externally)
├── pkg/                         # Public library code (importable by other projects)
├── api/                         # OpenAPI/Swagger specs
├── web/                         # Web assets
├── scripts/
├── test/                        # Additional test data
├── docs/
├── go.mod
├── go.sum
├── .gitignore
├── README.md
├── FLOYD.md
└── SSOT/, Issues/, .floyd/
```

**Conventions**:
- `cmd/` for executables, one subfolder per binary
- `internal/` for code that MUST NOT be imported by other projects (enforced by Go toolchain)
- `pkg/` for reusable library code
- `go.mod` always at repo root — no nesting
- Vendored dependencies in `vendor/` if using vendor mode

### Rust

```
project/
├── src/
│   ├── lib.rs                   # For libraries
│   ├── main.rs                  # For binaries
│   └── bin/                     # Additional binaries
├── tests/                       # Integration tests
├── benches/                     # Benchmarks
├── examples/                    # Example code
├── target/                      # Build output (gitignored)
├── Cargo.toml
├── Cargo.lock                   # Commit for binaries; debatable for libraries
├── .gitignore
├── README.md
├── FLOYD.md
└── SSOT/, Issues/, .floyd/
```

**Conventions**:
- `src/lib.rs` for libraries, `src/main.rs` for binaries, both if dual-purpose
- `target/` always gitignored
- `Cargo.lock`: commit for binaries, your call for libraries
- Workspace members go in subdirectories with their own `Cargo.toml`

### Swift (iOS / macOS / SwiftPM)

```
project/
├── Sources/                     # SwiftPM source layout
│   └── MyPackage/
│       └── MyPackage.swift
├── Tests/
│   └── MyPackageTests/
│       └── MyPackageTests.swift
├── Package.swift                # SwiftPM manifest
├── Package.resolved             # Lockfile
├── .build/                      # Build output (gitignored)
├── .gitignore
├── README.md
├── FLOYD.md
└── SSOT/, Issues/, .floyd/
```

**For Xcode projects**:
```
project/
├── MyApp.xcodeproj/ or MyApp.xcworkspace/
├── MyApp/                       # Source code
├── MyAppTests/
├── MyAppUITests/
├── Fastfile                     # If using Fastlane
├── README.md
└── FLOYD.md
```

**Conventions**:
- SwiftPM: `Sources/` and `Tests/` (capitalized — this is the SwiftPM convention, not a mistake)
- Xcode: `.xcodeproj/` or `.xcworkspace/` at repo root
- `.build/`, `DerivedData/`, `Pods/` (if CocoaPods) always gitignored
- Never commit `Package.resolved` without thought — it pins transitive versions

### Other Languages

Other languages are supported on request. When encountering a language not covered here (Java, C#, Ruby, PHP, C/C++, Kotlin, Dart/Flutter, Elixir, etc.), consult the language's community-canonical structure from upstream docs or `/Volumes/SanDisk1Tb/reference/` and document the chosen structure in the project's `FLOYD.md`.

---

## General Patterns Across All Languages

**At repo root**:
- `README.md` — human-facing project intro
- `LICENSE` — legal
- `.gitignore` — language-appropriate (see `contracts/repo-hygiene.md`)
- Primary language manifest (`package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `Package.swift`)
- Lockfile (committed)
- `FLOYD.md` — Legacy AI governance spec
- `CLAUDE.md` — optional Claude adapter
- `SSOT/` — governance write zone
- `Issues/` — governance write zone
- `.floyd/` — governance write zone

**Always gitignored**:
- `node_modules/`, `target/`, `__pycache__/`, `.venv/`, `dist/`, `build/`, `.build/`, `DerivedData/`
- `.env`, `.env.*` (except `.env.example`)
- OS artifacts (`.DS_Store`, `Thumbs.db`)
- IDE-specific (`.vscode/` should be partially ignored, `.idea/` usually ignored)
- Build outputs, coverage reports, log files

See `contracts/repo-hygiene.md` for the complete gitignore baseline per language.

---

## Migration Workflow

When a repository needs structural migration, agents MUST follow this three-phase workflow. DO NOT execute migrations autonomously on non-trivial structural changes — produce the plan, get human approval, then execute.

### Phase 1: Reconnaissance

1. **Scan current structure**
   - List all top-level directories and files
   - Identify language/framework from manifest files
   - Note nested "app" or "starter" folders
   - Identify build artifacts and other `.gitignore` candidates

2. **Detect structural problems**
   - Does the real project live in a subfolder? (Nested Platform)
   - Are there multiple starter templates or candidate roots? (Starter Folder Confusion)
   - Is source code mixed with docs, configs, build artifacts at root? (Mixed Concerns)
   - Are there multiple languages without clear separation? (Multi-Language Chaos)

3. **Identify target structure** based on the canonical layout for the detected language

### Phase 2: Impact Analysis

1. **Dependency mapping**
   - Which files import/reference other files?
   - What are the current import paths?
   - What will break when files move?

2. **Configuration impact**
   - Which config files reference paths? (`tsconfig.json`, `package.json` scripts, `Makefile`, `pyproject.toml`, `Cargo.toml` workspace members, etc.)
   - Which CI/CD configs reference paths? (`.github/workflows/*`, `.gitlab-ci.yml`, `circle.yml`, etc.)
   - Which build tools reference paths? (`webpack.config.js`, `vite.config.ts`, `tsup.config.ts`, etc.)

3. **Risk assessment**
   - Can this migration be done incrementally?
   - Are there any blocking dependencies?
   - What is the rollback strategy?

### Phase 3: Migration Plan Generation

Produce a migration plan consisting of **three documents** using the template at `.supercache/templates/repo-migration-plan-template.md`:

1. **Analysis Report** — current state, target state, problems identified, risks, mitigation
2. **Step-by-Step Migration Plan** — 10-20 atomic steps, each ≤5 file moves/edits, each with validation and rollback
3. **LLM Executor Instructions** — how another agent can execute the plan in a new session without ambiguity

All three documents go in `SSOT/migration-plans/<DATE>-<BRIEF_DESCRIPTION>/` in the target project.

---

## Atomic Step Discipline

Every migration step MUST satisfy ALL of:

1. **Small**: completable in ≤5 file moves or edits; fits in one LLM context window
2. **Atomic**: can be done independently without breaking the repo's ability to build, even if the next step never runs
3. **Testable**: includes clear validation criteria (e.g., `npm run build && exit 0`, `git status --porcelain is empty`, `cargo check passes`)
4. **Reversible**: includes rollback instructions that restore the previous state

Steps that cannot satisfy all four are not atomic. Split them until they can.

---

## Safe Order of Operations

The canonical order for a structural migration:

1. **Backup** — create a new branch (`git checkout -b restructure-repo`) and confirm uncommitted work is either committed or stashed
2. **Baseline** — run existing tests and build; record baseline pass/fail state
3. **Create** new directory structure (empty folders)
4. **Move non-code files** first (docs, configs that don't reference paths)
5. **Move source files** using `git mv` (never `mv`) to preserve history
6. **Update import/require/use statements** — this is usually the largest diff
7. **Update configuration files** (`tsconfig.json`, `package.json`, `Cargo.toml` workspace, CI/CD)
8. **Update CI/CD configs** specifically (`.github/workflows/*`, etc.)
9. **Update README and documentation** to reflect new structure
10. **Delete old empty directories**
11. **Validate** — re-run tests and build, compare to baseline
12. **Commit with a clear message** describing the migration

Skipping step 1 (backup branch) is forbidden. The entire migration must be recoverable via `git checkout main` and `git branch -D restructure-repo`.

---

## Why `git mv` and not `mv`

Git tracks file moves heuristically. Using `mv` and then `git add`/`git rm` sometimes triggers the heuristic and sometimes doesn't — for large moves it often fails and you lose history. `git mv` guarantees git records the move as a rename, preserving `git blame`, `git log --follow`, and cross-repo history.

**Rule**: Use `git mv` for every source file move during migrations. Non-negotiable.

---

## Triple-Check Each Step

Before delivering a migration plan, verify each step against these five questions:

1. **Accuracy**: are the file paths correct for the current structure of the repo?
2. **Completeness**: did I account for all imports, configs, and references that depend on the moved files?
3. **Safety**: can this step be executed without breaking the repo's ability to build?
4. **Clarity**: can a junior developer or an average LLM execute this blindly?
5. **Reversibility**: can this step be undone if something goes wrong mid-execution?

Any "no" requires revising the plan until the answer is yes.

---

## Relationship to Other Contracts

- **`repo-hygiene.md`** — complements this contract. Repo-structure defines where files go; repo-hygiene defines what to clean up, what to gitignore, and what not to commit.
- **`document-management.md`** — defines where documentation goes once the structure is established (e.g., `docs/` is created by this contract; what belongs in `docs/` is governed by document-management).
- **`git-discipline.md`** — defines the commit, push, and PR discipline for executing migrations.

---

## Enforcement Posture (v1.3.0)

This contract is **advisory** in v1.3.0. Agents should follow it; violations should be flagged via Issues; migration plans should be produced. Hard enforcement (pre-commit hooks, CI gates, `bootstrap.sh --verify-structure`) is deferred to v1.4.0 once the rules have been validated against real projects.

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
