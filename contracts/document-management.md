# Document Management Contract
**Version:** 1.3.0
**Governance:** .supercache/ v1.3.0
**Owner:** Douglas Talley / Legacy AI

This contract governs what documents agents create, where those documents live, how they are named, and how they are maintained over time. It is the authority for document lifecycle and anti-cruft enforcement.

It is READ-ONLY. The sole write path: Douglas Talley → GitHub PR → merge → git pull.

---

## The Anti-Cruft Rule (Core Rule)

**NEVER create documentation files unless the user explicitly requests them.**

This is the strongest anti-clutter rule in Legacy AI governance. It exists because agents have a tendency to over-document: creating `NOTES.md`, `TODO.md`, `PLAN.md`, `RATIONALE.md`, `DECISIONS.md`, `CLEANUP.md` files that outlive the work they describe and pollute the repository forever.

When in doubt, put the information in conversation, in an existing file, or nowhere. Not a new document.

**Exceptions** (times when creating documentation IS appropriate):

1. The user **explicitly requests** a document (by name, purpose, or topic)
2. A **canonical location** already exists for this type of content (e.g., the project's `SSOT/decision-log.md`, `Issues/NNN-*.md`)
3. The document is **governance-required** (e.g., `FLOYD.md` created by `bootstrap.sh --init`)
4. A **migration or refactoring** genuinely needs a plan document that persists across sessions (use `~/Documents/` for user-facing records)
5. A **README** for a new project the user just created

When in doubt, ask. Creating a file and then asking "should I have?" is the wrong order.

---

## Canonical Document Homes

Every document type has a canonical location. If an agent is creating a document and cannot identify which row in this table it belongs in, that is a strong signal that the document should not be created at all.

| Document Type | Canonical Location | Purpose | Lifecycle |
|---|---|---|---|
| Public-facing project intro | project root `README.md` | Human-facing overview, setup, usage | Stable, updated sparingly |
| Technical docs | `docs/` subdirectory | Architecture, API reference, guides | Stable, updated on feature changes |
| Project state summary | `SSOT/<PROJECT_NAME>_SSOT.md` | Current state, architecture facts, verification record | Living document, append-only change log |
| Decisions | `SSOT/decision-log.md` | Architectural decisions with rationale | Append-only, never edit old entries |
| Issues / bugs / tasks | `Issues/<PROJECT_NAME>_ISSUES.md` | Help-desk ledger with lifecycle | Living document, append-only change log |
| Per-issue detail | `Issues/NNN-description.md` | Deep detail on a single issue when the ledger row isn't enough | Created on demand, closed/archived when resolved |
| Session handoffs | `.floyd/HANDOFF_YYYY-MM-DD.md` | Agent-to-agent session state | Ephemeral; delete after consumed by next session |
| Agent scratch | `.floyd/scratch/*` | Intermediate agent work | Ephemeral; cleanup encouraged |
| Migration records | `SSOT/migration-plans/<DATE>-<DESCRIPTION>/` | Multi-document migration plans (per `contracts/repo-structure.md`) | Persistent for the duration of the migration; archived after completion |
| User-facing session records | `~/Documents/` on the user's machine | Records of significant sessions/migrations for the user's reference | User owned; agents write with explicit request only |
| API reference (generated) | `docs/api/` | Auto-generated API docs | Regenerated, never hand-edited |
| Change log (release notes) | `CHANGELOG.md` at repo root | User-facing release history | Append-only at the top (newest first) |
| License | `LICENSE` at repo root | Legal | Rarely changes |
| Governance (FLOYD.md) | project root `FLOYD.md` | Legacy AI canonical per-project spec | Created by `bootstrap.sh --init`; edited as project evolves |
| Governance (CLAUDE.md) | project root `CLAUDE.md` | Claude-specific adapter (optional) | Created by `bootstrap.sh --add-claude`; edited rarely |

If a document type isn't in the table above, default to **not creating it** unless the user asks.

---

## Naming Conventions

### Markdown files

- **kebab-case** for general docs: `migration-plan.md`, `api-reference.md`, `troubleshooting-guide.md`
- **SCREAMING_SNAKE_CASE** for traditional root-level files: `README.md`, `LICENSE`, `CHANGELOG.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md` (these have strong convention from GitHub tooling)
- **`<PROJECT_NAME>_SUFFIX.md`** for per-project governance files: `MyProject_SSOT.md`, `MyProject_ISSUES.md`
- **Date-prefixed** for historical records: `2026-04-15-governance-migration.md`, `HANDOFF_2026-04-15.md` — dates are ISO 8601 (`YYYY-MM-DD`)
- **Numbered** for ordered sequences: `001-initial-architecture.md`, `002-api-design.md` (decisions, issues, migration steps)

### Do NOT use

- `TODO.md`, `NOTES.md`, `RANDOM.md`, `SCRATCH.md`, `TEMP.md`, `TEST.md` at project root — these are agent-cruft magnets and always end up stale
- Spaces in filenames — breaks shell quoting, looks sloppy
- Non-ASCII characters in filenames unless genuinely needed
- Emoji in filenames — impossible to type, awkward in paths

---

## Per-Project Governance Filenames

Every governed project has (at minimum):

```
project/
├── FLOYD.md                             # Canonical project spec
├── CLAUDE.md                            # Optional Claude adapter
├── SSOT/
│   └── <PROJECT_NAME>_SSOT.md           # Project state + verification record
└── Issues/
    └── <PROJECT_NAME>_ISSUES.md         # Help-desk ledger
```

`<PROJECT_NAME>` is the directory basename (e.g., `LegacySiteTest`, `legacy_site`, `my_app`), sanitized to remove spaces if any exist. `bootstrap.sh --init` handles the substitution automatically.

**Per-issue detail files** are optional and live alongside the ledger when a single ledger row isn't enough:

```
Issues/
├── <PROJECT_NAME>_ISSUES.md             # Top-level ledger
├── 001-auth-token-refresh-loop.md       # Deep detail on issue 001
├── 002-build-fails-on-m1.md             # Deep detail on issue 002
└── ...
```

---

## Issues Ledger — Required Structure

The `Issues/<PROJECT_NAME>_ISSUES.md` file MUST match the structure in `.supercache/templates/issues-template.md`.

### Lifecycle

Every issue has a lifecycle. Status values (and their meanings):

| Status | Meaning |
|---|---|
| **New** | Captured; not yet triaged |
| **Triaged** | Scoped; priority set; owner assigned |
| **In progress** | Active work underway |
| **Blocked** | Cannot proceed; record blocker and next unblock action |
| **Resolved** | Fix implemented; proof attached |
| **Verified** | Fix confirmed by rerun, test, or log evidence |
| **Closed** | Complete and stable; no further action expected |

Issues move forward through these states. Backward moves are allowed if new information invalidates the previous transition (e.g., Closed → New if the bug recurs).

### Required fields per issue

Every issue row requires:

1. **ID** — stable identifier (`ISSUE-0001`, `ISSUE-0002`, etc.)
2. **Created timestamp** — `YYYY-MM-DD HH:MM TZ`
3. **Title** — one-line summary
4. **Status** — from the lifecycle table above
5. **Owner** — assigned person or "Unassigned"
6. **Evidence / Links** — logs, screenshots, commands, failing step, related files
7. **Resolution Proof** — how the fix was verified; "N/A" until resolved

### Append-only change log

Every significant update to the ledger appends a new timestamped line to the bottom-of-file change log. Never silently overwrite historical facts. The change log is the audit trail.

---

## SSOT — Required Structure

The `SSOT/<PROJECT_NAME>_SSOT.md` file is the **authoritative document** for architecture and programmatic change facts. All other documents are treated as **potentially flawed** unless confirmed here.

It MUST match the structure in `.supercache/templates/ssot-template.md`.

### Authority

The SSOT is the single source of truth. If another document disagrees with the SSOT on a project fact, the SSOT wins. If the SSOT itself is wrong, it is updated via the verification sweep protocol, not by editing other documents.

### Verification Sweep Protocol (required)

When an agent reads the SSOT for a task:

1. Perform a **line-by-line verification review** of the sections relevant to the current task
2. For each verified fact, append a verification entry with:
   - Timestamp (`YYYY-MM-DD HH:MM TZ`)
   - Section/line reference
   - Evidence source (code path, command output, build log, runtime behavior)
   - Confidence = 100%
3. If any fact cannot be verified to 100% confidence:
   - Mark it **UNVERIFIED** in the SSOT
   - Add an Issue in `Issues/<PROJECT_NAME>_ISSUES.md` to track the discrepancy
   - Do NOT proceed on the assumption that the fact is true

### Positive Reinforcement

For each fact verified at 100% confidence during a sweep, emit the acknowledgement:

```
Verified as fact (100%): <fact summary>
```

This is not decoration; it is a deliberate pattern that reinforces evidence-first thinking and makes the verification record auditable.

### Change Log

The SSOT has an append-only change log at the bottom. Every edit adds a new timestamped entry. Old entries are never modified or removed.

---

## Reference Materials Tier

Legacy AI maintains a **read-only reference library** at `/Volumes/SanDisk1Tb/reference/` for agents to consult when they need public-domain patterns, examples, or authoritative documentation.

### Structure

```
/Volumes/SanDisk1Tb/reference/
├── README.md                            # Tier-level contract
├── scraped_repos/                       # Community reference (60 repos: awesome-*, roadmaps, etc.)
│   └── INDEX.md                         # Catalog of what's available
└── canonical_sources/                   # Primary documentation (Rust book, Python PEPs, OWASP, etc.)
    └── INDEX.md                         # Catalog of what's available
```

### Rules

1. **Read-only**: agents MUST NOT write to, edit, or delete anything under `/Volumes/SanDisk1Tb/reference/`
2. **Updates**: content is refreshed by re-scraping from upstream (not by editing in place)
3. **Consult the INDEX first**: before diving into any specific subfolder, read the INDEX.md to find what you need
4. **Prefer canonical_sources over scraped_repos** when authoritative docs exist (e.g., Python PEPs over awesome-python when the question is about a specific PEP)
5. **Reference, don't copy**: point agents and documentation at the reference tier location; do not copy its content into project repos

### What belongs here vs. what doesn't

| Belongs | Does NOT belong |
|---|---|
| Public GitHub reference repos | Private Legacy AI code |
| Canonical language/framework docs | Secrets, credentials, tokens |
| Open-source cheat sheets | Client-specific content |
| Public standards (PEPs, KEPs, RFCs) | Work-in-progress scratch files |
| Curated "awesome-*" lists | Session handoffs |

---

## Forbidden Document Patterns

These patterns are disallowed regardless of context:

### At project root

- `NOTES.md`, `TODO.md`, `SCRATCH.md`, `RANDOM.md`, `TEMP.md`, `TEST.md`
- Parallel versioned session logs (`session-1.md`, `session-2.md`, `session-final.md`, `session-final-2.md`)
- `cleanup-plan.md`, `migration-plan.md`, `refactor-plan.md` that outlive the cleanup/migration/refactor
- READMEs in every subdirectory without a clear human need
- Multiple competing architecture documents (`ARCHITECTURE.md`, `DESIGN.md`, `ARCH-NEW.md`)

### Anywhere

- Commented-out content dumps masquerading as documentation
- Lorem-ipsum placeholder content that was never replaced
- Auto-generated docs committed without generation scripts (how do we regenerate?)
- Binary files (PDF, DOCX, XLSX) committed without explicit need — prefer Markdown

---

## Document Lifecycle

1. **Create** — only when needed, in the right location, with the right name
2. **Update** — prefer editing existing documents over creating parallel versions. If you need a new version, archive the old one (`archive/old-name-2026-04-15.md`) and replace
3. **Archive** — move superseded documents to `archive/` subfolder or `.floyd/archive/` when they still have historical value
4. **Delete** — remove fully ephemeral artifacts (session handoffs after consumed, scratch after cleanup, intermediate plans after completion)

### Archival vs deletion

- **Archive** if: the document has historical value (migration plans, post-mortems, old decisions that explain why current state is what it is)
- **Delete** if: the document is purely ephemeral (session handoffs, scratch notes, intermediate plans, temporary status files)

---

## User-Facing Migration Records

When a session performs significant architectural work (migrations, governance refactors, multi-phase refactoring), the agent SHOULD produce a user-facing record in `~/Documents/` on the user's machine. Examples from recent sessions:

- `~/Documents/governance-migration-2026-04-15.md` — v1.2.0 governance rollout record
- `~/Documents/at-risk-inventory-2026-04-15.md` — backup inventory analysis

These files are owned by the user and live outside any project repo. They:

- Serve as a persistent record for the user to consult later
- Provide orientation for future agent sessions that inherit the work
- Capture the **why** behind architectural decisions that aren't fully captured in commit messages
- Document lessons learned and future work

When creating such a file, structure it so that a future Claude session (or future Douglas) can pick up from it without the session context. Include:

- What the session accomplished
- What decisions were made and why
- Critical discoveries and lessons learned
- What was NOT done (future work)
- Orientation section for future sessions

---

## Relationship to Other Contracts

- **`repo-structure.md`** — defines where project directories go; this contract defines where documents within those directories go
- **`repo-hygiene.md`** — works together to prevent document cruft from accumulating in repos
- **`git-discipline.md`** — governs how documents are committed and what can be in commit messages
- **`execution-contract.md`** — the evidence-first rules that underpin the SSOT verification sweep protocol

---

## Enforcement Posture (v1.3.0)

This contract is **advisory** in v1.3.0. Agents should follow it; violations should be flagged. Hard enforcement (a `bootstrap.sh --verify-docs` command that scans for forbidden patterns) is deferred to v1.4.0.

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
