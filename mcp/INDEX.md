# MCP Server Library Index

MCP servers are lazy-loaded globally. Agents discover what's available here.
Project-level FLOYD.md declares which MCPs that project actually needs.

## Active MCP Servers

### Floyd Ecosystem (installed at /Volumes/Storage/MCP/)

| Server | Tools | Purpose |
|---|---|---|
| floyd-supercache | 12 | 3-tier cache (project/reasoning/vault). Per-project via --data-dir. |
| floyd-patch | 5 | Surgical code editing with safety validation |
| floyd-runner | 6 | Project detection, build, test, lint, format |
| floyd-safe-ops | 3 | Impact simulation, safe refactoring, verification |
| floyd-devtools | 11 | Schema migration, dependency analysis, test generation |
| floyd-terminal | 8 | Process management, code execution, file operations |
| floyd-lab | 5 | Sandboxed execution environments |

### Floyd CLI (installed at /Volumes/Storage/FLOYD_CLI/INK/)

| Server | Tools | Purpose |
|---|---|---|
| floyd-git | 8 | Git operations with safety checks |
| floyd-browser | 9 | Browser automation |

### Third-Party (via Claude Code MCP integrations)

| Server | Purpose |
|---|---|
| claude-in-chrome | Browser automation in Chrome |
| context7 | Library documentation lookup |
| Supabase | Database management |
| Vercel | Deployment management |
| Gmail | Email access |
| Google Calendar | Calendar management |
| HuggingFace | Model and dataset management |

## How Agents Use MCPs

1. Agent reads this INDEX to discover what servers exist
2. Project FLOYD.md declares which MCPs that project needs
3. MCPs are lazy-loaded — only initialized when actually called
4. Global MCPs provide awareness; project MCPs provide access


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
