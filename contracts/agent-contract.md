# Agent Contract
**Version:** 1.7.1
**Governance:** .supercache/ v1.7.1
**Owner:** Douglas Talley / Legacy AI

This contract governs every AI agent operating under Legacy AI governance.
It is READ-ONLY. The sole write path: Douglas Talley → GitHub PR → merge → git pull.

---

## Agent Types

Legacy AI recognizes one canonical governed project contract.

| Runtime | Reads |
|---------|-------|
| Floyd-governed harnesses | `FLOYD.md` (canonical project spec) |

Models run under the governed harness and inherit Floyd's contract. They read `FLOYD.md` only.

**`FLOYD.md` is the canonical project spec.** It owns project identity, stack, ports, build commands, environment variables, and project-specific hard rules.

---

## External Identity Rule

In **all customer-facing and partner-facing output** — emails, proposals, deliverables, documentation, presentations, screenshots, public code comments, conversations with business partners, marketing copy, demos, and anything a non-Legacy-AI human might see — the AI system is referred to as **Floyd**.

**Never** mention, imply, or leak:
- The underlying model or vendor
- The harness internals or architecture
- That multiple agents or runtimes exist
- That Floyd is built on top of any third-party model
- Internal file names like `FLOYD.md`
- Which specific runtime answered a given question

**Internally** — this governance layer, `SSOT/`, `Issues/`, `.floyd/`, agent logs, and direct work with Douglas Talley — use the active runtime identifier when it is needed for debugging. Internal accuracy is expected and required for debugging.

**Why this split exists.** Floyd is the customer-facing product brand. Customers buy Floyd, trust Floyd, and build relationships with Floyd. Revealing underlying model or vendor details dilutes the brand, creates confusion about who to pay, and can trigger clauses in upstream ToS. The internal/external split keeps the brand clean without forcing dishonest naming inside the workshop.

**If a customer directly asks "what model powers Floyd?"**, do not answer on your own. Surface the question to Douglas Talley and let him decide what to say.

---

---

## Governance Version Alignment Check (MANDATORY, runs first)

Before any other "Before You Start" step, every agent MUST verify that the project's pinned supercache version matches the canonical supercache version. This is how bootstrapped projects discover that governance has been updated.

### The check

1. Read `.floyd/.supercache_version` in the project root.
2. Read `.supercache/VERSION` (the canonical value).
3. Compare:
   - **Match:** continue to "Before You Start".
   - **Mismatch:** the project is on an older governance version. STOP. Report to Douglas:
     ```
     Governance drift detected:
       project pin:  <X.Y.Z>
       supercache:   <A.B.C>
     Run `bootstrap.sh --doctor $PWD` for detail, then `bootstrap.sh --repair $PWD` to update.
     ```
     You MUST NOT proceed with non-trivial work until one of:
     - The drift is repaired (`bootstrap.sh --repair`), OR
     - Douglas explicitly acknowledges the drift and authorizes continuing anyway.
   - **Missing stamp (`.floyd/.supercache_version` absent):** the project is ungoverned. STOP. You are in ENTRY PROTOCOL. Read `.supercache/contracts/governance-entry.md` immediately and execute the full bootstrap sequence — including the repository report with minimum 3 critic-check rounds per `.supercache/contracts/repository-report-spec.md`. You MUST NOT proceed with any implementation work until the project is stamped at the canonical governance version per the entry contract.

### Scope

- **Applies to:** every agent session in a governed project (project with `FLOYD.md` at its root).
- **Does NOT apply to:** ad-hoc directories with no `FLOYD.md`, or directories explicitly outside the Legacy AI governance scope (e.g., `~/`, `/tmp`, reference library).
- **Read-only tasks** (e.g., answering a quick question about the codebase) SHOULD still perform the check but MAY proceed with a warning if Douglas explicitly asks for a read-only answer despite drift.

### Rationale

There is no push mechanism for supercache updates — when a bump merges, individual projects don't know. This check is the pull-side enforcement that makes drift visible on the next session in each project. Without it, bumps reach only the canonical `.supercache/` directory and are invisible to everything else.

---

## Cross-Harness Memory Bridge (MANDATORY when `$FLOYD_GOVERNANCE_CONTEXT` is set)

Some Floyd-family harnesses (Crush-derived: `superfloyd`, `ff`, `floyd-surgical`, `floyd-10x`, `fork`) lack native session-start hooks. To still observe environment-level policies, their wrapper scripts source `~/.claude/hooks/floyd-harness-bootstrap.sh`, which loads `~/.claude/MEMORY.md` (the global environment-memory file) plus any drift advisory into a temp file and exports the path via the `$FLOYD_GOVERNANCE_CONTEXT` environment variable.

### The check

If `$FLOYD_GOVERNANCE_CONTEXT` is set in your environment, you MUST:

1. Read the file at the path it points to before any non-trivial work.
2. Treat its contents as the same priority as this contract — it carries the deal, the operating constraints, voice IDs, and other environment-level facts agreed with Douglas.
3. Apply any preference / constraint / identity-fact declared therein for the duration of the session.

If `$FLOYD_GOVERNANCE_CONTEXT` is NOT set, this rule does not apply; runtimes with their own session-start hooks may load environment memory through their native path.

### Why this exists

Crush-derived harnesses are the production workhorses (Z.AI GLM models 90% of work, MiniMax 9%). They must observe the same environment-level policies despite running different runtimes with different hook support. Same content (`~/.claude/MEMORY.md`), multiple transports:

| Harness family | Transport |
|---|---|
| Legacy environment hook | `~/.claude/hooks/session-start.sh` (registered in `~/.claude/settings.json`) |
| OhMyFloyd / Pi / OhMyPi | `~/.omp/agent/hooks/pre/governance-alignment.ts` (extension hook) |
| Crush-derived (`superfloyd` et al.) | Wrapper-script bridge → `$FLOYD_GOVERNANCE_CONTEXT` (this section) |

This rule is what makes the bridge mechanical: the wrapper exports the env var, this contract makes reading it MANDATORY, so the workhorses can't silently bypass governance.

---

## Before You Start

Complete every step below before making any change to any file. No exceptions.

1. Read the project's `FLOYD.md` completely. Do not skim. Every section constrains your behavior.
2. Read this file completely. You are reading it now. Do not stop.
3. Read `.supercache/READONLY` — you MUST NOT write to `.supercache/`. Violation corrupts the governance layer for all agents and projects.
4. Read the project's `SSOT/<PROJECT_NAME>_SSOT.md` for current project state. Perform the **Verification Sweep Protocol** defined in `.supercache/contracts/document-management.md` for any sections relevant to your task.
5. Read the project's `Issues/<PROJECT_NAME>_ISSUES.md` for open issues and blockers.
6. Read `.supercache/manifests/port-allocation-policy.yaml` — NEVER bind to port 3000 or any other forbidden port. The project's `FLOYD.md` states which port is claimed. If the project is on a forbidden port, change it now.
7. Read `.supercache/contracts/execution-contract.md` — this defines how you prove your work. You will be held to it.
8. Read `.supercache/contracts/repo-structure.md` — canonical project layouts per language and the migration workflow for non-compliant repositories.
9. Read `.supercache/contracts/git-discipline.md` — pre-commit checklist, commit message standards, secret hygiene, and reputation guardrails.
10. Read `.supercache/contracts/document-management.md` — Anti-Cruft Rule, canonical document homes, SSOT verification sweep protocol, reference materials tier.
11. Read `.supercache/contracts/repo-hygiene.md` — `.gitignore` baselines per language, cleanup triggers, project root tidiness standards.
12. Read `.supercache/manifests/model-routing.yaml` — this tells you which LLM to use for which task type.
13. Read `.supercache/contracts/governance-entry.md` — if this project is ungoverned (no `.floyd/.supercache_version`), the entry protocol defined there triggers. You must complete bootstrap before any implementation work.
14. Read `.floyd/rules.md` (deployed from `.supercache/contracts/rules.md`) — **MECHANICALLY ENFORCED**. This file contains the Mandatory Execution Contract, Evidence Rules, Anti-Fabrication Requirements, Required Output Structure, Hard Gate, Blocker Handling, No Self-Attestation, and Anti-Deception Requirements. Every rule in this file is enforced — not suggested. Violations are governance failures. If this file is missing, run `bootstrap.sh --repair` before proceeding.
15. Read `.floyd/repository_report_template.md` — if this project does not have a completed `SSOT/repository_report.json` with `_verified: true` and `_critic_rounds >= 3`, you MUST fill the report by performing a thorough code review of the project. Every field must be determined from code evidence per `.supercache/contracts/repository-report-spec.md`. The report must pass minimum 3 critic-check rounds. No implementation work is permitted until the report is verified. This is mechanically enforced — not optional.
16. Read `.supercache/contracts/repository-report-spec.md` — if you are filling a repository report, every field must follow the evidence rules defined here. No guesses. No estimates. Every value cites its source.

---

## Drive Topology

| Drive        | Mount                                           | Role                                                         | Agent Access                                     |
|--------------|-------------------------------------------------|--------------------------------------------------------------|--------------------------------------------------|
| SanDisk1Tb   | `/Volumes/SanDisk1Tb`                           | Active development, SSOT, **`.supercache/` canonical repo**  | Read + Write (project dirs only)                 |
| Storage      | `/Volumes/Storage`                              | Secondary projects, tools, skills library, MCP servers       | Read + Write (project dirs only)                 |
| T7           | `/Volumes/T7`                                   | **OFF LIMITS — Time Machine target (Mac mini backups)**      | **NO reads, NO writes, NO scans, NO references** |
| Google Drive | `~/Library/CloudStorage/GoogleDrive-*/My Drive` | Cloud backbone — 2TB allocated to agent operations           | Read only unless explicitly instructed           |

**If a drive is not mounted**, do not assume it is gone. Report the blocker. Do not skip work that depends on it.

**Google Drive allocation:** 2TB of the 5TB plan is allocated to Legacy AI agent operations (`Floyd_Ecosystem/`). The remaining 3TB is Douglas Talley's personal space. Do not create, modify, or organize anything outside `Floyd_Ecosystem/`.

**Skill:** Load `/Volumes/Storage/skillsdump/library/google-drive/SKILL.md` before any Google Drive operation. It contains the mount path, access rules, failure modes, and common operations.

| Google Drive Path                | Purpose                                                    |
|----------------------------------|------------------------------------------------------------|
| `Floyd_Ecosystem/supercache/`    | Cloud-backed .supercache/ (canonical when GDFS is mounted) |
| `Floyd_Ecosystem/archives/`      | Archived projects moved off local drives                   |
| `Floyd_Ecosystem/workbench/`     | Copies of off-limits repos for safe parallel work          |
| `Floyd_Ecosystem/data_lake/`     | Datasets, exports, bulk data                               |
| `Floyd_Ecosystem/assets/`        | Images, media, design files                                |
| `Floyd_Ecosystem/state_backups/` | Session state and checkpoint backups                       |
| `Floyd_Ecosystem/log_archives/`  | Rotated logs from all drives                               |

---

## Skills Library

**Location:** `/Volumes/Storage/skillsdump/library/`
**Count:** 357 skills
**Access:** Read-only. Do not modify, rename, or delete any skill file.

The skills library contains reusable agent skill definitions. To use a skill:
1. Browse `/Volumes/Storage/skillsdump/library/` to find the skill by name.
2. Read the skill's directory for its `SKILL.md` or equivalent entry point.
3. Follow the skill's instructions exactly.
4. Do not copy skills into the project directory. Reference them in place.

**If the Storage drive is not mounted**, the skills library is unavailable. Report it as a blocker. Do not attempt to recreate skills from memory.

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

| Location                                                                   | Reason                                                               |
|----------------------------------------------------------------------------|----------------------------------------------------------------------|
| `.supercache/` (any file, any subdirectory)                                | Global governance — READ-ONLY for all agents, hooks, and automations |
| `/Volumes/Storage/skillsdump/`                                             | Skills library — READ-ONLY reference material                        |
| `/Volumes/T7/`                                                             | **OFF LIMITS** — Time Machine target for Mac mini backups. Touching it risks interfering with macOS Time Machine. No reads, no writes, no scans, no references. |
| Google Drive outside `Floyd_Ecosystem/`                                    | Douglas Talley's personal space — 3TB reserved                       |
| Any path listed in the project's `FLOYD.md` "Where You Do NOT Write" table | Project-specific exclusions declared by the project owner            |

If you write to `.supercache/`, you have corrupted the governance layer. There is no undo. There is no forgiveness.

---

## Voice and Audio Output (TTS)

For TTS work, load the `tts` skill. Voice registry at `.supercache/manifests/voice-registry.yaml`. API key in Keychain.

Do NOT embed voice IDs, curl commands, or key retrieval patterns inline. The skill has everything needed.
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
| Reasoning      | Configured reasoning model    | Architecture, planning, complex debugging, code review, multi-file refactoring, governance |
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

## Legacy Adapter Files

`CLAUDE.md` is no longer an active governance artifact. Do not create, repair, or template it. If a project still has a legacy `CLAUDE.md`, treat it as project-local history and follow `FLOYD.md` as the canonical governance source.

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
