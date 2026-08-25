# Validation Test 1 — FocusPulse PWA (Windows 11)

**Status: PASSED** · Date: 2026-08-24 · Total wall time: ~21 min (active: ~15 min)

## Setup under test

| Item | Value |
|---|---|
| Skill under test | `docker-agent-cache-optimized-workflow` v1.1.0 |
| Agent container | `agent-pomodoro` (nousresearch/hermes-agent, non-root uid 10000) |
| Model | deepseek-v4-pro (official API) — single model, **no delegation** |
| Context files | CONTEXT / MASTER_PLAN / TASK_LIST / AGENT_PROMPT (4 files, one role each) |
| Task | FocusPulse: installable Pomodoro PWA for Windows 11 (Edge/Chrome) |
| Budget | $0.60 max |
| Human interventions | **0** (fully autonomous run) |

## Metrics (measured, independently re-verified)

| Metric | Value | Target | Verdict |
|---|---|---|---|
| API calls | 35 | — | — |
| Input tokens (miss) | 72,987 | — | — |
| Output tokens | 74,529 | — | — |
| Cache-read tokens | 2,527,744 | — | — |
| Cache-hit ratio | **97.2%** | ≥90% | ✅ |
| Cost (recorded est) | $0.105 | — | — |
| Cost (real, legacy tier) | ~$0.11 | — | — |
| Budget used | 18% | ≤100% | ✅ |
| Tasks completed | 24/24 | all | ✅ |
| Smoke tests | 28/28 PASS (re-run independently) | all | ✅ |
| Cost without cache (counterfactual) | ~$1.16 | — | cache saved ~90% |

## Agent behavior (from session logs + workspace artifacts)

- Read the context files in the mandated order: CONTEXT → MASTER_PLAN → TASK_LIST → AGENT_PROMPT
- Wrote STATUS_SPRINT1..4.md, each with accumulated cost reported
- Executed all 4 sprints sequentially with real verification (node smoke tests, curl, manifest JSON validation, installability criteria check)
- Found and fixed a real bug during testing (`setBreakType` not updating live state), documented in the final status
- Self-improvement: created the `headless-frontend-verification` skill inside its own container
- Guardrails respected: no destructive commands, no fabricated data, server left running and verified (HTTP 200)
- Delegation: **none** — single model, zero subagent sessions (verified in state.db: 0 sessions with parent)

## Output quality

- Functional verification (browser): timer start/pause/reset/skip, countdown accuracy, presets 25/5 and 50/10, custom durations, sound toggle, dark/light theme, keyboard shortcuts, "last 7 days" chart, manifest + service worker, inline SVG icon
- Installability criteria met (Chromium): name, icons incl. ≥192px, start_url, `display: standalone`, theme_color
- User assessment on Windows 11: **"UI molto performante e davvero ottima. Nessun bug"**
- Note: the deliverable is an installable PWA (per the spec), not a native Windows app — the next test targets a native app

## Grade

| Dimension | Score |
|---|---|
| Autonomy (0 interventions, self-verification) | 9.5/10 |
| Cost efficiency (18% of budget) | 10/10 |
| Cache strategy (97.2% hit, ~90% saving) | 9.5/10 |
| Output quality (user-verified, no bugs) | 9/10 |
| Process fidelity (order, status files, guardrails) | 9.5/10 |
| **Overall** | **9.3/10** |

## Limitations / next steps

- Web app, not native (spec said PWA; user expectation was native) → Test 2: native app
- Single-model run (no delegation exercised) → Test 2: exercise delegation to a second model
- Visual QA by human (user) on Windows 11; no automated screenshot grading

# Validation Test 2 — FocusPulse Android (native app)

**Status: PASSED** · Date: 2026-08-24 · Wall time: ~26 min (4 sprints, fully autonomous)

## Setup under test

| Item | Value |
|---|---|
| Skill under test | `docker-agent-cache-optimized-workflow` v1.1.0 |
| Agent container | `agent-focuspulse` (nousresearch/hermes-agent) |
| Model | deepseek-v4-pro (official API) + **delegation configured** to qwen3.8-max (provider alibaba) |
| Context files | CONTEXT / MASTER_PLAN / TASK_LIST / AGENT_PROMPT (4 files, one role each) |
| Task | FocusPulse: native Android Pomodoro app (Kotlin + Jetpack Compose) |
| Budget | $1.50 max |
| Human interventions | 0 during build; 1 evaluation pass afterward (bug fixes, see below) |

## Metrics (measured, independently re-verified)

| Metric | Value | Target | Verdict |
|---|---|---|---|
| API calls | 67 | — | — |
| Input tokens (miss) | 77,634 | — | — |
| Output tokens | 109,198 | — | — |
| Cache-read tokens | 5,141,888 | — | — |
| Cache-hit ratio | **98.5%** | ≥90% | ✅ |
| Cost (recorded est) | $0.147 | — | — |
| Budget used | 10% | ≤100% | ✅ |
| Tasks completed | 4/4 sprints | all | ✅ |
| aapt dump badging | PASS (minSdk 26, targetSdk 35, correct permissions) | — | ✅ |
| APK install on device | PASS (Samsung A137F via adb wireless) | — | ✅ |
| App launch + foreground | PASS (MainActivity, process alive, zero crash) | — | ✅ |
| Cost without cache (counterfactual) | ~$2.39 | — | cache saved ~94% |

## Agent behavior (from session logs + workspace artifacts)

- Read context files in mandated order (CONTEXT → MASTER_PLAN → TASK_LIST → AGENT_PROMPT)
- Wrote STATUS_SPRINT1..4.md, each with accumulated cost reported
- Executed all 4 sprints with real verification (gradle build, unit tests)
- **Delegation attempted to qwen3.8-max but blocked by a framework bug** (sqlite WAL
  corruption under concurrent connections in `async_delegation.py`, upstream issues
  #55305/#71498) — NOT a skill failure; agent documented the block, saved a memory
  note to skip re-diagnosis, and implemented the design directly with DeepSeek
- Guardrails respected: no destructive commands, no fabricated output, honest blocker reporting

## Post-run fixes (user evaluation round)

User assessment: *"App funzionante. Molto BASIC questa volta. Nessun suono, bug nei bottoni
+/- per incrementare minuti. Però BASIC ma funzionale."* → two fixes applied:

1. **+/- buttons bug**: `coerceAtLeast(1)` applied only the min, never the max → value
   could exceed the limit and disable buttons incoherently. Fixed with `coerceIn(1,180)`,
   `coerceIn(1,60)`, `coerceIn(1,60)`, `coerceIn(1,12)`. Rebuild: BUILD SUCCESSFUL.
2. **No sound**: sound existed only in the notification (`setSound`), which does not fire
   when the app is in foreground. Added `ToneGenerator` double-beep in
   `MainViewModel.onPhaseCompleted`, gated by the existing Sound setting.
3. Reinstalled on Samsung A137F: Success, app in foreground, zero crash.

## Grade

| Dimension | Score |
|---|---|
| Autonomy (0 interventions during build) | 9/10 |
| Cost efficiency (10% of budget) | 10/10 |
| Cache strategy (98.5% hit, ~94% saving) | 9.5/10 |
| Output quality (functional, basic UI; user-verified) | 7/10 |
| Process fidelity (order, status files, honest blocker reporting) | 9.5/10 |
| **Overall** | **9.0/10** |

## Limitations / next steps

- Delegation to a second model was configured but not exercised (framework WAL bug,
  upstream #55305/#71498) — a future run on a fixed framework can validate the delegation path
- UI is functional but basic (user feedback) — a Qwen design pass via direct API call
  (bypassing the WAL bug) is the recommended follow-up
- No automated screenshot grading; visual QA by human on the device

# Validation Test 3 — FocusPulse PWA with Qwen3.8-Max

**Status: PASSED** · Date: 2026-08-25 · Fully autonomous run

Test 1 built the FocusPulse PWA with deepseek-v4-pro. This run swaps the
primary model: qwen3.8-max (QwenCloud/DashScope, billing provider alibaba)
inside the agent container, no delegation. The app was left running and
re-verified after the run: `http://192.168.1.187:8000/` returns 200 and
`/api/stats` returns live session data (2 sessions today, streak 1,
week total 2).

## Setup under test

| Item | Value |
|---|---|
| Skill under test | `docker-agent-cache-optimized-workflow` |
| Agent container | `agent-qwen-test` (nousresearch/hermes-agent) |
| Model | qwen3.8-max (QwenCloud/DashScope), primary, no delegation |
| Context files | CONTEXT / MASTER_PLAN / TASK_LIST / AGENT_PROMPT (4 files, one role each) |
| Task | FocusPulse: Pomodoro PWA (FastAPI backend, vanilla JS timer, charts, settings) |
| Budget | $10.00 hard cap |
| Human interventions | 0 |
| Deliverable URL | http://192.168.1.187:8000/ |

## Metrics (measured, independently re-verified)

| Metric | Value | Target | Verdict |
|---|---|---|---|
| Tasks completed | 10/10 (T0-T9) | all | ✅ |
| pytest | 14 passed (10 API + 4 smoke) | all | ✅ |
| JS unit tests (timer state machine) | 10 passed | all | ✅ |
| Live endpoints | `/`, 4 assets, health, `/api/stats` all HTTP 200 | all | ✅ |
| Visual verification | Playwright headless, 5 screenshots, zero JS errors | — | ✅ |
| Cache-hit ratio | **99.99%** (from state.db) | ≥90% | ✅ |
| Budget used (estimated) | ~14% | ≤100% | ✅ |

## Telemetry from the agent's own state.db (measured, not estimated)

The numbers below were read directly from the container's Hermes session
database (`session_model_usage`, billing provider alibaba) after the run:

| Token bucket | Value |
|---|---|
| Cache-read | 4,120,902 |
| Cache-write | 419,454 |
| Input (miss) | 558 |
| Output | 64,479 |

Cache-hit ratio = 4,120,902 / (4,120,902 + 558) = **99.986%**.

Cost note: the DB did not finalize a cost figure for this run
(`estimated_cost_usd` = 0, `cost_status` = unknown), so the cost below is
computed from Qwen3.8-Max list prices ($2/M input miss, $6/M output,
$0.25/M cache-read): roughly **$1.42**, of which $1.03 is cache-read and
$0.39 is output. The agent's own in-run estimate (~21% cache-hit, ~$0.63)
was wrong on both counts: it had no access to provider telemetry and
guessed the cache reuse rate. The DB shows the stable-prefix strategy
performed at the same level as the DeepSeek runs (97-99%).

## Bugs found and fixed during the run

Caught by the browser verification step, which pytest could not see:

1. `index.html` did not load `timer.js` (`FocusPulseTimer is not defined`),
   the app was completely dead. Fixed by adding the script tag.
2. A global `*{margin:0}` reset killed the auto margins on the native
   `<dialog>`, leaving the settings dialog stuck in the top-left corner.
   Fixed with `margin:auto` on the dialog class.

## What did not go smoothly

- The container had restarted before the session, so the previous workspace
  was gone; the agent rebuilt everything from scratch in a new directory.
- 5 of 6 UI skill symlinks were broken in the container (they pointed to a
  non-existent directory). The agent reported this honestly and used the one
  skill that loaded (`popular-web-designs`, Linear template) for the design.
- No system Chrome was available and `playwright install chromium` failed
  (slow download, `--with-deps` needs root). The agent found a headless-shell
  already present on the image matching its Playwright version, which made
  real visual verification possible.

## Grade

| Dimension | Score |
|---|---|
| Autonomy (0 interventions, self-verification) | 9.5/10 |
| Cost efficiency (~14% of budget, estimated) | 9/10 |
| Cache strategy (99.99% hit, measured from state.db) | 10/10 |
| Output quality (functional app, browser-verified, 2 real bugs caught and fixed) | 9/10 |
| Process fidelity (status files, honest blocker reporting, no fabrication) | 9.5/10 |
| **Overall** | **9.4/10** |

## What this means for the workflow

- Qwen3.8-Max is a viable primary model for the container setup. It holds
  the same autonomy, verification and cost profile as deepseek-v4-pro on the
  same app.
- The cache-hit strategy is not model-specific: with a stable prefix and
  files-first output discipline, this run hit 99.99% cache-read exactly like
  the DeepSeek runs.
- The agent's own cost estimates should be treated as rough. The state.db
  telemetry is the source of truth for cache ratios; cost figures still need
  list-price math until the DB finalizes billing for third-party providers.

## Limitations / next steps

- Cost is estimated from list prices; the DB left `cost_status` unknown for
  this provider, so the exact billed amount is unverified.
- Single model, no delegation: the delegation path was blocked in Test 2 by
  an upstream framework bug (sqlite WAL corruption, issues #55305/#71498).
  A run with a Qwen worker under a DeepSeek orchestrator is the natural
  follow-up once that is fixed.
- No automated screenshot grading; visual checks were read by the agent from
  its own Playwright output.
