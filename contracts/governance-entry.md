# Governance Entry Contract
**Version:** 1.7.2
**Governance:** .supercache/ v1.7.2
**Type:** Mandatory — read on first entry to any directory
**Applies to:** All agents, all models, all harnesses

> This contract triggers when an agent enters a directory that is either ungoverned (no `.floyd/.supercache_version`) or has an incomplete repository report (no `SSOT/repository_report.json`, or report has UNVERIFIED fields). The protocol below is non-optional. Violation is a governance failure.

---

## Entry Detection Protocol

When you first enter a project directory, run these checks immediately — before any code changes:

```bash
# Check 1: Governance stamp
if [ -f ".floyd/.supercache_version" ]; then
    echo "GOVERNED: $(cat .floyd/.supercache_version)"
else
    echo "UNGOVERNED — ENTRY PROTOCOL TRIGGERED"
fi

# Check 2: Repository report
if [ -f "SSOT/repository_report.json" ]; then
    python3 -c "import json; r=json.load(open('SSOT/repository_report.json')); unverified=[k for k,v in r.items() if 'UNVERIFIED' in str(v)]; print(f'VERIFIED' if not unverified else f'UNVERIFIED FIELDS: {unverified}')" 2>/dev/null || echo "REPORT PARSE ERROR"
else
    echo "NO REPORT — ENTRY PROTOCOL TRIGGERED"
fi
```

**If either check triggers:** You are in ENTRY PROTOCOL. You must complete the bootstrap sequence below before any implementation work. No exceptions.

**If both checks pass:** The project is governed. Proceed to the project's `FLOYD.md` for instructions.

---

## Bootstrap Sequence (Mandatory — Do Not Skip Steps)

### Step 1: Read Governance Layer

Before touching anything in this directory, read these files in order:

1. `/Volumes/SanDisk1Tb/.supercache/contracts/governance-entry.md` (this file)
2. `/Volumes/SanDisk1Tb/.supercache/contracts/rules.md` — **MECHANICALLY ENFORCED execution contract**. Every rule herein is enforced, not suggested.
3. `/Volumes/SanDisk1Tb/.supercache/contracts/repository-report-spec.md`
4. `/Volumes/SanDisk1Tb/.supercache/contracts/agent-contract.md`
5. `/Volumes/SanDisk1Tb/.supercache/templates/floyd-md-template.md`
6. `/Volumes/SanDisk1Tb/.supercache/templates/ssot-template.md`
7. `/Volumes/SanDisk1Tb/.supercache/templates/repository-report-template.md`

### Step 2: Create Required Directory Structure and Deploy Contracts

```bash
mkdir -p .floyd SSOT Issues
```

Deploy mechanically enforced contracts into `.floyd/`:

```bash
cp /Volumes/SanDisk1Tb/.supercache/contracts/rules.md .floyd/rules.md
cp /Volumes/SanDisk1Tb/.supercache/templates/repository-report-template.md .floyd/repository_report_template.md
```

These files are checked at `--verify`. If either is missing, the project is non-compliant.
Do NOT create source code directories. Bootstrap is assessment, not implementation.

### Step 3: Create FLOYD.md from Template

Read `.supercache/templates/floyd-md-template.md`. Create `FLOYD.md` at the project root by copying the template and filling in every field that can be determined from the existing directory contents.

**Fields you MUST fill from evidence:**
- Project name (from directory name)
- Primary language (from existing files: `package.json` → JavaScript/TypeScript, `go.mod` → Go, `pyproject.toml` → Python, etc.)
- Repository (run `git remote -v` if `.git/` exists)

**Fields you mark `<!-- TODO -->`:**
- Any field you cannot determine from existing files. Do not guess.

### Step 4: Create SSOT from Template

Read `.supercache/templates/ssot-template.md`. Create `SSOT/{ProjectName}_SSOT.md` by copying the template and filling in the SanDisk1Tb Top-Level Inventory section if this project is on SanDisk1Tb.

### Step 5: Fill Repository Report (MECHANICALLY ENFORCED — NO IMPLEMENTATION UNTIL VERIFIED)

**This step is not optional.** If `SSOT/repository_report.json` does not exist or has `_verified: false`, you MUST NOT proceed to any implementation work. This is mechanically enforced by the pi extension `governance-enforcement.ts` (blocks Write/Edit to source files and git commit) and repo-report enforcement hooks.

Read `/Volumes/SanDisk1Tb/.supercache/contracts/repository-report-spec.md` completely. Then read `.floyd/repository_report_template.md` for the schema.

**Fill `SSOT/repository_report.json`** with all 12 fields. Every field MUST have a corresponding evidence citation in the `_evidence` companion object. No field may be guessed, estimated, or assumed.

**Critic-Check Rounds (minimum 3):**

After filling the report:
1. **Round 1 — Self-Critic:** Re-read every field. For each, ask: "Would this value survive adversarial cross-examination?" Fix any field that wouldn't.
2. **Round 2 — Code Evidence Audit:** For each field, trace the evidence citation back to the actual file/line. Does the evidence truly support the value? Fix discrepancies.
3. **Round 3 — Fresh Eyes:** Read the report as if you've never seen this project before. Does every value make sense independently? Are any values suspiciously round, generic, or template-like? Fix them.

Each round produces a diff of corrections. The final report must show zero corrections in the third round.

**Report Acceptance Criteria:**
- All 12 fields have non-placeholder values
- `_evidence` object has a citation for every field (file:line or command+output)
- `_verified` is `true`
- `_critic_rounds` is ≥ 3
- `_last_verified` is the current timestamp

### Step 7: Stamp Governance

Only after the repository report passes all critic-check rounds:

```bash
cat /Volumes/SanDisk1Tb/.supercache/VERSION > .floyd/.supercache_version
```

This stamps the project at the canonical governance version. The stamp is your assertion that Steps 1-6 were completed and verified.

### Step 8: Signal Dashboard Update

```bash
touch .floyd/.bootstrap_complete
```

The dashboard refresh script detects this file and updates the project's status.

---

## What You MUST NOT Do During Bootstrap

| Forbidden Action | Reason |
|---|---|
| Create, modify, or delete source code | Bootstrap is assessment, not implementation |
| Write to `.supercache/` | Read-only governance layer |
| Skip the critic-check rounds | Unverified reports poison downstream decisions |
| Guess field values | Every value must have evidence citation |
| Proceed to implementation before Step 7 | Ungoverned projects are unsafe to modify |
| Delete existing files | Even if they appear broken — assessment only |
| Commit or push | Bootstrap is local until Douglas approves |

---

## After Bootstrap — What Changes

Once `.floyd/.supercache_version` exists and `SSOT/repository_report.json` is verified:

1. The project is **governed**. Agents entering this directory read `FLOYD.md` (not this entry contract).
2. The **HTML dashboard** reflects the new governed status.
3. If `completion_percentage` < 100, the project is eligible for **finisher swarm dispatch** from the dashboard.
4. All future agent sessions reference `FLOYD.md` as canonical spec — but `repository_report.json` must be re-verified if significant code changes occur.

---

## Drift Detection (Per-Session)

Every governed project's `FLOYD.md` should mandate a quick drift check at session start:

```bash
STAMP_VER=$(cat .floyd/.supercache_version 2>/dev/null)
CANON_VER=$(cat /Volumes/SanDisk1Tb/.supercache/VERSION 2>/dev/null)
if [ "$STAMP_VER" != "$CANON_VER" ]; then
    echo "DRIFT: stamp=$STAMP_VER canonical=$CANON_VER — run governance-bump.sh"
fi
```

If drifted, the agent must flag it before any implementation work.

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
