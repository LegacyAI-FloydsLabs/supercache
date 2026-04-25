# Legacy AI Governance — Changelog

Newest first.

---

## v1.4.1 — 2026-04-25

Scope: cross-harness governance compliance. Make the v1.4.0 alignment work mechanical for non-Claude-Code harnesses (OhMyFloyd via TypeScript extension, Crush-derived via wrapper-script bridge).

### Added

- **Cross-Harness Memory Bridge** section in `contracts/agent-contract.md`. Mandates that any agent finding `$FLOYD_GOVERNANCE_CONTEXT` set in its environment MUST read the referenced file before non-trivial work. Closes the "different harnesses interpret governance differently" gap by giving Crush-derived workhorses a mechanical path to the same `~/.claude/MEMORY.md` that Claude Code reads directly.
- **Companion infrastructure outside `.supercache/`** (not in this PR but documented here for the propagation record):
  - `~/.claude/MEMORY.md` — single source of truth for environment-level facts.
  - `~/.claude/hooks/session-start.sh` — Claude Code transport.
  - `~/.omp/agent/hooks/pre/governance-alignment.ts` — OhMyFloyd transport.
  - `~/.claude/hooks/floyd-harness-bootstrap.sh` — Crush-family bootstrap; sourced by harness wrapper scripts (e.g., `/opt/homebrew/bin/superfloyd`).

### Changed

- **`contracts/agent-contract.md`** — new section after "Governance Version Alignment Check" and before "Before You Start". Version bumped 1.4.0 → 1.4.1.
- **`VERSION`**, **`README.md`**, **`contracts/document-management.md`**, **`contracts/execution-contract.md`** — version headers bumped 1.4.0 → 1.4.1 to keep the precommit drift check happy. No content changes in those files.

### Unchanged (explicitly)

- `contracts/git-discipline.md`, `contracts/repo-structure.md`, `contracts/repo-hygiene.md` — untouched.
- `templates/floyd-md-template.md` — not modified in this release. Future projects bootstrapped via `bootstrap.sh --init` will get the `agent-contract.md` reference automatically; the new env-var rule applies via the universal contract, not via per-project FLOYD.md content.

### Migration step (post-merge)

Same as v1.4.0:

```bash
bash /Volumes/SanDisk1Tb/.supercache/scripts/post-bump-sweep.sh --repair
```

This re-stamps governed projects to 1.4.1 so the SessionStart drift check in Claude Code passes cleanly.

### Verification plan (post-merge)

1. `cat /Volumes/SanDisk1Tb/.supercache/VERSION` → expect `1.4.1`
2. `grep -c "Cross-Harness Memory Bridge" /Volumes/SanDisk1Tb/.supercache/contracts/agent-contract.md` → expect ≥1
3. `bash ~/.claude/hooks/session-start.sh` from a CURRENT project → memory loads, no drift notice
4. (When superfloyd is run): wrapper sources `floyd-harness-bootstrap.sh`, exports `$FLOYD_GOVERNANCE_CONTEXT`, agent reads it per the new contract section

---

## v1.4.0 — 2026-04-24

Scope: add canonical homes for agent-written reports and research; strengthen doc-management enforcement language; introduce scoped Floyd Docs governance.

### Added

- **Shared Agent Deposits tier.** Two new canonical document homes for long-form agent output, backed by Google Drive via `/Volumes/Storage/Floyd Docs/`:
  - Reports: `Reports/<YYYY-MM-DDTHH-MM>_<topic-slug>/report.md`
  - Research: `Research/<YYYY-MM-DDTHH-MM>_<topic-slug>/research.md`
  - Directories are treated as append-only historical records.
- **`/Volumes/Storage/Floyd Docs/FLOYD.md`.** New scoped governance document for the deposit folder. Invoked on request (not auto-enforced every session). Lives outside `.supercache/` (writable by Douglas directly, no PR needed for that file).
- **Governance Version Alignment Check** in `contracts/agent-contract.md`. New MANDATORY session-start step requiring every agent to compare `.floyd/.supercache_version` against canonical `.supercache/VERSION` and stop on drift. Pull-side enforcement for governance updates — makes bumps visible in the next session of each project.
- **`scripts/post-bump-sweep.sh`.** New release automation. After every supercache bump, run `bash .supercache/scripts/post-bump-sweep.sh --repair` to walk all governed projects and refresh their version stamps. `--doctor` mode (default) dry-runs; `--repair` performs updates.

### Changed

- **`contracts/document-management.md`**:
  - Version header bumped 1.3.0 → 1.4.0.
  - Canonical Document Homes table: two new rows for shared agent reports and research.
  - New section "Shared Agent Deposits Tier" after "Reference Materials Tier", modeled on that tier's structure.
  - Enforcement Posture header bumped to v1.4.0; hard-enforcement target (`bootstrap.sh --verify-docs`) deferred from v1.4.0 to v1.5.0.
- **`contracts/agent-contract.md`**:
  - Version header bumped 1.3.0 → 1.4.0.
  - New section "Governance Version Alignment Check (MANDATORY, runs first)" inserted before "Before You Start".
- **`VERSION`** bumped 1.3.0 → 1.4.0.

### Migration step (one-time, required for this release)

After merging this PR and running `git pull` in `/Volumes/SanDisk1Tb/.supercache/`, Douglas MUST run the new sweep script to stamp all governed projects at 1.4.0:

```bash
bash /Volumes/SanDisk1Tb/.supercache/scripts/post-bump-sweep.sh --repair
```

This stamps the 7 projects that currently lack a `.floyd/.supercache_version` file AND updates the 2 already-stamped projects from 1.3.0 to 1.4.0. Projects identified as unstamped on 2026-04-24:

- `/Volumes/SanDisk1Tb/` (drive root governed project)
- `/Volumes/Storage/floyd/`
- `/Volumes/Storage/Gordy/`
- `/Volumes/Storage/PSI/`
- `/Volumes/Storage/Floyd Docs/`
- `/Volumes/Storage/Floyd_OpenFloyd/`
- `/Volumes/Storage/LegacyAINexus/`

Already-stamped at 1.3.0 (will bump to 1.4.0 via the same sweep):

- `/Volumes/Storage/LegacySiteTest/`
- `/Volumes/Storage/harness-launcher/`

Without this step, agents entering bootstrapped projects after the merge will hit the new Alignment Check and stop on drift until the stamp is repaired manually per-project.

### Unchanged (explicitly)

- Enforcement remains **advisory** for `document-management.md`. No new code-level pattern scanner in this release.
- `contracts/execution-contract.md` — untouched.
- `contracts/git-discipline.md` — untouched.
- `contracts/repo-structure.md` — untouched.
- `contracts/repo-hygiene.md` — untouched.
- Canonical `.supercache/` location — still `/Volumes/SanDisk1Tb/.supercache/` with `/Volumes/Storage/.supercache/` as symlink.
- Retired supercache at `~/Library/CloudStorage/GoogleDrive-douglastalley1977@gmail.com/My Drive/Floyd_Ecosystem/supercache.retired-20260415/` — left in place as archival; confirmed unused (VERSION 1.2.0, unmodified since 2026-04-15, zero references anywhere on disk).

### Propagation plan

1. **Supercache canonical** (`/Volumes/SanDisk1Tb/.supercache/`) — updated via `git pull` after PR merges.
2. **Supercache symlink** (`/Volumes/Storage/.supercache/`) — auto-updates (symlink).
3. **GitHub** (`LegacyAI-FloydsLabs/supercache`) — PR merged.
4. **Downstream bootstrapped projects** — retro-stamp the 7 unstamped projects as part of this release (see Migration step); thereafter, the new Alignment Check enforces drift detection on every session. Release sweep via `scripts/post-bump-sweep.sh --repair` is the recommended cadence.

### Rationale

The previous governance had no canonical home for agent-written reports and research. Agents defaulted to `~/Documents/` (user-owned) or repo roots (clutter). The new tier gives cross-device, cloud-backed storage that survives drive changes and stays out of individual repos. Scoping it to Floyd Docs (via a dedicated FLOYD.md) rather than baking rules into every repo's governance prevents scope bloat.

### Verification plan (post-merge)

1. `cat /Volumes/SanDisk1Tb/.supercache/VERSION` → expect `1.4.0`
2. `grep -c "Shared Agent Deposits" /Volumes/SanDisk1Tb/.supercache/contracts/document-management.md` → expect ≥1
3. `ls /Volumes/Storage/Floyd\ Docs/FLOYD.md` → expect present
4. Floyd Docs `Reports/` and `Research/` subdirectories remain usable and unchanged.

---

## v1.3.0 — (prior)

No prior changelog entry exists in the repo; history before 1.4.0 lives in `~/Documents/governance-migration-2026-04-15.md` and commit history.
