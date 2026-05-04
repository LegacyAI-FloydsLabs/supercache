# Repository Sanitation & Document Hygiene Contract

**Version:** 1.7.0
**Governance:** .supercache/ v1.7.0
**Owner:** Douglas Talley / Legacy AI
**Type:** Mandatory — applies to every agent on every task
**Supersedes deletion provisions of:** `contracts/repo-hygiene.md` (v1.3.0+ deletion policy) and `contracts/document-management.md` (v1.4.1 lifecycle "Delete" step)

> This contract codifies a single, non-negotiable rule across both code and document management: **agents do not delete.** They quarantine. The contract defines the quarantine mechanism, the daily bootstrap routine that enforces sanitation on every session, and the execution contract that proves both happened. It is the authoritative reference for repository sanitation health and document management best practices in Legacy AI governance.
>
> This contract is READ-ONLY. The sole write path: Douglas Talley → GitHub PR → merge → git pull.

---

## 1. Authority and Relationship to Other Contracts

This contract sits above the existing hygiene contracts on the topic of removal:

| Contract | Role under v1.6.0 |
|---|---|
| `repo-sanitation.md` (this file) | **Authoritative** — no-deletion rule, quarantine mechanism, bootstrap routine, execution contract for doc + repo sanitation |
| `repo-hygiene.md` | Subordinate — its `.gitignore` baselines, cleanup triggers, file-size limits, and code-quality guidance remain authoritative. Its prior "Safety Protocol Before Deleting Anything" and "User Override" sections are **superseded** by this contract. |
| `document-management.md` | Subordinate — its canonical document homes, naming conventions, SSOT/Issues structures, reference materials tier, and shared agent deposits tier remain authoritative. Its prior "Delete" lifecycle action is **superseded** by this contract. |
| `governance-entry.md` | Co-equal — defines what an agent does on first entry to an ungoverned directory; this contract defines what an agent does on every session start (governed or not). The two interlock via the Bootstrap Routine in §6 below. |

When this contract conflicts with an older clause in `repo-hygiene.md` or `document-management.md`, this contract wins. Update the older contracts to align in the same governance bump that adopts this one.

---

## 2. The Three Hard Rules

These are absolute. There is no scope-expansion override and no "user said I could" exception that survives a session boundary.

### Rule 1 — Agents Do Not Delete

No agent — under any prompt, persona, harness, or escalation — may run `rm`, `rm -rf`, `git clean`, `unlink`, `os.remove`, `shutil.rmtree`, `fs.unlink`, `Remove-Item`, or any equivalent destructive operation against any file or directory in any project, in any drive, at any depth.

This includes:
- Files the agent itself created
- Files that look stale, broken, empty, duplicated, or obsolete
- Files explicitly identified as cleanup targets in cleanup-trigger sections of other contracts
- Files in `.floyd/`, `SSOT/`, `Issues/`, or anywhere else inside a governed project
- Files outside `.git/` history (history rewrites are also forbidden — escalate to Douglas)
- Empty directories

The only exception is the contents of the agent's own ephemeral cache directories (e.g., `.pytest_cache/`, `__pycache__/`, `.ruff_cache/`) that the agent itself just created in the current session and is cleaning up before exit. Anything pre-existing is off-limits.

### Rule 2 — Removal Means Quarantine

When an agent determines that an item should leave active use, the agent **moves** it to the project's quarantine folder using the protocol in §3 below. The original item is preserved bit-for-bit; only its location changes. The original path is recorded so a future restore is mechanical.

### Rule 3 — Only Douglas Empties Quarantine

The quarantine folder is purged by Douglas alone, on his manual review. There is no TTL, no automatic sweep, no "old enough to remove" threshold. Items remain in quarantine indefinitely until Douglas decides their fate. The ControlBoard surfaces a persistent alert (§4) so the build-up is always visible.

---

## 3. Quarantine Protocol

### 3.1 Folder location

Per project, at:

```
<project-root>/.floyd/quarantine/
```

Inside that folder, items are organized by date of quarantine:

```
<project-root>/.floyd/quarantine/<YYYY-MM-DD>/
```

If multiple agents quarantine items on the same day, they share that day's folder. There is no per-agent or per-session subdirectory.

### 3.2 Item layout

For each quarantined item, two artifacts are created:

```
<project-root>/.floyd/quarantine/<YYYY-MM-DD>/<original-relative-path>
<project-root>/.floyd/quarantine/<YYYY-MM-DD>/<original-relative-path>.WHY.md
```

The `<original-relative-path>` preserves the path the item had under the project root. If the original was at `<project>/docs/old-architecture.md`, it lands at `<project>/.floyd/quarantine/<date>/docs/old-architecture.md`.

If the original was a directory, the entire directory tree moves under the quarantine date folder, preserving inner structure. A single `<original-relative-path>.WHY.md` at the top of the moved tree is sufficient — per-file WHY.md is not required for items quarantined as a unit.

### 3.3 The WHY.md schema

Every quarantine event MUST include a `WHY.md` companion file with this exact frontmatter and structure:

```markdown
---
quarantined_at: <ISO 8601 timestamp with timezone>
quarantined_by: <agent identifier — e.g., claude-opus-4-7@cc-session-NNN, or human:douglas>
original_path: <absolute path the item had before quarantine>
original_size_bytes: <integer>
reason_category: <one of: stale | duplicate | broken | superseded | secret-leak | cleanup-trigger | other>
session_link: <path to .floyd/agent_log.jsonl entry, or "n/a">
---

## Reason

<One to three sentences in plain English. Why was this item moved out of active use? What evidence supports the decision?>

## Restore command

```bash
mv "<full path within quarantine folder>" "<original_path>"
```

## Notes

<Optional. Any context Douglas should have when deciding whether to restore, archive, or purge.>
```

The `restore command` block is mandatory and must be a valid `mv` invocation that exactly reverses the quarantine move when run from the project root.

### 3.4 Quarantine append-only log

Each project's `.floyd/quarantine/` folder MUST contain a `LEDGER.jsonl` file. Every quarantine event appends one JSON line:

```json
{"ts": "<ISO 8601>", "agent": "<id>", "action": "quarantine", "from": "<original_path>", "to": "<quarantine_path>", "reason_category": "<category>", "size_bytes": <int>}
```

When Douglas purges, the purge action also appends:

```json
{"ts": "<ISO 8601>", "agent": "human:douglas", "action": "purge", "path": "<quarantine_path>", "size_bytes": <int>}
```

Restore actions append:

```json
{"ts": "<ISO 8601>", "agent": "<id>", "action": "restore", "from": "<quarantine_path>", "to": "<original_path>", "size_bytes": <int>}
```

Agents MUST NOT modify the LEDGER.jsonl other than to append. Existing lines are immutable.

### 3.5 Quarantine of governance-protected paths

If an agent ever finds itself wanting to quarantine something inside `.supercache/`, the answer is: **stop**. `.supercache/` is read-only at the agent layer. The correct action is to escalate to Douglas via an entry in `Issues/<PROJECT>_ISSUES.md` and let him handle it through the legacy-governance-assistant workflow. Quarantining `.supercache/` content is itself a violation.

---

## 4. ControlBoard Alert Requirement

The ControlBoard at `/Volumes/Storage/Legacy Agents/control-center/` (and any successor dashboard) MUST display a persistent alert whenever any project across the governed portfolio has at least one item in `.floyd/quarantine/`.

### 4.1 Alert content

The alert MUST surface, at minimum:

- A count of total quarantined items across all projects
- A breakdown by project (project name + count)
- The oldest quarantine date (so Douglas knows how long items have been waiting)
- A direct `file://` link or hot button per affected project that opens the quarantine folder

### 4.2 Alert visibility

- The alert MUST be visible on the Governance Dashboard (Page 1) without requiring a scroll
- It MUST persist (no auto-dismiss) until the ControlBoard's next refresh detects all `.floyd/quarantine/` folders empty
- It MUST be color-coded with both color and glyph (so it's accessible to colorblind users)

### 4.3 Implementation pointer

The dashboard's data refresh script reads `.floyd/quarantine/` directly from each project. No special API is needed — the file system is the source of truth. The script counts files (excluding `WHY.md` companions and `LEDGER.jsonl`) per quarantine date folder and aggregates.

---

## 5. Best Practices Execution Contract for Document Management

This section codifies the deterministic execution contract for document management work. It complements `document-management.md` (which defines canonical homes and naming conventions) by specifying the proof-of-work an agent owes when doing document-management tasks.

### 5.1 Required actions on every doc-management task

For every task that creates, modifies, archives, or quarantines documents:

1. **Identify the canonical location** in `document-management.md`'s "Canonical Document Homes" table. If the document type does not appear there, default to NOT creating it.
2. **Check for existing documents** that already serve the purpose. Edit the existing document instead of creating a parallel one whenever feasible.
3. **Apply naming conventions** from `document-management.md` exactly. No spaces. No emoji. No `TODO.md`/`NOTES.md`/`SCRATCH.md` at root.
4. **For supersession**, use the "Archive" pattern from `document-management.md` (move to `archive/` subfolder with date suffix), or quarantine if the older document has no archival value.
5. **Append a one-line entry to the project's SSOT change log** describing the doc-management action.

### 5.2 Forbidden patterns (document-side)

These are restated from `document-management.md` for emphasis under the new sanitation regime:

- `NOTES.md`, `TODO.md`, `SCRATCH.md`, `RANDOM.md`, `TEMP.md`, `TEST.md` at any project root
- Parallel versioned session logs (`session-1.md`, `session-2.md`, `session-final-2.md`)
- Multiple competing architecture documents (`ARCHITECTURE.md`, `DESIGN.md`, `ARCH-NEW.md`)
- Lorem-ipsum or placeholder content that was never replaced
- Binary files (PDF, DOCX, XLSX) committed without explicit need

When an agent encounters one of these in an existing project, the action is **quarantine** with `reason_category: cleanup-trigger`, not delete.

### 5.3 Evidence required per doc-management task

Per the project's overarching execution contract, every doc-management task MUST produce:

- File path of every document touched
- Action taken (created / updated / archived / quarantined)
- Justification per the canonical homes table
- For quarantine: link to the WHY.md and LEDGER.jsonl entry

---

## 6. Best Practices Execution Contract for Repository Sanitation

This section codifies the deterministic execution contract for repository sanitation work. It complements `repo-hygiene.md` (which defines `.gitignore` baselines, cleanup triggers, and code-quality limits) by specifying the proof-of-work an agent owes when doing sanitation tasks.

### 6.1 Required actions on every sanitation task

For every task that touches repository organization, cleanup, or git hygiene:

1. **Verify `.gitignore` against the language baseline** in `repo-hygiene.md`. If the baseline is missing entries, add them (this is creation, not deletion — allowed).
2. **Scan for forbidden-in-git categories**: secrets, build artifacts, OS/IDE artifacts, backups, large binary blobs without `.gitattributes`. Findings get **quarantined**, not deleted.
3. **Scan for cleanup triggers** (duplicate directories, empty placeholders, stale root-level junk, dead code per `repo-hygiene.md`). Findings get **quarantined**, not deleted.
4. **Apply project root tidiness rules**: ≤20 loose files at root, manifest files only at root, scripts in `scripts/`, etc.
5. **Apply soft size limits**: flag files >800 lines, directories >4 levels deep, functions >50 lines. Flag means open an issue in `Issues/<PROJECT>_ISSUES.md`, not auto-refactor.
6. **Append a one-line entry to the project's SSOT change log** describing the sanitation action and any quarantine activity.

### 6.2 Quarantine over deletion (rewrite of `repo-hygiene.md` § "Safety Protocol Before Deleting Anything")

The prior "Safety Protocol Before Deleting Anything" in `repo-hygiene.md` allowed deletion under a checklist. **That section is superseded by this contract.** The replacement protocol:

When a sanitation pass identifies a candidate for removal:

1. **Move it to quarantine** per §3 with appropriate `reason_category`
2. **Append a LEDGER entry**
3. **Open an Issue** in `Issues/<PROJECT>_ISSUES.md` describing the candidate and why quarantine was chosen, so Douglas has a discoverable trail
4. **Continue the task** — do not block on deletion approval; quarantine is the disposition

The agent never reaches a step where it asks "should I delete this?" Quarantine is the answer in 100% of cases.

### 6.3 Dead code and commented-out blocks (rewrite of `repo-hygiene.md` § "Dead Code and Commented-Out Blocks")

The prior "Default policy: delete" for dead code and commented-out blocks is **rescinded**. New policy:

- **Commented-out code blocks** larger than ~10 lines: extract the block into a quarantined file at `.floyd/quarantine/<date>/dead-code/<original-file>__<line-range>.snippet` with WHY.md, then remove the comment from the active source file. Git history still preserves the original commit; quarantine preserves the extracted snippet for easy review.
- **Unreferenced functions/classes/modules**: same treatment — extract to quarantine, remove from active source.
- **Load-bearing comments** that explain *why* code is the way it is: leave alone. The distinction in `repo-hygiene.md` § "Load-bearing comment" remains authoritative.

The agent's commit message references the quarantine path, not "deleted dead code".

### 6.4 Forbidden patterns (repo-side)

These are restated from `repo-hygiene.md` for emphasis under the new sanitation regime:

- Secrets and credentials in source (`.env` committed, API keys, private keys)
- Build artifacts in git (`node_modules/`, `target/`, `dist/`, `__pycache__/`)
- OS/IDE artifacts (`.DS_Store`, `Thumbs.db`, `*.swp`)
- Backup files (`*.bak`, `*.orig`, `*.rej`)
- Binary blobs without `.gitattributes` declaration

When an agent encounters one of these in an existing project, the action is **quarantine** with `reason_category` matching the violation.

### 6.5 Evidence required per sanitation task

Per the project's overarching execution contract, every sanitation task MUST produce:

- Files/directories touched
- `.gitignore` diff (if updated)
- Cleanup-trigger findings (if any) with full file paths
- Quarantine actions taken (if any) with WHY.md references and LEDGER.jsonl entries
- Link to the SSOT change log entry

---

## 7. Daily Bootstrap Routine (A → F, mandatory at every session start)

This routine is the entry point for every Claude or agent session that lands in a project directory, governed or not. It is referenced by `governance-entry.md` (which handles ungoverned-project bootstrap) and inherited by every governed project's `FLOYD.md` via the SSOT template's quarantine pointer section.

### A — Cleanup round
- Walk the project tree
- Apply §6.1 sanitation pass
- Quarantine cleanup-trigger findings per §3
- Append summary line to `.floyd/agent_log.jsonl`

### B — Documentation organization sweep
- Verify canonical document homes per `document-management.md`
- Verify the per-project governance file set: `FLOYD.md`, optional `CLAUDE.md`, `SSOT/<PROJECT>_SSOT.md`, `Issues/<PROJECT>_ISSUES.md`, `.floyd/agent_log.jsonl`
- Quarantine any anti-cruft violations per §5.2
- Reconcile FLOYD.md governance header drift: log to `Issues/`, do NOT auto-bump

### C — Repository organization sweep
- Verify `.gitignore` baseline per `repo-hygiene.md` for the project's language(s)
- Scan for forbidden-in-git categories per §6.4
- Apply project root tidiness rules per §6.1.4
- Quarantine violations per §3

### D — Code review at 100% confidence
- Run language-appropriate static analysis
- Read entrypoints, identify primary user journey paths in code
- Verify build/run commands actually succeed (exit codes + outputs captured)
- Every assertion gets a file:line citation
- Open Issues for any finding that warrants follow-up; do NOT auto-fix

### E — Update `repository_report.json`
- Per `repository-report-spec.md`, fill or refresh every field with evidence citation
- Update `gate_statuses` for the 7 Beta Release Readiness gates
- Update `last_bootstrap` to the current timestamp
- Run the 3-round critic check

### F — Verify and sign
- Round-3 critic check yields zero corrections
- Append signed entry to `.floyd/agent_log.jsonl` with timestamp + agent identity
- If any quarantine activity occurred this session, the entry includes a count + LEDGER pointer

The routine MUST complete before any implementation work in the session. If the routine is interrupted, the session boundary is the interruption point and the next session starts from A.

---

## 8. Cross-cutting Sections

### 8.1 Secret hygiene (escalates above quarantine)

If an agent discovers a real secret or credential in committed source code or git history, the secret hygiene response is **NOT quarantine**. The escalation path:

1. **Stop** — do not move the file, do not touch git history
2. **Notify Douglas** immediately via an Issue in `Issues/<PROJECT>_ISSUES.md` with severity = SECURITY
3. **Recommend rotation** of any exposed credentials
4. **Wait for Douglas's call** on whether to rotate and rewrite history (this requires `git filter-repo` or similar — agent doesn't run that without explicit Douglas authorization)

Quarantining the file would not remove the secret from git history. The hygiene response is escalation, not quarantine.

### 8.2 User override (rewrite of `repo-hygiene.md` § "User Override")

The prior `repo-hygiene.md` "User Override" section allowed Douglas to grant temporary deletion autonomy ("authorized to delete anything you think is stale"). Under v1.6.0, **even an explicit user override does not authorize agent deletion**. If Douglas wants something deleted, Douglas deletes it himself. The override remains valid for *scope* (what to clean) but never for *operation* (deletion vs quarantine — quarantine is always the operation).

### 8.3 Cleanup triggers retain their categorization, not their disposition

`repo-hygiene.md` § "Cleanup Triggers" enumerates duplicate directories, empty placeholders, stale root-level junk, etc. Those categorizations remain useful and authoritative. What changes under v1.6.0 is the disposition: every trigger that previously could end in deletion now ends in quarantine.

---

## 9. Mandatory execution contract

For EACH requested item:
1) Show exact action taken
2) Show direct evidence (file/line/command/output)
3) Show verification result
4) Mark status only after proof

## Forbidden behaviors
- Declaring "done" without evidence
- Collapsing multiple requested items into one vague summary
- Skipping failed steps without explicit blocker report
- Running any deletion command — no exceptions

## Required output structure
A) Requested items checklist
B) Per-item evidence ledger
C) Verification receipts
D) Completeness matrix (item -> done/blocked -> evidence)
E) Quarantine ledger summary (count of items quarantined this session, paths, WHY.md references) — REQUIRED whenever any quarantine activity occurred

## Hard gate
If any requested item has no evidence row, final status MUST be INCOMPLETE.
If any agent ran a deletion command, final status MUST be VIOLATION and the session MUST escalate to Douglas before continuing.
