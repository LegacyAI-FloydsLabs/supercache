# Skills Library Index

Skills are harness-agnostic capability definitions. They tell agents HOW to do specific tasks.

## Available Skills

### Claude Code Skills (349+ via ECC)
**Location:** `/Volumes/Storage/skillsdump/`
**GitHub:** `CaptainPhantasy/skillsdump`
**Includes:** coding-standards, tdd-workflow, security-review, deployment-patterns, api-design, and 340+ more.

### Floyd Skills
**Location:** `/Volumes/Storage/FLOYD_CLI/` (various subdirectories)
**GitHub:** `CaptainPhantasy/FloydSkills`

### PEBKAC Skills (Agent Defense Stack)
**Location:** `/Volumes/Storage/PEBKAC/`
**GitHub:** `CaptainPhantasy/PEBKAC`
**Purpose:** 5-layer agent defense stack (L0-L4) for evidence-based execution.

## How Agents Use Skills

1. Agent reads this INDEX to discover what skills exist
2. Agent loads the specific skill file it needs for the current task
3. Skills are consumed at runtime — they are NOT pre-loaded into context
4. Project-level FLOYD.md MAY specify required skills for that project


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
