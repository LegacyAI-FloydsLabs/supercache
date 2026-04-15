# Git Discipline Contract
**Version:** 1.3.0
**Governance:** .supercache/ v1.3.0
**Owner:** Douglas Talley / Legacy AI

This contract governs how agents interact with git, GitHub, and related version-control operations on behalf of Legacy AI. It combines Git best practices with strict IP protection and brand reputation safeguarding.

It is READ-ONLY. The sole write path: Douglas Talley → GitHub PR → merge → git pull.

---

## Prime Directive

Every commit and push is a **permanent, potentially public artifact** that must:

1. Ship clean, stable, well-explained changes
2. Never leak internal secrets, business intent, or private IP
3. Protect the reputation of Legacy AI and Douglas Talley / CaptainPhantasy
4. Be understandable in isolation by a competent developer years from now

Assume all commit messages, README surfaces, and public repo content may be read by potential clients, partners, investors, or recruiters.

---

## Pre-Commit Checklist (Required Before Any Commit)

Silently walk this checklist in exact order before recommending or executing any commit. If any step fails, do not commit — fix the issue or report a blocker.

### 1. Working Tree & Build Health

- Ensure working tree is clean OR all untracked work is explicitly documented
- Run appropriate checks for the detected stack:
  - **Rust**: `cargo test`, `cargo clippy`, `cargo fmt --check`
  - **TypeScript/Node**: `npm test` (or `pnpm test`/`yarn test`), `tsc --noEmit`, lint (`eslint`, `biome check`)
  - **Python**: `pytest`, `ruff check` or `flake8`, `mypy` if typed
  - **Go**: `go test ./...`, `go vet ./...`, `gofmt -l` or `golangci-lint run`
  - **Swift**: `swift test`, `swift build`, lint via SwiftLint if configured
- If any check fails:
  - Trigger the **Swarm Emulation Protocol** (below) to diagnose
  - Propose concrete fixes before committing
  - Only proceed once the repo is green or the failure is explicitly quarantined (WIP branch, non-protected)

### 2. Dependency & Lockfile Integrity

- Ensure dependency definitions and lockfiles are aligned (`Cargo.toml` ↔ `Cargo.lock`, `package.json` ↔ `package-lock.json`/`pnpm-lock.yaml`/`yarn.lock`, `pyproject.toml` ↔ `poetry.lock`, etc.)
- Avoid introducing unnecessary new dependencies
- Flag risky or abandoned dependencies (no commits in 2+ years, known CVEs, security advisories)
- Never commit dependency updates without re-running the test suite

### 3. Diff Review & Secret Hygiene

- Review `.gitignore` to ensure it excludes `.env`, local caches, build artifacts, log files
- Perform a **secret scan** on the staged diff before committing. Look for:
  - API keys (`sk-`, `AIza`, `ghp_`, `xoxb-`, `AKIA`, etc.)
  - Tokens (bearer tokens, OAuth tokens, session tokens)
  - Passwords (even "test" passwords — they leak production-ready patterns)
  - Private URLs (internal domains, infrastructure hostnames)
  - Database connection strings (especially with credentials embedded)
  - Private SSH keys, TLS certificates, private keys of any kind
  - High-entropy strings that look like credentials
- If suspected secrets appear: **do not commit**. Recommend environment variables instead. Remove from staging. Consider rotating the secret if it's already been staged more than a moment.

### 4. Error Squashing

- Read the full diff like a meticulous code reviewer
- Identify logic bugs, regressions, unsafe refactors
- Suggest tests or assertions to cover new behavior
- Flag any TODO/FIXME/XXX/HACK comments added in this diff

### 5. Commit Message Quality

- Draft a clear commit message following the standards below
- Verify the message is understandable without context from surrounding messages
- Verify the message contains no forbidden content (see "Forbidden Commit Content" below)

---

## Commit Message Standards

### Tone & Structure

- Concise, concrete, professional
- Default format: short title (50-72 characters, imperative mood) + optional body explaining **what** and **why**
- Do not explain the how — the diff shows the how

### Title Format

```
<type>: <description>
```

Types (conventional commits flavor):
- `feat:` — new feature or capability
- `fix:` — bug fix
- `refactor:` — restructuring without behavior change
- `docs:` — documentation only
- `test:` — test additions or updates
- `chore:` — routine maintenance (deps updates, config tweaks)
- `perf:` — performance improvement
- `ci:` — CI/CD configuration changes
- `build:` — build system changes

Title should be **imperative mood**: "add feature", not "added feature" or "adds feature".

Title should be **under 72 characters** so it fits in git log / GitHub UI without wrapping.

### Body (when needed)

When the commit is non-trivial, add a body explaining:
- **What** changed at a high level
- **Why** it changed — the motivation, the bug, the requirement
- **Any non-obvious consequences** — breaking changes, migration notes, related PRs

Wrap body text at 72 characters per line.

### Examples

**Good**:
```
feat: add passwordless login flow

Introduces magic-link authentication via email, replacing the
previous password-based flow. This reduces attack surface and
removes password storage from the system entirely.

BREAKING: users with existing passwords must re-authenticate
on next login. Migration path is handled in AuthMigrator.
```

**Also good** (no body needed):
```
fix: handle null timezone in date parser
```

```
refactor: extract ValidationResult into shared module
```

```
chore: bump tokio to 1.42.0 for CVE-2024-XXXXX
```

**Bad** (violates forbidden content rules):
```
feat: prepare repo for huge revenue launch
quick hack for demo to investor X
add secret pricing logic per partner agreement
```

---

## Forbidden Commit Content

NEVER include in commit messages, commit bodies, commit signatures, or code comments that will be committed:

- **Financial/business intent**: revenue targets, pricing, sales forecasts, investor language, monetary gain
- **Client/partner names**: specific customers, clients, prospects, deals in progress
- **Proprietary algorithms**: trade secrets, internal model weights, optimization techniques that provide competitive advantage
- **Internal code names**: confidential program names, unreleased product names, internal project codenames
- **Business strategy**: competitive positioning, go-to-market plans, unannounced features
- **Credentials or secrets**: see secret hygiene rules above
- **Personal information**: real names (other than authors), emails other than author address, addresses, phone numbers
- **Accusations or emotional language**: "fix stupid bug by X", "revert dumb change", blame attribution

If any of the above appears in a draft commit message, revise before committing.

---

## README and Documentation Guardrails

When creating or editing README.md, docs/, or any other public-facing document:

### Tone Strategy

- Technical, concise, empowering
- Avoid marketing fluff or hype words ("revolutionary", "game-changing", "best-in-class", "industry-leading")
- Write for a competent developer who respects precision and craftsmanship
- Active voice, present tense

### What to Emphasize

- Clear description of what the code does (utility, purpose)
- How to run it (installation, quickstart, common commands)
- High-level architecture (useful without revealing implementation secrets)
- Setup steps and dependency notes
- Compatibility (supported OSes, language versions, runtime requirements)

### What to Avoid

- Internal code names for confidential programs
- Business rationale ("we built this to capture market segment X")
- Financial or pricing strategy
- Client or partner identifiers
- Implementation secrets (specific prompt engineering, model selection rationale, proprietary optimizations)
- Unannounced features or roadmap
- Vendor-specific advantages that might tip off competitors

### Public vs. Private Repos

The rules above apply to **all** repositories, regardless of whether they are currently public or private. Privacy settings change; commits persist. Assume every commit will eventually be public.

---

## Force-Push, Hooks, and Destructive Operations

### Never force-push to `main`

Force-pushing to `main` (or any protected branch) rewrites shared history and can destroy other people's work. Never force-push to main without **explicit human instruction** from Douglas Talley. If a force-push to main is required, it must be preceded by a backup branch (`git branch main-backup-YYYY-MM-DD`) and followed by verification that all collaborators have been notified.

### Never skip hooks without instruction

Do not use `--no-verify`, `--no-gpg-sign`, or equivalent flags to bypass commit hooks unless Douglas has explicitly instructed you to. If a hook is blocking a legitimate commit, investigate the hook's complaint and fix the underlying issue.

### Never `git reset --hard` on shared branches

`git reset --hard` discards uncommitted work silently. On a shared branch, this can destroy in-progress work by other people. Only use `git reset --hard` on your own local branches, and only after confirming no uncommitted changes matter.

### Never `git push --force` without a backup branch

Even on your own branches, create a backup branch before force-pushing so you can recover if you pushed the wrong state.

### Never `git clean -fdx` without listing what will be deleted first

`git clean -fdx` removes untracked files including `.gitignored` files like `.env`. Always run `git clean -n` first to preview.

---

## The Swarm Emulation Protocol

When diagnosing complex errors, architectural decisions, or ambiguous bugs, do not converge on a single solution immediately. Instead, **simulate a swarm** by sequentially adopting distinct perspectives:

1. **The Security Engineer**: "What attack surface does this change open? What secrets could leak? What trust boundaries are crossed?"
2. **The QA Tester**: "What edge cases are not covered? What happens with null/empty/huge/concurrent inputs? What breaks under stress?"
3. **The API Architect**: "Is this change consistent with the existing API? Does it violate separation of concerns? Is there a cleaner abstraction?"
4. **The Performance Engineer**: "What is the time and space complexity? Does this introduce allocations in hot paths? Are there N+1 queries?"
5. **The Future Maintainer**: "Will I understand this six months from now? Is the intent obvious? Are there load-bearing comments that would be easy to delete accidentally?"

Reason through the problem from each angle, collect their concerns, then converge on a solution that addresses all of them. This protocol is mandatory for complex bug investigations and optional for routine commits.

---

## Self-Critique Before Any Git Action

Before delivering your final recommendation or executing any Git operation, silently ask:

1. **Is anything here leaking secrets, tokens, or credentials?**
2. **Is any messaging exposing Legacy AI's strategy, client list, or unannounced plans?**
3. **Is the commit understandable without the context of the current conversation?**
4. **Would Douglas Talley / CaptainPhantasy be proud to have this associated with the brand?**
5. **Does this change respect the External Identity Rule (customer-facing = "Floyd")?**

If the answer to any is not a clear yes, revise, tighten, and sanitize until it is.

---

## Integration with External Identity Rule

The Git Discipline contract works in concert with the External Identity Rule in `contracts/agent-contract.md`.

- **Public code comments**: treated as customer-facing. Refer to the system as "Floyd" where relevant. Never mention the underlying model or harness.
- **README and docs**: customer-facing. Same rule.
- **Commit messages**: Douglas's name appears as author; co-author trailer may mention "Claude Opus 4.6" when appropriate for attribution inside Legacy AI, but **commit bodies intended for public view should not name internal implementation details**.
- **Issue/PR descriptions**: customer-facing. Write as if a customer will read them.
- **GitHub Actions logs**: potentially customer-visible. Do not log secrets or internal paths.

---

## GitHub-Specific Discipline

### Pull Requests

- PR title: same rules as commit title (imperative mood, under 72 chars, conventional type prefix)
- PR body: use the project's PR template if `.github/pull_request_template.md` exists
- Link to relevant Issues via "Closes #N" / "Fixes #N"
- Request review from appropriate CODEOWNERS
- Do not merge your own PR without approval unless explicitly authorized

### Issues

- Use templates in `.github/ISSUE_TEMPLATE/` if they exist
- Label appropriately (bug, feature, docs, etc.)
- Assign to the right owner
- Never include secrets or internal details in public issue bodies

### CODEOWNERS

- Respect `CODEOWNERS` file if present — do not bypass required reviewers

### GitHub Actions

- Never log secrets (`echo "$API_KEY"` is a fireable offense)
- Use `${{ secrets.XXX }}` for credentials, never hardcode
- Pin action versions to SHAs or major versions, not `@main`
- Review third-party actions before adopting them

---

## Co-Authorship Attribution

When Claude or another AI assists in a commit, the following trailer format is acceptable:

```
Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
```

**When to include**: commits where Claude contributed significant code, design, or prose.

**When to omit**:
- Commits that are customer-facing deliverables (see External Identity Rule)
- Commits where the AI contribution was trivial (single-line fixes)
- When Douglas specifies no-attribution mode

**Never falsify**: do not attribute work to Claude that Claude did not do, and do not attribute Claude work to a human.

---

## Enforcement Posture (v1.3.0)

This contract is **advisory** in v1.3.0. Agents should follow it, and failures should be flagged, but hard enforcement (CI gates, pre-commit hooks for secret scanning, automated message linting) is deferred to v1.4.0.

One hard enforcement is already active: the `.supercache/` drift-prevention hook (`hooks/supercache-repo-precommit.sh`) blocks commits to the governance repo itself if version-bearing files drift. That is separate from this contract and already operational.

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
