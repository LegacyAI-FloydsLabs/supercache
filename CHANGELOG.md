# Legacy AI Governance — Changelog

Newest first.

---

## v1.7.1 — 2026-07-04

Scope: repair the v1.7.x canonical governance repo after partial Claude-adapter removal left broken shell syntax, stale CLI routes, and version drift. This release finishes the removal without restoring Claude-specific agent positioning.

### Fixed

- **`bootstrap.sh`** — removed injected marker text, orphaned adapter-function fragments, undefined `cmd_add_claude` routing, and broken `cmd_bulk_init` shell structure.
- **`scripts/post-bump-sweep.sh`** — accepts `--doctor` explicitly and handles zero discovered projects under `set -u`.
- **`hooks/supercache-repo-precommit.sh`** — now checks `FLOYD.md`, `.floyd/.supercache_version`, and shell syntax so the previous failure mode is blocked before commit.
- **Version lockstep** — bumped canonical version-bearing files and the self-governance stamp to `1.7.1`.

### Removed

- **`templates/claude-md-template.md`** — removed as an active governance template.
- **Claude adapter workflow references** — removed active `--add-claude`, `--no-claude`, and generated `CLAUDE.md` guidance from bootstrap, templates, and contracts.

---

## v1.6.2 — 2026-04-30

Scope: extend v1.6.1's no-delete enforcement from Claude Code only to **every agent harness on this machine that exposes a PreTool hook surface**. Lift the deletion patterns + path allowlist into a shared rules file (`~/.local/share/legacy-ai/no-delete/rules.json`) and a shared core library (`~/.local/share/legacy-ai/no-delete/core.js`). Each harness ships a thin adapter that delegates to the core. No vendor lock-in.

### Added (outside .supercache/)

- **`~/.local/share/legacy-ai/no-delete/rules.json`** — single source of truth for deletion regex patterns + allowlisted ephemeral cache paths + block message template. Edited only via governance bumps.
- **`~/.local/share/legacy-ai/no-delete/core.js`** — pure check function (`checkCommand(cmd, {rulesPath, harness}) → {allow} | {allow:false, message}`). No I/O beyond rule loading; no `process.exit`. Adapters translate the verdict into the harness-specific block primitive.
- **`~/.local/bin/floyd-no-delete-check`** — generic shell wrapper. Reads JSON-on-stdin (Claude Code / Factory.ai compatible) or accepts a command on argv (`floyd-no-delete-check rm -rf /tmp/foo` or `--cmd "rm ..."`). Used by harnesses without a structured PreTool hook protocol (Codex CLI, Aider, raw SDK scripts).
- **`~/.factory/hooks/no-delete-guard.js`** + **`~/.factory/hooks/hooks.json`** PreToolUse Execute entry — Factory.ai droid adapter. Hook protocol mirrors Claude Code's (JSON-on-stdin, exit 2 to block).
- **`~/.opencode/plugins/legacy-ai-no-delete/`** — OpenCode plugin. Registers `tool.execute.before`; throws on block (OpenCode aborts the tool call). Requires manual reference from `opencode.json` (`"plugin": [".../index.js"]`) — OpenCode does not auto-discover from `.opencode/plugins/`.
- **`~/.config/floyd/plugins/legacy-ai-no-delete/`** — Floyd CLI (omp v14.x) adapter. Subscribes to `tool_call` events and returns `{block: true, reason}`. Auto-discovered by Floyd from `~/.config/floyd/plugins/`.

### Changed (outside .supercache/)

- **`~/.claude/scripts/hooks/no-delete-guard.js`** — refactored to a thin wrapper that requires the shared core. Patterns + allowlist no longer hardcoded in this file. Behavior identical to v1.6.1 from the user's perspective; future pattern changes ship by editing `rules.json` only.
- **`~/.claude/settings.json`** — PreToolUse Bash hook entry pointed at the refactored adapter (path unchanged; jq merge replaces any prior `no-delete-guard.js` command entry to keep the registration idempotent).

### Added (inside .supercache/)

- **`CHANGELOG.md` entry** for v1.6.2 (this file).

### Changed (inside .supercache/)

- **`VERSION`** — bumped 1.6.1 → 1.6.2.
- **`README.md`** — version header bumped.
- **`contracts/agent-contract.md`** — version + governance headers bumped 1.6.1 → 1.6.2. No content change in this bump.

### Documentation (outside .supercache/)

- **`~/legacy-governance-pending/v1.6.2/docs/harness-coverage.md`** — supplementary doc enumerating coverage tier per harness (mechanical / wrapper / contract). Stays in the staging tree as install-time reference, not in `.supercache/contracts/`. The contract authority remains v1.6.0's `repo-sanitation.md`; v1.6.2 only changes WHO can mechanically enforce it.

### Unchanged (explicitly)

- `manifests/`, `templates/`, `scripts/governance-bump.sh`, `scripts/post-bump-sweep.sh` — untouched.
- The deletion patterns and allowlist are byte-identical to v1.6.1; v1.6.2 only changes WHERE those rules live (extracted to shared JSON) and WHO can enforce them (every harness, not just Claude Code).
- `floyd-quarantine` — unchanged from v1.6.1.

### Coverage matrix (post-bump)

| Harness            | Hook surface                        | Coverage   | Adapter                                                  |
|--------------------|-------------------------------------|------------|----------------------------------------------------------|
| Claude Code        | `settings.json` PreToolUse Bash     | mechanical | `~/.claude/scripts/hooks/no-delete-guard.js`             |
| Factory.ai droid   | `hooks.json` PreToolUse Execute     | mechanical | `~/.factory/hooks/no-delete-guard.js`                    |
| OpenCode           | `tool.execute.before` plugin        | mechanical | `~/.opencode/plugins/legacy-ai-no-delete/` *(opt-in via opencode.json)* |
| Floyd CLI (omp)    | `pi.on("tool_call")` → `{block}`    | mechanical | `~/.config/floyd/plugins/legacy-ai-no-delete/`           |
| Codex CLI          | none (only `[mcp_servers]`)         | wrapper    | `floyd-no-delete-check` from prompt-driven shell guard   |
| Aider              | none                                | wrapper    | `floyd-no-delete-check` from prompt-driven shell guard   |
| Cursor             | none                                | contract   | repo-sanitation.md authority only                        |
| Gemini CLI         | none                                | contract   | repo-sanitation.md authority only                        |
| Raw SDK scripts    | n/a (user-authored)                 | wrapper    | author calls `floyd-no-delete-check` before any rm-shaped op |

### Migration step (post-merge)

```bash
bash /Volumes/SanDisk1Tb/.supercache/scripts/post-bump-sweep.sh --repair
```

Re-stamps every governed project's `.floyd/.supercache_version` to `1.6.2`.

### Verification plan (post-merge)

1. `cat /Volumes/SanDisk1Tb/.supercache/VERSION` → expect `1.6.2`
2. `test -f ~/.local/share/legacy-ai/no-delete/rules.json && echo OK` → `OK`
3. `test -f ~/.local/share/legacy-ai/no-delete/core.js && echo OK` → `OK`
4. `test -x ~/.local/bin/floyd-no-delete-check && echo OK` → `OK`
5. `~/.local/bin/floyd-no-delete-check --cmd "rm -rf /Volumes/Storage/important"; echo $?` → `2`
6. `~/.local/bin/floyd-no-delete-check --cmd "rm -rf /tmp/foo"; echo $?` → `0`
7. `node ~/.claude/scripts/hooks/no-delete-guard.js <<< '{"tool_name":"Bash","tool_input":{"command":"rm -rf /Volumes/Storage/x"}}'; echo $?` → `2`
8. (if Factory droid present) `node ~/.factory/hooks/no-delete-guard.js <<< '{"tool_name":"Execute","tool_input":{"command":"rm -rf /Volumes/Storage/x"}}'; echo $?` → `2`
9. `bash /Volumes/SanDisk1Tb/.supercache/scripts/governance-bump.sh verify` → exit 0

### Rationale

v1.6.1 left a vendor-lock-in gap: the contract was harness-agnostic but the mechanical enforcement was Claude-Code-only. Every other harness (Factory droid, OpenCode, Floyd CLI, Codex, Aider, raw SDK scripts) was protected only by the contract, which is honor-system. v1.6.2 closes the gap by making mechanical enforcement match the contract's scope.

The shared core design means future pattern changes (new deletion idioms agents reach for) ship as edits to a single JSON file. No per-harness drift. No "we updated Claude but forgot OpenCode."

The wrapper is the safety net for everything without a structured hook surface. A prompt-driven agent on Codex or Aider can be instructed via the project's CLAUDE.md / FLOYD.md / system prompt to invoke `floyd-no-delete-check` before any deletion-shaped operation, which still gives mechanical enforcement at the cost of one shell-out.


## v1.6.1 — 2026-04-30

Scope: mechanical enforcement of the v1.6.0 deletion prohibition. Ship the PreToolUse no-delete-guard hook (Node-based, pattern-matches deletion commands in Bash tool calls) and the `floyd-quarantine` helper (atomic move + WHY.md + LEDGER.jsonl append). No contract content changes — version headers and CHANGELOG only on the supercache side; the user-level installation lives in `~/.claude/scripts/hooks/` and `~/.local/bin/`.

### Added (outside .supercache/)

- **`~/.claude/scripts/hooks/no-delete-guard.js`** — Claude Code PreToolUse hook that pattern-matches deletion commands (`rm`, `rm -rf`, `unlink`, `rmdir`, `git clean`, `git rm`, `shutil.rmtree`, `os.remove`, `os.unlink`, `fs.unlink`, `fs.rm`, `Remove-Item`, `find -delete`, `find -exec rm`) and blocks them with exit 2 and a pointer to `floyd-quarantine`. Allowlist permits cleanup of ephemeral cache directories (`/tmp/`, `__pycache__`, `.pytest_cache`, `.ruff_cache`, `.mypy_cache`, `node_modules`, `.next`, `.turbo`, `dist/`, `build/`) when `rm`/`rmdir`/`unlink` is the only command and ALL targets are inside the allowlist.
- **`~/.local/bin/floyd-quarantine`** — bash helper. Usage: `floyd-quarantine <path> --reason <category> --note "<one-liner>" [--agent <id>]`. Auto-detects project root by walking up for `.floyd/` or `FLOYD.md`, computes relative path, moves target to `<project-root>/.floyd/quarantine/<YYYY-MM-DD>/<rel-path>`, authors WHY.md per `repo-sanitation.md §3.3` schema, appends a JSON line to `LEDGER.jsonl`, uses `git mv` if the target is tracked. Refuses to quarantine inside `.supercache/`.
- **`~/.claude/settings.json` PreToolUse hook entry** — registers the no-delete-guard.js as a hook on the Bash tool. Installation script patches the JSON in place (preserves existing hooks).

### Added (inside .supercache/)

- **CHANGELOG.md entry** for v1.6.1 (this file).

### Changed (inside .supercache/)

- **`VERSION`** — bumped 1.6.0 → 1.6.1.
- **`README.md`** — version header bumped 1.6.0 → 1.6.1.
- **`contracts/agent-contract.md`** — version + governance headers bumped 1.6.0 → 1.6.1. No content change in this bump.

### Unchanged (explicitly)

- All other contracts under `contracts/` — untouched.
- `manifests/`, `templates/`, `scripts/governance-bump.sh`, `scripts/post-bump-sweep.sh` — untouched.
- The repo-sanitation.md authority remains v1.6.0; v1.6.1 only adds the mechanical enforcement layer.

### Migration step (post-merge)

```bash
bash /Volumes/SanDisk1Tb/.supercache/scripts/post-bump-sweep.sh --repair
```

This re-stamps every governed project's `.floyd/.supercache_version` to `1.6.1`.

### Verification plan (post-merge)

1. `cat /Volumes/SanDisk1Tb/.supercache/VERSION` → expect `1.6.1`
2. `test -x ~/.local/bin/floyd-quarantine && echo OK` → expect `OK`
3. `test -f ~/.claude/scripts/hooks/no-delete-guard.js && echo OK` → expect `OK`
4. `node ~/.claude/scripts/hooks/no-delete-guard.js <<< '{"tool_name":"Bash","tool_input":{"command":"rm -rf /tmp/foo"}}'; echo $?` → expect `0` (allowlisted /tmp/)
5. `node ~/.claude/scripts/hooks/no-delete-guard.js <<< '{"tool_name":"Bash","tool_input":{"command":"rm -rf /Volumes/Storage/important"}}'; echo $?` → expect `2` (blocked)
6. `floyd-quarantine` (bare invocation) → expect usage printout, exit 1
7. `bash /Volumes/SanDisk1Tb/.supercache/scripts/governance-bump.sh verify` → exit 0

### Rationale

v1.6.0 ships the contract — the words. v1.6.1 ships the mechanism — the runtime that enforces those words at the harness layer. The hook is a belt-and-suspenders measure; it cannot catch every deletion path (e.g., a Python script the agent writes that internally calls `os.remove`), but it catches the overwhelming majority of paths agents reach for when they reach for deletion. The helper makes the alternative (quarantine) one-line ergonomic, so there's no friction-driven excuse to bypass.

The hook fails open on parse errors and is allowlisted for legitimate cache cleanup so it doesn't block normal work.


## v1.6.0 — 2026-04-30

Scope: repository sanitation regime. Establish a single, non-negotiable rule across both code and document management — **agents do not delete; they quarantine.** Define the quarantine mechanism, the daily bootstrap routine that enforces sanitation on every session, and the execution contracts that prove both happened. Supersede the deletion provisions of `repo-hygiene.md` and the `Delete` lifecycle action of `document-management.md`.

### Added

- **`contracts/repo-sanitation.md`** — new authoritative contract for repository sanitation health and document management best practices. Codifies three hard rules (agents do not delete; removal means quarantine; only Douglas empties quarantine), the quarantine protocol (`<project>/.floyd/quarantine/<YYYY-MM-DD>/<original-relative-path>` + `WHY.md` + append-only `LEDGER.jsonl`), the ControlBoard alert requirement, the best-practices execution contracts for both doc management and repo sanitation, the daily bootstrap routine A→F, secret-hygiene escalation (above quarantine), and the user-override semantics (override grants scope, never deletion authority). Ends with the mandatory execution contract footer.

### Changed

- **`contracts/document-management.md`** (v1.4.1 → v1.6.0):
  - Version + governance headers bumped.
  - Forward-pointer added at top: removal flows route through `repo-sanitation.md`.
  - "Document Lifecycle" section: `Delete` step replaced with `Quarantine`. Pointer to `repo-sanitation.md §3` for the protocol.
  - "Archival vs deletion" section: rewritten as "Archival vs quarantine". Quarantine replaces delete.
  - "Forbidden Document Patterns" section: clarified that the disposition for any forbidden pattern encountered in an existing project is **quarantine**, not delete.
  - "Relationship to Other Contracts" section: `repo-sanitation.md` added.
  - Enforcement Posture bumped to v1.6.0; advisory remains the posture for v1.6.0 (hard enforcement via PreToolUse hook arrives in v1.6.1).
- **`contracts/repo-hygiene.md`** (v1.3.0 → v1.6.0):
  - Version + governance headers bumped.
  - Forward-pointer added at top: removal flows route through `repo-sanitation.md`.
  - "Cleanup Triggers" subsections: deletion language replaced with quarantine language.
  - "Safety Protocol Before Deleting Anything" section: replaced with a supersession notice pointing to `repo-sanitation.md §6.2`.
  - "User Override" section: rewritten. Override grants scope (what to clean), never operation (deletion vs quarantine — quarantine is always the operation).
  - "Dead Code and Commented-Out Blocks" section: `Default policy: delete` rescinded. Replaced with quarantine-extract protocol that points to `repo-sanitation.md §6.3`.
  - "Relationship to Other Contracts" section: `repo-sanitation.md` added.
  - Enforcement Posture bumped to v1.6.0; advisory remains the posture for v1.6.0 (hard enforcement arrives in v1.6.1 via PreToolUse hook).
- **`contracts/agent-contract.md`** — version banner bumped 1.5.0 → 1.6.0; governance line bumped accordingly.
- **`VERSION`**, **`README.md`** — version headers bumped 1.5.0 → 1.6.0 to keep the precommit drift check happy.

### Unchanged (explicitly)

- `contracts/execution-contract.md`, `contracts/git-discipline.md`, `contracts/repo-structure.md` — untouched.
- `contracts/governance-entry.md`, `contracts/repository-report-spec.md` — these were authored by an earlier (DeepSeek) session and remain untracked. This bump does not promote them; that is a separate decision pending Douglas's review.
- `manifests/` — untouched. No new manifests in this bump.
- `templates/` — untouched. The bootstrap routine added in `repo-sanitation.md §7` applies via the universal contract reference, not by per-project FLOYD.md edits.
- `scripts/governance-bump.sh`, `scripts/post-bump-sweep.sh` — untouched. The harness remains the only sanctioned write path.

### Migration step (post-merge)

```bash
bash /Volumes/SanDisk1Tb/.supercache/scripts/post-bump-sweep.sh --repair
```

This re-stamps every governed project's `.floyd/.supercache_version` to `1.6.0` so SessionStart drift checks pass cleanly.

### Verification plan (post-merge)

1. `cat /Volumes/SanDisk1Tb/.supercache/VERSION` → expect `1.6.0`
2. `test -f /Volumes/SanDisk1Tb/.supercache/contracts/repo-sanitation.md && echo OK` → expect `OK`
3. `grep -c "Agents Do Not Delete" /Volumes/SanDisk1Tb/.supercache/contracts/repo-sanitation.md` → expect ≥1
4. `grep -c "Removal Means Quarantine" /Volumes/SanDisk1Tb/.supercache/contracts/repo-sanitation.md` → expect ≥1
5. `grep -c "Version:.. 1.6.0" /Volumes/SanDisk1Tb/.supercache/contracts/document-management.md` → expect ≥1
6. `grep -c "Version:.. 1.6.0" /Volumes/SanDisk1Tb/.supercache/contracts/repo-hygiene.md` → expect ≥1
7. `grep -c "Quarantine over deletion" /Volumes/SanDisk1Tb/.supercache/contracts/repo-hygiene.md` → expect ≥1
8. `bash /Volumes/SanDisk1Tb/.supercache/scripts/governance-bump.sh verify` → exit 0

### Rationale

DeepSeek's session on 2026-04-29 demonstrated the failure mode this contract closes: an agent acting in good faith deleted or overwrote files it had no authority to touch, and rationalized the action against an absent rule. The previous `repo-hygiene.md` "Safety Protocol Before Deleting Anything" was a checklist, not a prohibition — agents could (and did) rationalize past it. The new regime is unambiguous: the operation is quarantine, and the *operation* is non-negotiable regardless of any *scope* the user granted. Combined with the daily bootstrap routine (which makes every session start with a sanitation pass) and the ControlBoard alert (which makes quarantine visible), the build-up is always under Douglas's control without delegating destructive authority to agents.

This bump is contracts-only. The mechanical enforcement (PreToolUse hook + `floyd-quarantine` helper + SessionStart bootstrap) ships in v1.6.1.


## v1.5.0 — 2026-04-26

Scope: TTS access surface. Make ElevenLabs voice synthesis available to every governed harness — including PEBKAC-protected workhorses — by registering the credential pattern, persona-to-voice mapping, and contract section in the canonical governance layer.

### Added

- **`manifests/voice-registry.yaml`** — new manifest mapping persona handles to ElevenLabs voice IDs. v1 declares `floyd` → `FKIWV9cvZ5iFxzOJPHGP`. Voice IDs are not secrets (they identify which voice, not how to authenticate); they live here for tidy lookup. The API key remains in macOS Keychain. Includes usage rules (lookup by handle only, never paste IDs into agent code), per-call character cap (5000), and Creator-plan cost governance.
- **Voice and Audio Output (TTS) section** in `contracts/agent-contract.md`. Specifies the canonical lookup pattern (resolve persona handle → voice_id via voice-registry.yaml, retrieve API key via `security find-generic-password -a legacy-ai -s elevenlabs-api-key -w`, call ElevenLabs TTS endpoint). Hard rules: voice IDs MUST be looked up by handle, never pasted; API key MUST come from Keychain — never from `.env`, source, or conversation; if a persona is unregistered, the agent MUST surface the gap to Douglas, not invent a voice_id.
- **Two `credentials-manifest.yaml` entries** (file remains untracked per governance rule):
  - `elevenlabs-api-key` — TTS scope only, $22/mo Creator plan, 100k chars/mo. Status PENDING until Douglas runs `security add-generic-password` with the actual API key.
  - `elevenlabs-floyd-voice-id` — voice identifier (not a secret). STORED in Keychain on 2026-04-26.
- **`scripts/governance-bump.sh`** — single-command deploy harness for governance bumps. Idempotent. Reads pending plan from `scripts/pending/`. Subcommands: `status`, `simulate`, `apply`, `verify`, `clean`. Authored to make future bumps mechanical and 100%-confidence-gated.

### Changed

- **`contracts/agent-contract.md`** — version banner bumped 1.4.1 → 1.5.0; new section inserted between "Where You Do NOT Write" and "Port Rules".
- **`VERSION`**, **`README.md`** — version headers bumped 1.4.1 → 1.5.0 to keep the precommit drift check happy.

### Unchanged (explicitly)

- `contracts/document-management.md`, `contracts/execution-contract.md`, `contracts/git-discipline.md`, `contracts/repo-structure.md`, `contracts/repo-hygiene.md` — untouched.
- `templates/floyd-md-template.md` — not modified. Future projects bootstrapped via `bootstrap.sh --init` will inherit the new TTS section through the universal contract reference.
- `manifests/credential-rotation-policy.yaml`, `manifests/port-allocation-policy.yaml`, `manifests/service-catalog.yaml` — untouched. (Service catalog already lists ElevenLabs at the org level; the new manifest adds operational mapping detail.)

### Migration step (post-merge)

```bash
bash /Volumes/SanDisk1Tb/.supercache/scripts/post-bump-sweep.sh --repair
```

This re-stamps every governed project's `.floyd/.supercache_version` to `1.5.0` so SessionStart drift checks pass cleanly.

**Pre-use step (Douglas only — agents cannot do this):**
```bash
security add-generic-password -a legacy-ai -s elevenlabs-api-key -w '<actual-api-key>' -U
```

Until that runs, the registry is correct but the API key entry resolves to nothing. Voice ID is already stored.

### Verification plan (post-merge)

1. `cat /Volumes/SanDisk1Tb/.supercache/VERSION` → expect `1.5.0`
2. `grep -c "Voice and Audio Output (TTS)" /Volumes/SanDisk1Tb/.supercache/contracts/agent-contract.md` → expect ≥1
3. `grep -c "FKIWV9cvZ5iFxzOJPHGP" /Volumes/SanDisk1Tb/.supercache/manifests/voice-registry.yaml` → expect ≥1
4. `security find-generic-password -a legacy-ai -s elevenlabs-floyd-voice-id -w` → expect `FKIWV9cvZ5iFxzOJPHGP`
5. `bash /Volumes/SanDisk1Tb/.supercache/scripts/governance-bump.sh verify` → exit 0
6. After Douglas adds the API key: any harness can run the canonical `curl` from voice-registry.yaml's header comment and produce audio.


## v1.4.1 — 2026-04-25

Scope: cross-harness governance compliance. Make the v1.4.0 alignment work mechanical for non-Claude-Code harnesses (OhMyFloyd via TypeScript extension, Crush-derived via wrapper-script bridge).

### Added

- **Cross-Harness Memory Bridge** section in `contracts/agent-contract.md`. Mandates that any agent finding `$FLOYD_GOVERNANCE_CONTEXT` set in its environment MUST read the referenced file before non-trivial work. Closes the "different harnesses interpret governance differently" gap by giving Crush-derived workhorses a mechanical path to the same `~/.claude/MEMORY.md` that Claude Code reads directly.
- **Companion infrastructure outside `.supercache/`** (not in this PR but documented here for the propagation record):
  - `~/.claude/MEMORY.md` — single source of truth for environment-level facts.
  - `~/.claude/hooks/session-start.sh` — Claude Code transport.
  - `~/.omp/agent/hooks/pre/governance-alignment.ts` — OhMyFloyd transport.
  - `~/.claude/hooks/floyd-harness-bootstrap.sh` — Crush-family bootstrap; sourced by harness wrapper scripts (e.g., `/opt/homebrew/bin/superfloyd`).

### Changed

- **`contracts/agent-contract.md`** — new section after "Governance Version Alignment Check" and before "Before You Start". Version bumped 1.4.0 → 1.4.1.
- **`VERSION`**, **`README.md`**, **`contracts/document-management.md`**, **`contracts/execution-contract.md`** — version headers bumped 1.4.0 → 1.4.1 to keep the precommit drift check happy. No content changes in those files.

### Unchanged (explicitly)

- `contracts/git-discipline.md`, `contracts/repo-structure.md`, `contracts/repo-hygiene.md` — untouched.
- `templates/floyd-md-template.md` — not modified in this release. Future projects bootstrapped via `bootstrap.sh --init` will get the `agent-contract.md` reference automatically; the new env-var rule applies via the universal contract, not via per-project FLOYD.md content.

### Migration step (post-merge)

Same as v1.4.0:

```bash
bash /Volumes/SanDisk1Tb/.supercache/scripts/post-bump-sweep.sh --repair
```

This re-stamps governed projects to 1.4.1 so the SessionStart drift check in Claude Code passes cleanly.

### Verification plan (post-merge)

1. `cat /Volumes/SanDisk1Tb/.supercache/VERSION` → expect `1.4.1`
2. `grep -c "Cross-Harness Memory Bridge" /Volumes/SanDisk1Tb/.supercache/contracts/agent-contract.md` → expect ≥1
3. `bash ~/.claude/hooks/session-start.sh` from a CURRENT project → memory loads, no drift notice
4. (When superfloyd is run): wrapper sources `floyd-harness-bootstrap.sh`, exports `$FLOYD_GOVERNANCE_CONTEXT`, agent reads it per the new contract section

---

## v1.4.0 — 2026-04-24

Scope: add canonical homes for agent-written reports and research; strengthen doc-management enforcement language; introduce scoped Floyd Docs governance.

### Added

- **Shared Agent Deposits tier.** Two new canonical document homes for long-form agent output, backed by Google Drive via `/Volumes/Storage/Floyd Docs/`:
  - Reports: `Reports/<YYYY-MM-DDTHH-MM>_<topic-slug>/report.md`
  - Research: `Research/<YYYY-MM-DDTHH-MM>_<topic-slug>/research.md`
  - Directories are treated as append-only historical records.
- **`/Volumes/Storage/Floyd Docs/FLOYD.md`.** New scoped governance document for the deposit folder. Invoked on request (not auto-enforced every session). Lives outside `.supercache/` (writable by Douglas directly, no PR needed for that file).
- **Governance Version Alignment Check** in `contracts/agent-contract.md`. New MANDATORY session-start step requiring every agent to compare `.floyd/.supercache_version` against canonical `.supercache/VERSION` and stop on drift. Pull-side enforcement for governance updates — makes bumps visible in the next session of each project.
- **`scripts/post-bump-sweep.sh`.** New release automation. After every supercache bump, run `bash .supercache/scripts/post-bump-sweep.sh --repair` to walk all governed projects and refresh their version stamps. `--doctor` mode (default) dry-runs; `--repair` performs updates.

### Changed

- **`contracts/document-management.md`**:
  - Version header bumped 1.3.0 → 1.4.0.
  - Canonical Document Homes table: two new rows for shared agent reports and research.
  - New section "Shared Agent Deposits Tier" after "Reference Materials Tier", modeled on that tier's structure.
  - Enforcement Posture header bumped to v1.4.0; hard-enforcement target (`bootstrap.sh --verify-docs`) deferred from v1.4.0 to v1.5.0.
- **`contracts/agent-contract.md`**:
  - Version header bumped 1.3.0 → 1.4.0.
  - New section "Governance Version Alignment Check (MANDATORY, runs first)" inserted before "Before You Start".
- **`VERSION`** bumped 1.3.0 → 1.4.0.

### Migration step (one-time, required for this release)

After merging this PR and running `git pull` in `/Volumes/SanDisk1Tb/.supercache/`, Douglas MUST run the new sweep script to stamp all governed projects at 1.4.0:

```bash
bash /Volumes/SanDisk1Tb/.supercache/scripts/post-bump-sweep.sh --repair
```

This stamps the 7 projects that currently lack a `.floyd/.supercache_version` file AND updates the 2 already-stamped projects from 1.3.0 to 1.4.0. Projects identified as unstamped on 2026-04-24:

- `/Volumes/SanDisk1Tb/` (drive root governed project)
- `/Volumes/Storage/floyd/`
- `/Volumes/Storage/Gordy/`
- `/Volumes/Storage/PSI/`
- `/Volumes/Storage/Floyd Docs/`
- `/Volumes/Storage/Floyd_OpenFloyd/`
- `/Volumes/Storage/LegacyAINexus/`

Already-stamped at 1.3.0 (will bump to 1.4.0 via the same sweep):

- `/Volumes/Storage/LegacySiteTest/`
- `/Volumes/Storage/harness-launcher/`

Without this step, agents entering bootstrapped projects after the merge will hit the new Alignment Check and stop on drift until the stamp is repaired manually per-project.

### Unchanged (explicitly)

- Enforcement remains **advisory** for `document-management.md`. No new code-level pattern scanner in this release.
- `contracts/execution-contract.md` — untouched.
- `contracts/git-discipline.md` — untouched.
- `contracts/repo-structure.md` — untouched.
- `contracts/repo-hygiene.md` — untouched.
- Canonical `.supercache/` location — still `/Volumes/SanDisk1Tb/.supercache/` with `/Volumes/Storage/.supercache/` as symlink.
- Retired supercache at `~/Library/CloudStorage/GoogleDrive-douglastalley1977@gmail.com/My Drive/Floyd_Ecosystem/supercache.retired-20260415/` — left in place as archival; confirmed unused (VERSION 1.2.0, unmodified since 2026-04-15, zero references anywhere on disk).

### Propagation plan

1. **Supercache canonical** (`/Volumes/SanDisk1Tb/.supercache/`) — updated via `git pull` after PR merges.
2. **Supercache symlink** (`/Volumes/Storage/.supercache/`) — auto-updates (symlink).
3. **GitHub** (`LegacyAI-FloydsLabs/supercache`) — PR merged.
4. **Downstream bootstrapped projects** — retro-stamp the 7 unstamped projects as part of this release (see Migration step); thereafter, the new Alignment Check enforces drift detection on every session. Release sweep via `scripts/post-bump-sweep.sh --repair` is the recommended cadence.

### Rationale

The previous governance had no canonical home for agent-written reports and research. Agents defaulted to `~/Documents/` (user-owned) or repo roots (clutter). The new tier gives cross-device, cloud-backed storage that survives drive changes and stays out of individual repos. Scoping it to Floyd Docs (via a dedicated FLOYD.md) rather than baking rules into every repo's governance prevents scope bloat.

### Verification plan (post-merge)

1. `cat /Volumes/SanDisk1Tb/.supercache/VERSION` → expect `1.4.0`
2. `grep -c "Shared Agent Deposits" /Volumes/SanDisk1Tb/.supercache/contracts/document-management.md` → expect ≥1
3. `ls /Volumes/Storage/Floyd\ Docs/FLOYD.md` → expect present
4. Floyd Docs `Reports/` and `Research/` subdirectories remain usable and unchanged.

---

## v1.3.0 — (prior)

No prior changelog entry exists in the repo; history before 1.4.0 lives in `~/Documents/governance-migration-2026-04-15.md` and commit history.
