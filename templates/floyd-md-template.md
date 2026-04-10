# {{PROJECT_NAME}} — FLOYD.md
**Version:** {{VERSION}}
**Initialized:** {{DATE}}
**Governance:** .supercache/ v{{VERSION}}

> **Compliance Notice:** This file must match the template at `.supercache/templates/floyd-md-template.md`. If you are an agent reading this file and it is missing sections from the template, edit this file to add them. Preserve all project-specific content in the "Project-Specific Context" section below. The template is the spec. This file is the implementation. Make them match.

---

## Agent Contract

You are working on **{{PROJECT_NAME}}**, a Legacy AI project.

### Before You Start
1. Read this file completely.
2. Read `.supercache/READONLY` — you MUST NOT write to .supercache/.
3. Check `SSOT/README.md` for current project state.
4. Check `Issues/README.md` for open issues.
5. Read `.supercache/manifests/port-allocation-policy.yaml` — NEVER use port 3000, 5000, 8000, 8080, or any other forbidden port. Claim a port in `/Volumes/SanDisk1Tb/SSOT/port-registry.json` before binding.

### Governance Location
```
.supercache/ → {{SUPERCACHE_PATH}}
```

This directory contains global templates, contracts, manifests, and routing config. It is **READ-ONLY**. Do not create, modify, or delete any file there.

### Where You Write
- `SSOT/` — project status, decisions, findings
- `Issues/` — bugs, blockers, tasks
- `.floyd/` — agent working state, session logs, runtime cache
- Project source files — your actual work

### Execution Contract
Before claiming any task complete, provide:
1. Exact action taken
2. Direct evidence (file/line/command/output)
3. Verification result
4. Status only after proof

See `.supercache/contracts/execution-contract.md` for full details.

### Model Routing
See `.supercache/manifests/model-routing.yaml` for which LLM to use for which task type.

### Available Services
See `.supercache/manifests/resource-manifest.yaml` for all available infrastructure.

### Port Allocation
Ports 3000, 5000, 8000, 8080, and all others in `.supercache/manifests/port-allocation-policy.yaml` are forbidden. Use only ports from the available range (10000-65535). Claim your port in `/Volumes/SanDisk1Tb/SSOT/port-registry.json` before binding. Verify with `lsof -i :<port>`. If this project is on a forbidden port, change it now.

---

## Project-Specific Context

<!-- Add project-specific information below this line -->
<!-- This section is the ONLY part of FLOYD.md that should be customized per project -->

**Purpose:**

**Tech Stack:**

**Key Files:**

**Current Phase:**


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
