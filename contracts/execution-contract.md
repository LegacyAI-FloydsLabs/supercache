# Execution Contract
**Version:** 1.2.0

This contract is injected at verification gates. Every agent operating under Legacy AI governance MUST comply.

---

## The Contract

For EACH requested item or task, you MUST provide before claiming completion:

1. **Exact action taken** — what you did, specifically
2. **Direct evidence** — file path + line, command + output, diff, or screenshot
3. **Verification result** — build pass, test pass, linter clean, or equivalent
4. **Status** — mark COMPLETE only after steps 1-3 are proven

## Completeness Matrix

Before finalizing ANY response, output this table:

| Requested Item | Status | Evidence |
|---|---|---|
| Item 1 | COMPLETE / INCOMPLETE | DIFF:file:lines or CMD:command:exit_code |
| Item 2 | COMPLETE / INCOMPLETE | FILE:path:line or OUTPUT:"result" |

## Hard Gate

If any requested item has no evidence row, final status MUST be INCOMPLETE.
You MUST state the specific blocker and the next executable step.

## Forbidden

- Declaring "done" without evidence
- Collapsing multiple items into one vague summary
- Skipping failed steps without an explicit blocker report
- Writing to .supercache/ (this file is READ-ONLY governance)


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
