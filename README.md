# .supercache/ — Legacy AI Governance System

**Version:** 1.7.2
**Owner:** Douglas Talley / Legacy AI
**Repository:** github.com/LegacyAI-FloydsLabs/supercache

---

## First Five Minutes

You are looking at the governance layer for the entire Legacy AI development environment. This directory is the single source of truth for how projects are structured, how agents behave, what services exist, and what rules apply.

## Agent Model

Legacy AI governance uses one canonical per-project spec.

| Runtime | Project file it reads |
|---------|-----------------------|
| Floyd-governed harnesses | `FLOYD.md` (canonical, always required) |

Models run through the governed harness and inherit Floyd's contract. They read `FLOYD.md` only.

**`FLOYD.md` is the canonical project spec.** It owns project identity, stack, ports, build commands, environment variables, and project-specific hard rules. Every project must have one. It matches `templates/floyd-md-template.md`.

### If you are an AI agent (Floyd or any harness-routed model):
1. Read `READONLY` — understand you MUST NOT write to this directory
2. Read the project's `FLOYD.md` — it points here and has project-specific context
3. Read `contracts/execution-contract.md` — this is how you prove your work
4. Read `manifests/model-routing.yaml` — this tells you which LLM to use for what
5. Read `manifests/resource-manifest.yaml` — this tells you what infrastructure exists
6. Read `manifests/port-allocation-policy.yaml` — NEVER bind to port 3000 or any other forbidden port. Claim a port in `/Volumes/SanDisk1Tb/SSOT/port-registry.json` before binding.
7. Read `templates/floyd-md-template.md` — this is the authoritative spec for every project's FLOYD.md. If the project's FLOYD.md does not match this template, you are responsible for editing it into compliance. Preserve project-specific content. Add any missing sections from the template. The template is the spec. The project's FLOYD.md is the implementation. Make them match.


### If you are Douglas:
1. To initialize a new project: `./bootstrap.sh --init /path/to/project`
2. To check compliance: `./bootstrap.sh --verify /path/to/project`
3. To scan all drives: `./bootstrap.sh --health`
4. To repair a project: `./bootstrap.sh --repair /path/to/project`
5. To archive a project: `./bootstrap.sh --archive /path/to/project`

### If you are a new team member:
1. Read this file
2. Read `manifests/service-catalog.yaml` for what we pay for
3. Read `manifests/resource-manifest.yaml` for what infrastructure exists
4. Run `./bootstrap.sh --health` to see the state of all projects
5. Pick a project, read its `FLOYD.md`, and start contributing

---

## Directory Structure

```
.supercache/
├── READONLY              # Sentinel: agents must not write here
├── VERSION               # Semantic version of this governance system
├── bootstrap.sh          # Project initialization and compliance tool
├── README.md             # This file
├── manifests/
│   ├── resource-manifest.yaml    # All infrastructure and services
│   ├── cross-drive-registry.yaml # What's on which drive
│   ├── service-catalog.yaml      # Subscriptions and costs
│   ├── port-allocation-policy.yaml # Forbidden and allocated ports
│   └── model-routing.yaml        # LLM selection rules
├── templates/
│   ├── floyd-md-template.md            # Project FLOYD.md skeleton (canonical, required)
│   ├── ssot-template.md                # Project SSOT with Verification Sweep Protocol
│   ├── issues-template.md              # Project issues ledger with lifecycle + change log
│   ├── repo-migration-plan-template.md # Three-document migration plan template
│   └── agent-log-template.md           # Agent log format spec
├── contracts/
│   ├── agent-contract.md               # Global agent contract (Before You Start, drive topology, identity rules)
│   ├── execution-contract.md           # Evidence + verification gates for all agents
│   ├── repo-structure.md               # Canonical layouts per language + migration workflow
│   ├── git-discipline.md               # Pre-commit checklist, commit standards, secret hygiene, reputation
│   ├── document-management.md          # Anti-Cruft Rule, document homes, SSOT sweep, reference tier
│   └── repo-hygiene.md                 # .gitignore baselines, cleanup triggers, tidiness standards
├── hooks/
│   ├── pre-commit.sh                     # Blocks commits TO .supercache/ from other projects
│   ├── supercache-repo-precommit.sh      # Version-drift check for the governance repo itself
│   ├── session-end.sh                    # Handoff block reminder
│   ├── floyd-state-pause.sh              # Session state capture
│   ├── critic-runner.sh                  # Governance compliance sweep across drives
│   ├── log-rotate.sh                     # Nightly log compression
│   └── state-monitor.sh                  # Orphaned session state detection
├── skills/
│   └── INDEX.md                  # Skills library catalog
└── mcp/
    └── INDEX.md                  # MCP server catalog
```

## Write Policy

**.supercache/ is READ-ONLY for all agents and automations.**

The sole write path: Douglas → GitHub PR → merge → git pull to this directory.

Agents write to project-level directories only:
- Project `.floyd/` — working state, session logs, runtime cache
- Project `SSOT/` — project status and decisions
- Project `Issues/` — bugs and tasks
- Firestore — cross-device session state
- BigQuery — append-only analytics

## Contract Enforcement

The mandatory execution contract is the final section of every instructional document and prompt in this environment. There is nothing after the contract. No instructions, no footnotes, no references. The contract is the last word.


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
