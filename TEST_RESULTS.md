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
