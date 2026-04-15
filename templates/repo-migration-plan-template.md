# Repository Migration Plan Template
**Governance:** .supercache/ v{{VERSION}}
**Spec:** `contracts/repo-structure.md` (Migration Workflow section)

This template generates the **three documents** required by the migration workflow in `contracts/repo-structure.md`:

1. **Analysis Report** — current state, target state, problems, risks, rollback
2. **Step-by-Step Migration Plan** — 10-20 atomic, reversible steps
3. **LLM Executor Instructions** — how another agent can execute the plan in a fresh session

All three documents go in `SSOT/migration-plans/<DATE>-<BRIEF_DESCRIPTION>/` in the target project.

---

## DOCUMENT 1: ANALYSIS REPORT

Filename: `01-analysis-report.md`

```markdown
# Repository Structure Analysis — {{PROJECT_NAME}}
**Date:** YYYY-MM-DD
**Prepared by:** <agent or human name>

## Current State

**Language/Framework Detected**: <!-- e.g., Node.js + TypeScript, Rust + Cargo, Python 3.12 -->
**Primary Issue**: <!-- e.g., Entire application nested in starter-app/ folder -->

### Current Structure

```
<paste actual directory tree>
```

### Problems Identified

1. <!-- Specific problem with impact, tying to one of the four anti-patterns in contracts/repo-structure.md -->
2. <!-- ... -->
3. <!-- ... -->

## Target State

### Best Practice Structure for <language>

```
<paste target directory tree, per contracts/repo-structure.md canonical layout>
```

### Why This Structure

- <!-- Reason 1: convention, tooling support, discoverability, etc. -->
- <!-- Reason 2 -->
- <!-- Reason 3 -->

## Impact Analysis

- **Files That Will Move**: <count>
- **Import Statements to Update**: <count or "TBD after detailed scan">
- **Config Files to Update**: <list of config files that reference paths>
- **CI/CD Files to Update**: <list of workflow/pipeline files>
- **Estimated Complexity**: <Low / Medium / High>
- **Estimated Steps**: <10-20>

## Risk Assessment

### High Risk Areas

- <!-- e.g., Build scripts reference absolute paths that will break -->
- <!-- e.g., Hardcoded import paths in tests -->

### Mitigation

- <!-- Strategy for each risk -->

### Rollback Strategy

- <!-- How to undo the migration if something breaks mid-execution -->
- <!-- The minimum viable rollback is: git checkout main && git branch -D <migration-branch> -->
```

---

## DOCUMENT 2: STEP-BY-STEP MIGRATION PLAN

Filename: `02-migration-plan.md`

```markdown
# Migration Plan: <brief description>
**Date:** YYYY-MM-DD
**Related:** 01-analysis-report.md

## Prerequisites

- [ ] Create a new branch: `git checkout -b restructure-<date>`
- [ ] Ensure all changes are committed OR explicitly stashed
- [ ] Run existing tests to establish baseline: `<test command>`
- [ ] Record baseline pass/fail state in the Verification Log at the bottom of this file

---

## Step 1: <action name>

**Objective**: <!-- What this step accomplishes in one line -->

**Commands**:
\`\`\`bash
<exact commands to run, one per line>
\`\`\`

**Files Affected**:
- <!-- List every file touched -->

**Validation**:
- [ ] <!-- How to confirm this step succeeded; specific command + expected result -->

**Rollback** (if needed):
\`\`\`bash
<exact commands to undo this step>
\`\`\`

---

## Step 2: <action name>

<!-- Repeat the structure above -->

---

<!-- Continue for all steps. Keep each step atomic, testable, reversible. -->
<!-- Typical plan has 10-20 steps. -->

---

## Final Validation

- [ ] All tests pass: `<test command>`
- [ ] Application builds: `<build command>`
- [ ] Application runs: `<run command>`
- [ ] No broken imports: `<linter/type-check command>`
- [ ] CI/CD pipeline passes (if applicable)

## Completion

Once all validations pass:

\`\`\`bash
git add -A
git commit -m "refactor: restructure repository per canonical layout"
git push origin restructure-<date>
\`\`\`

Create a pull request for human review. Do not merge without approval.

## Verification Log

- YYYY-MM-DD HH:MM TZ — Baseline captured: <result>
- YYYY-MM-DD HH:MM TZ — Step 1 completed, validation passed
- <!-- Append as each step completes -->
```

---

## DOCUMENT 3: LLM EXECUTOR INSTRUCTIONS

Filename: `03-executor-instructions.md`

```markdown
# LLM Executor Instructions: Repository Restructuring for {{PROJECT_NAME}}
**Date:** YYYY-MM-DD
**Related:** 01-analysis-report.md, 02-migration-plan.md

## Overview

You are executing a pre-planned repository restructuring. Each step has been verified for safety and accuracy. **Follow the plan exactly — do not improvise, do not skip steps, do not batch steps together.**

## Your Role

- Execute steps in order
- Validate after EACH step
- Report any errors immediately and **STOP**
- Do NOT proceed if validation fails on any step
- Do NOT attempt to fix failing validation yourself — escalate to the user

## How to Use This Plan

### For Each Step:

1. **Read the entire step** before executing anything
2. **Execute the commands exactly** as written (case-sensitive file paths)
3. **Check the validation criteria** — run the validation command
4. **If validation passes**: proceed to the next step
5. **If validation fails**: **STOP** and report:
   - Which step failed
   - What the validation expected
   - What actually happened (full command output)
   - Do NOT attempt to fix it yourself

### Important Notes

- File paths are **case-sensitive**
- Use `git mv` instead of `mv` to preserve git history (per contracts/repo-structure.md)
- If a command fails, use the **Rollback** instructions for that step
- Test after every 3-5 steps to catch issues early
- Every completed step must be recorded in the Verification Log at the bottom of `02-migration-plan.md`

### Step Execution Template

Use this format when recording each step's execution in the verification log:

\`\`\`
STEP N: <name>
Status: [X] Complete / [ ] Failed / [ ] Skipped

Commands executed:
<paste commands here>

Validation result:
<paste validation output here>

Notes:
<any observations or issues>
\`\`\`

## Stop Conditions

You MUST stop and report immediately if any of these occur:

- A step's commands fail with a non-zero exit code
- A validation check fails
- A file path in the plan does not exist in the current repo state
- You encounter files not mentioned in 01-analysis-report.md that look related
- The git working tree becomes unclean in an unexpected way
- Any command would require force-push or --no-verify to proceed

## Steps Begin Below

Reference Step 1 from `02-migration-plan.md` and proceed sequentially.
```

---

## How to Use This Template

1. Copy this template file into the target project at `SSOT/migration-plans/<DATE>-<BRIEF_DESCRIPTION>/`
2. Split the three document sections into three separate files: `01-analysis-report.md`, `02-migration-plan.md`, `03-executor-instructions.md`
3. Fill in each section based on actual reconnaissance of the target repo
4. Triple-check accuracy, completeness, safety, clarity, and reversibility before presenting to the user
5. Get user approval before any execution begins
6. Execute via `03-executor-instructions.md` (by yourself in a fresh session or by another agent)

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
