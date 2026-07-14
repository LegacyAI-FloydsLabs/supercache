# Repository Report Specification — Deterministic Field Evidence Rules
**Version:** 1.7.2
**Governance:** .supercache/ v1.7.2
**Type:** Mandatory — referenced by GOVERNANCE-ENTRY.md
**Applies to:** All agents filling `SSOT/repository_report.json`

> This specification defines exactly how each field in the repository report template (`/Volumes/SanDisk1Tb/.supercache/templates/repository-report-template.md`) must be determined. No field may be filled without following the evidence rule below. Every field must cite its evidence source.

---

## Report Schema (12 fields)

The repository report is a JSON file at `SSOT/repository_report.json` with this structure:

```json
{
    "project_name": "string",
    "completion_percentage": 0-100,
    "tech_stack": ["string", ...],
    "complexity_score": 1-10,
    "team_size_minimum": integer,
    "go_to_market_timeline": "string",
    "industry_vertical": "string",
    "business_model": "string",
    "technical_debt": 0-100,
    "scalability_needs": "low|medium|high",
    "target_users": "string",
    "key_features": ["string", ...],
    "risks": ["string", ...],
    "_evidence": {
        "project_name": "file:line or command+output",
        "completion_percentage": "...",
        "...": "..."
    },
    "_verified": false,
    "_critic_rounds": 0,
    "_last_verified": null,
    "_verified_by": null
}
```

---

## Field-by-Field Evidence Rules

### 1. `project_name`

**Rule:** Use the directory name as it appears on disk. No transformations, no branding reinterpretations.

**Evidence source:** `basename $(pwd)`
**Example:** Directory is `/Volumes/SanDisk1Tb/ATerm` → `"project_name": "ATerm"`

**Common failure:** Renaming the project to something "better" than the directory name. Don't. The directory name is the canonical identifier for dashboard tracking.

---

### 2. `completion_percentage` (0–100)

**Rule:** Calculate from code evidence, not from documentation claims or README statements. This is the single most important field — it determines team size and finisher dispatch eligibility.

**Method A — Feature inventory (preferred):**

1. List all features/endpoints/routes/screens claimed in README.md, FLOYD.md, or any spec document
2. For each, check if implementation exists in source code:
   - Web app: Check `src/pages/`, `src/routes/`, `src/components/` for corresponding files
   - CLI: Check command registrations vs implemented handlers
   - API: Check route definitions vs handler implementations
   - Library: Check exported symbols vs documented API surface
3. Completion = (implemented features ÷ total claimed features) × 100

**Method B — Git history analysis (fallback):**

1. Count total commits
2. Count commits in last 30 days (active development indicator)
3. If active development: estimate from commit velocity vs stated scope
4. If inactive (0 commits in 30 days): check if project "looks done" (no TODO/FIXME, tests pass, no stubs)

**Method C — File count ratio (last resort):**

1. Count files with implementation code (exclude config, docs, tests, assets)
2. Estimate based on project type:
   - 0–10 files → 0–15% (early prototype)
   - 10–50 files → 15–40%
   - 50–100 files → 40–65%
   - 100–200 files → 65–85%
   - 200+ files → 85–100%

**Evidence format:** `"Method A: 14 of 22 claimed features implemented = 63.6% → rounded to 64%"`

**Common failures:**
- Trusting a README that says "80% complete" without code verification
- Rounding to neat numbers (0, 25, 50, 75, 100) — real projects have messy percentages
- Using Method C when Methods A or B are feasible

---

### 3. `tech_stack`

**Rule:** Extract from dependency manifests only. Do not infer from file extensions alone.

**Detection order:**
1. `package.json` → `dependencies` + `devDependencies` keys → extract framework names (React, Express, Next.js, etc.) + language = TypeScript if `tsconfig.json` exists, else JavaScript
2. `go.mod` → `require` block → extract module paths → language = Go
3. `pyproject.toml` or `requirements.txt` → extract dependencies → language = Python
4. `Cargo.toml` → `[dependencies]` → language = Rust
5. `Gemfile` → language = Ruby
6. `pom.xml` or `build.gradle` → language = Java/Kotlin
7. `CMakeLists.txt` or `Makefile` → language = C/C++

**Additional detection:**
- Database: `prisma/`, `migrations/`, `knexfile`, `sqlalchemy` → add specific DB
- CSS framework: `tailwind.config`, `postcss.config` with tailwind → add Tailwind
- Testing: `jest.config`, `vitest.config`, `pytest.ini` → add test framework

**Evidence format:** `"package.json dependencies: react@18, express@4, prisma@5; tsconfig.json exists → ['TypeScript', 'React', 'Express', 'Prisma', 'PostgreSQL']"`

---

### 4. `complexity_score` (1–10)

**Rule:** Objective rubric. Score each dimension, take the ceiling of the average.

| Dimension | Score 1-3 (Simple) | Score 4-6 (Moderate) | Score 7-10 (Complex) |
|---|---|---|---|
| File count | <20 source files | 20-100 source files | >100 source files |
| Dependency count | <10 deps | 10-40 deps | >40 deps |
| Architecture | Single module / flat | Multiple modules / layered | Microservices / event-driven / multi-repo |
| State management | Stateless or local state only | Database with simple queries | Distributed state / caching / queues |
| Auth/Security | None or simple API key | OAuth2 / JWT with refresh | Multi-tenant / RBAC / compliance |
| Concurrency | Single-threaded | Async but single-process | Multi-process / distributed / real-time |
| Data complexity | Flat JSON or key-value | Relational with joins | Graph / time-series / multi-store |

**Scoring:** Average the 7 dimensions, round up to nearest integer.

**Evidence format:** `"Files: 45 → 4, Deps: 32 → 5, Arch: layered → 5, State: SQLite → 4, Auth: JWT → 5, Concurrency: async → 4, Data: relational → 5. Average: 4.57 → complexity_score: 5"`

---

### 5. `team_size_minimum`

**Rule:** Derived from `completion_percentage` and `complexity_score`. This is the MINIMUM team size — the actual dispatched team may be larger based on the team builder algorithm.

**Formula:**

| Completion % | Base size |
|---|---|
| 0–30% | 4 |
| 31–60% | 6 |
| 61–85% | 8 |
| 86–100% | 10 |

**Adjustment:** If `complexity_score` ≥ 8, add 2. If `complexity_score` ≤ 3, subtract 1 (minimum 2).

**Evidence format:** `"completion=35% → base 6, complexity=5 → no adjustment → team_size_minimum: 6"`

---

### 6. `go_to_market_timeline`

**Rule:** Estimate from `completion_percentage` and git history velocity.

1. If completion < 10%: "6+ months"
2. If completion 10-40%: "3-6 months"
3. If completion 40-70%: "1-3 months"
4. If completion 70-90%: "2-4 weeks"
5. If completion > 90%: "1-2 weeks"

**Adjust for git velocity:** If last commit was >30 days ago, add " (inactive — restart cost unknown)".

**Evidence format:** `"completion=35% + active git (3 commits this week) → go_to_market_timeline: '3-6 months'"`

---

### 7. `industry_vertical`

**Rule:** Infer from project name, README content, and domain terminology found in source code. Acceptable values: "Technology", "Healthcare", "Finance", "Education", "Real Estate", "E-commerce", "Gaming", "Developer Tools", "AI/ML", "Cybersecurity", "IoT", "Unknown".

**Evidence source:** `head -50 README.md` + grep for industry keywords in source code comments and strings.

**Evidence format:** `"README.md:3 mentions 'SaaS platform for real estate agents' → industry_vertical: 'Real Estate'"`

---

### 8. `business_model`

**Rule:** Acceptable values: "B2B", "B2C", "B2B2C", "Internal Tool", "Open Source", "Unknown".

**Detection:** README.md, pricing references, target audience language. If no evidence, "Unknown".

**Evidence format:** `"README.md:12 'pricing per seat for enterprise teams' → business_model: 'B2B'"`

---

### 9. `technical_debt` (0–100)

**Rule:** Measure, don't guess. Score each indicator, average, round up.

| Indicator | 0 (Clean) | 50 (Moderate) | 100 (Severe) |
|---|---|---|---|
| TODO/FIXME/HACK count | 0-5 | 6-30 | 30+ |
| Test coverage (if detectable) | >60% | 10-60% | <10% or no tests |
| Dependency freshness | All latest | Some outdated (1 major version behind) | Severely outdated (2+ major versions) |
| Code duplication (grep for repeated blocks) | None visible | Some patterns repeated | Heavy copy-paste |
| Config hardcoding (.env vs hardcoded URLs/keys) | All in .env | Mixed | Secrets in source |
| Error handling | Try/catch or Result types present | Inconsistent | Swallowed errors / no handling |
| Documentation presence | FLOYD.md + SSOT + README all filled | README only | No docs at all |

**Evidence format:** `"TODOs: 12 → 40, Tests: none → 100, Deps: outdated → 50, Duplication: moderate → 50, Config: mixed → 50, Errors: inconsistent → 50, Docs: README only → 50. Average: 55.7 → technical_debt: 56"`

---

### 10. `scalability_needs`

**Rule:** Acceptable values: "low", "medium", "high". Derived from `business_model` and evidence of concurrent users/data volume.

- **low**: Internal tool, single-user, CLI, or local-only app
- **medium**: B2B SaaS, team-level usage, moderate data
- **high**: B2C, public-facing, real-time, large data volumes

**Evidence format:** `"README describes 'internal tool for the dev team' → scalability_needs: 'low'"`

---

### 11. `target_users`

**Rule:** One sentence describing the intended user from README or spec. If unknown: "Unknown — no user description found in project documentation."

**Evidence format:** `"README.md:5 'A CLI tool for DevOps engineers managing Kubernetes clusters' → target_users: 'DevOps engineers managing Kubernetes clusters'"`

---

### 12. `key_features`

**Rule:** Extract from README feature lists, route definitions, CLI command registrations, or exported API surface. List 3-10 items. Each must be verifiable in code.

**Evidence format:** `"README.md features section lists 5 features; verified 4 of 5 in src/routes/ → key_features: ['User authentication', 'Dashboard analytics', 'Report generation', 'Email notifications']"`

---

### 13. `risks`

**Rule:** Identify 2-5 project-specific risks. Categories:
- **Technical**: Single points of failure, unmaintained dependencies, missing tests
- **Security**: No auth, secrets in code, no HTTPS enforcement
- **Operational**: No deployment docs, no monitoring, bus factor = 1
- **Market**: No clear target user, no differentiation

**Evidence format:** `"grep found API keys in src/config.ts:15 → risk: 'Secrets hardcoded in source'; no test files found → risk: 'Zero test coverage'"`

---

## Critic-Check Protocol (Minimum 3 Rounds)

After filling all fields, execute these rounds sequentially. Each round produces a correction diff.

### Round 1 — Self-Critic

For each field, ask:
- "If someone challenged this value, could I defend it with the evidence citation?"
- "Is this value too round, too generic, or too convenient?"
- "Did I use the hardest available method (A before B before C)?"

Fix any field that fails. Record corrections.

### Round 2 — Code Evidence Audit

For each field, follow the evidence citation back to source:
- Open the file at the cited line. Does it actually say what you claim?
- Run the cited command. Does the output match what you reported?
- If evidence is a calculation (e.g., completion %), re-run it manually. Same result?

Fix discrepancies. Record corrections. If a discrepancy can't be resolved, mark the field `"UNVERIFIED — [reason]"`.

### Round 3 — Fresh Eyes

Read the entire report as if you are a new agent who has never seen this project:
- Does every value make sense independently without needing the evidence citation?
- Are any fields suspiciously similar to the template placeholder values?
- Is the report internally consistent? (e.g., `completion_percentage=15` but `key_features` lists 8 features — those don't match)
- Would you stake your reputation on this report's accuracy?

Fix inconsistencies. After this round, if zero corrections were needed, set `_verified: true` and `_critic_rounds: 3`. If corrections were needed, do another round. Maximum 5 rounds — if still unverified after 5, flag for Douglas.

---

## Report Acceptance Criteria

All must be true before stamping governance:

- [ ] All 12 fields have non-placeholder, non-template values
- [ ] `_evidence` object has a citation for every field
- [ ] `_verified` is `true`
- [ ] `_critic_rounds` is ≥ 3
- [ ] `_last_verified` is current ISO 8601 timestamp
- [ ] `_verified_by` is the agent identifier
- [ ] Zero fields marked "UNVERIFIED"
- [ ] No field value matches the template placeholder exactly

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
