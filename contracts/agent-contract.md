# Agent Contract
**Version:** 1.0.0
**Governance:** .supercache/ v1.0.0
**Owner:** Douglas Talley / Legacy AI

This contract governs every AI agent operating under Legacy AI governance.
It is READ-ONLY. The sole write path: Douglas Talley → GitHub PR → merge → git pull.

---

## Before You Start

Complete every step below before making any change to any file. No exceptions.

1. Read the project's `FLOYD.md` completely. Do not skim. Every section constrains your behavior.
2. Read this file completely. You are reading it now. Do not stop.
3. Read `.supercache/READONLY` — you MUST NOT write to `.supercache/`. Violation corrupts the governance layer for all agents and projects.
4. Read `SSOT/README.md` in the project directory for current project state.
5. Read `Issues/README.md` in the project directory for open issues.
6. Read `.supercache/manifests/port-allocation-policy.yaml` — NEVER bind to port 3000 or any other forbidden port. The project's `FLOYD.md` states which port is claimed. If the project is on a forbidden port, change it now.
7. Read `.supercache/contracts/execution-contract.md` — this defines how you prove your work. You will be held to it.
8. Read `.supercache/manifests/model-routing.yaml` — this tells you which LLM to use for which task type.

---

## Governance Location

```
.supercache/ → /Volumes/SanDisk1Tb/.supercache
```

This directory contains global templates, contracts, manifests, and routing config.
It is **READ-ONLY**. Do not create, modify, or delete any file there.

The sole write path: Douglas Talley → GitHub PR → merge → git pull to this directory.

---

## Where You Write

| Location             | Purpose                                          | Example                                                |
|----------------------|--------------------------------------------------|--------------------------------------------------------|
| `SSOT/`              | Project status, decisions, findings              | `SSOT/README.md`, `SSOT/decision-log.md`               |
| `Issues/`            | Bugs, blockers, tasks                            | `Issues/README.md`, `Issues/001-description.md`        |
| `.floyd/`            | Agent working state, session logs, runtime cache | `.floyd/agent_log.jsonl`                               |
| Project source files | Your actual work                                 | Any file in the project tree not in the exclusion list |

---

## Where You Do NOT Write

| Location                                                                   | Reason                                                                        |
|----------------------------------------------------------------------------|-------------------------------------------------------------------------------|
| `.supercache/` (any file, any subdirectory)                                | Global governance — READ-ONLY for all agents, hooks, and automations          |
| Any path listed in the project's `FLOYD.md` "Where You Do NOT Write" table | Project-specific exclusions — the project owner has declared these off-limits |

If you write to `.supercache/`, you have corrupted the governance layer. There is no undo. There is no forgiveness.

---

## Port Rules

The following ports are **FORBIDDEN**. You may never bind to them, configure them, or default to them:

|   Port | Why forbidden                                                |
|--------|--------------------------------------------------------------|
|   3000 | Next.js, Express, Vite, CRA — the #1 collision port globally |
|   3001 | Next.js alt, Storybook                                       |
|   3002 | Next.js alt                                                  |
|   4000 | GraphQL, Firebase                                            |
|   4200 | Angular CLI                                                  |
|   5000 | Flask, macOS AirPlay                                         |
|   5173 | Vite                                                         |
|   5174 | Vite alt                                                     |
|   5500 | VS Code Live Server                                          |
|   8000 | Django, FastAPI                                              |
|   8080 | Tomcat, Spring Boot, nginx                                   |
|   8081 | Spring Boot alt                                              |
|   8443 | HTTPS alt                                                    |
|   8888 | Jupyter                                                      |
|   9000 | PHP-FPM, SonarQube                                           |
|   9090 | Prometheus                                                   |

**Available range:** 10000–65535

**Before binding a port:**
1. Read `/Volumes/SanDisk1Tb/SSOT/port-registry.json` — check if your port is already claimed.
2. Claim your port using `/Volumes/SanDisk1Tb/SSOT/port-claim.sh claim <port> <project> <drive>`.
3. Verify with `lsof -i :<port>` — if something else is bound, investigate before killing.
4. Record the claimed port in the project's `FLOYD.md` Port Allocation table.

**If the project is on a forbidden port:**
- Change the port in the code immediately.
- Update `FLOYD.md` with the new port.
- Claim the new port in `port-registry.json`.

**You may only kill your own specifically claimed port per project.** No mass port kills without Douglas Talley's explicit order.

---

## Model Routing

| Tier           | Provider                      | Use for                                                                                    |
|----------------|-------------------------------|--------------------------------------------------------------------------------------------|
| Reasoning      | Anthropic Claude Opus         | Architecture, planning, complex debugging, code review, multi-file refactoring, governance |
| Implementation | Z.ai / MiniMax                | Coding, bulk code generation, test writing, documentation                                  |
| Quick          | Google Gemini                 | Simple lookups, formatting, quick questions, light code generation                         |
| Free           | HuggingFace (via Novita/Groq) | Experimentation, non-critical tasks, model testing                                         |

**Routing rules:**
- If the task requires understanding multiple files or architectural decisions → **reasoning tier**.
- If the task is writing code to a known spec → **implementation tier**.
- If the task is a quick lookup or simple formatting → **quick tier**.
- If the task is experimental or non-critical → **free tier**.
- When in doubt, start with reasoning tier to plan, then hand off to implementation tier.

---

## FLOYD.md Compliance

Every project has a `FLOYD.md` at its root. That file must match the template at `.supercache/templates/floyd-md-template.md`.

**If the project's FLOYD.md does not match the template:**
- You are responsible for editing it into compliance.
- Preserve all project-specific content.
- Add any missing sections from the template.
- The template is the spec. The project's FLOYD.md is the implementation. Make them match.

**If the project has no FLOYD.md:**
- Do not create one manually. Run `bootstrap.sh --init /path/to/project`.
- If `bootstrap.sh` is unavailable, report the blocker. Do not improvise.

---

## Execution Contract

Before claiming any task complete, provide:

1. **Exact action taken** — what you did, specifically.
2. **Direct evidence** — file path + line, command + output, diff, or screenshot.
3. **Verification result** — build pass, test pass, linter clean, or equivalent.
4. **Status** — mark COMPLETE only after steps 1-3 are proven.

See `.supercache/contracts/execution-contract.md` for the full contract including the completeness matrix format.

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
- Writing to .supercache/ (this file is READ-ONLY governance)

## Required output structure
A) Requested items checklist
B) Per-item evidence ledger
C) Verification receipts
D) Completeness matrix (item -> done/blocked -> evidence)

## Hard gate
If any requested item has no evidence row, final status MUST be INCOMPLETE.
