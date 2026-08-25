# Validation Test 3 — FocusPulse PWA with Qwen3.8-Max

**Status: PASSED** · Date: 2026-08-25 · Fully autonomous run

Test 1 in TEST_RESULTS.md built the FocusPulse PWA with deepseek-v4-pro.
This run builds the same app with a different primary model: qwen3.8-max
(QwenCloud/DashScope) running in the agent container, no delegation.

The app is live on `http://192.168.1.187:8000/` and was re-verified after
the run: `/` returns 200, and `/api/stats` returns real session data
(today 2 sessions, streak 1, week total 2).

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
| Real cost (estimated) | ~$0.63 | ≤$10 | ✅ (6% of budget) |
| Cache-hit ratio | ~21% of input tokens | — | cold cache (see below) |

## Design direction

Dark-native, Linear-inspired (from the `popular-web-designs` skill template).
Near-black canvas, surfaces built on luminance steps instead of solid blocks,
whisper-thin translucent borders, tabular-nums for the countdown. One accent
color per session mode: indigo for focus, emerald for short break, sky blue
for long break, switched via `body[data-mode]` CSS custom properties. SVG
progress ring with glow, native `<dialog>` for settings, 7-day bar chart,
4-pomodoro cycle dot.

## Agent behavior

- Read the context files in the mandated order, wrote STATUS files with
  accumulated cost, executed all tasks with real verification (curl, pytest,
  Node unit tests).
- Used the one loadable UI skill (`popular-web-designs`) and reported
  honestly that the other 5 UI skills were broken symlinks in the container
  (they pointed to a directory that does not exist), applying their
  anti-slop principles from general knowledge instead.
- Found a headless-shell already present on the image when `playwright
  install chromium` failed, which made real visual verification possible.

## Bugs found and fixed during the run

Caught by the browser verification step, which pytest could not see:

1. `index.html` did not load `timer.js` (`FocusPulseTimer is not defined`),
   the app was completely dead. Fixed by adding the script tag.
2. A global `*{margin:0}` reset killed the auto margins on the native
   `<dialog>`, leaving the settings dialog stuck in the top-left corner.
   Fixed with `margin:auto` on the dialog class.

## The cost picture, honestly

The cache-hit ratio was ~21%, well below the 97-99% of the warm-cache runs.
The reason is mundane: the container had restarted before this session, so
the prompt cache from the previous run was gone. The cost still landed at
~$0.63. Two things made that possible:

- The agent wrote code to files with its tools instead of pasting it into
  chat. Output stayed at ~30K tokens; without that discipline the same work
  typically costs 120K+ tokens of output, roughly $0.54 extra at Qwen output
  prices. On a cold cache this single habit did more for the bill than the
  cache itself.
- Input stayed small: ~280K tokens total, $0.56 at miss prices, $0.455 with
  the partial cache.

## Grade

| Dimension | Score |
|---|---|
| Autonomy (0 interventions, self-verification) | 9.5/10 |
| Cost efficiency (6% of budget, cold cache) | 9.5/10 |
| Cache strategy (cold cache, partial reuse) | 8/10 |
| Output quality (functional app, browser-verified, 2 real bugs caught and fixed) | 9/10 |
| Process fidelity (status files, honest blocker reporting, no fabrication) | 9.5/10 |
| **Overall** | **9.1/10** |

## What this means for the workflow

- Qwen3.8-Max is a viable primary model for the container setup. It held the
  same autonomy, verification and cost profile as deepseek-v4-pro on the
  same app.
- The workflow does not collapse on a cold cache. The output discipline
  ("write to files, never paste code into chat") is the lever that keeps
  costs low in both cases.
- A cold start after a container restart is the worst case worth planning
  for; the workflow absorbs it, it just does not get the headline cache
  numbers.

## Limitations / next steps

- Cache-hit % is the agent's own estimate, not provider billing data.
- Single model, no delegation: the delegation path was blocked in Test 2 by
  an upstream framework bug (sqlite WAL corruption, issues #55305/#71498).
  A run with a Qwen worker under a DeepSeek orchestrator is the natural
  follow-up once that is fixed.
- No automated screenshot grading; visual checks were read by the agent from
  its own Playwright output.
