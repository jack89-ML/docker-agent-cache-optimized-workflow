# Test 3 — FocusPulse PWA · qwen3.8-max

**Status: PASSED** · Date: 2026-08-25 · Fully autonomous run · 0 human interventions

## Overview

Same app as Test 1 (FocusPulse PWA), same container workflow, different
primary model: qwen3.8-max (QwenCloud/DashScope, provider alibaba). The
project for this test: verify that the cache-first strategy holds when the
model changes, with costs read from the real telemetry database instead of
the agent's estimates. The app was designed as in the first version: dark
Pomodoro timer inspired by Linear, one accent color per mode (indigo for
focus, emerald for short break, sky for long break), glowing progress ring,
native dialog for settings, 7-day bar chart. The server is still up and
answering: the app lives at `http://192.168.1.187:8000/`.

## Setup

| Item | Value |
|---|---|
| Container | `agent-qwen-test` (nousresearch/hermes-agent) |
| Model | qwen3.8-max (QwenCloud/DashScope), primary, no delegation |
| Context | CONTEXT / MASTER_PLAN / TASK_LIST / AGENT_PROMPT (4 files) |
| Task | FocusPulse: Pomodoro PWA (FastAPI backend, vanilla JS timer, charts, settings) |
| Verification | 10/10 tasks · 14 pytest (10 API + 4 smoke) · 10 JS timer tests · all endpoints 200 |

## Cost summary

Data read from the container's `state.db` (`session_model_usage`, provider
alibaba) after the run. Measured, not estimated.

| Metric | Value |
|---|---|
| Cache-hit | **99.99%** — 4,120,902 cache-read / (4,120,902 + 558 miss) |
| Planned budget | $10.00 |
| Actual cost | ~$1.42 estimated at list prices (DB not finalized: `cost_status` unknown) |
| Budget used | ~14% |
| No-cache counterfactual | ~$8.63 (4,121,460 miss × $2/M + output) |
| Effective saving | ~84% |
| API calls | 92 (28 + 64) |
| Input (miss) / output | 558 / 64,479 |
| Cache-read / cache-write | 4,120,902 / 419,454 |

The awkward part, stated plainly: the agent's own in-run report estimated
~21% cache-hit and ~$0.63 cost. Both were wrong. It has no access to
provider telemetry and guessed the prefix reuse rate. The measured data
says 99.99% cache-hit and ~$1.42 estimated cost. The stable-prefix strategy
performed with qwen3.8-max exactly as it did with deepseek.

## Verification

- Live endpoints: `/`, 4 assets, health, `/api/stats` all HTTP 200.
- Playwright headless, 5 screenshots (desktop, running countdown, mode
  themes, settings, mobile 390px), zero JS errors.

## Agent behavior

- Context files in order, STATUS files with accumulated cost, real
  verification at every task (curl, pytest, Node unit tests).
- Used the one loadable UI skill (`popular-web-designs`, Linear template)
  and reported honestly that the other 5 were broken symlinks in the
  container (pointing to a non-existent directory), applying their
  anti-slop principles from general knowledge instead.
- No system Chrome and `playwright install chromium` failed: found a
  headless-shell already present on the image, matching its Playwright
  version, which made real visual verification possible.

## Bugs

Caught by the browser verification step, which pytest could not see:

1. `index.html` did not load `timer.js` (`FocusPulseTimer is not defined`):
   the app was completely dead. Fixed by adding the script tag.
2. The global `*{margin:0}` reset killed the auto margins on the native
   `<dialog>`, leaving the settings dialog stuck in the top-left corner.
   Fixed with `margin:auto` on the dialog class.

## Scores

| Dimension | Score |
|---|---|
| Autonomy (0 interventions, self-verification) | 9.5/10 |
| Cost efficiency (~14% of budget, estimated) | 9/10 |
| Cache strategy (99.99% measured from state.db) | 10/10 |
| Output quality (functional app, browser-verified, 2 real bugs caught and fixed) | 9/10 |
| Process fidelity (status files, honest blocker reporting, no fabrication) | 9.5/10 |
| **Overall** | **9.4/10** |

## Limitations

- Cost is estimated from list prices: the DB left `cost_status` unknown for
  this provider, so the exact billed amount is unverified.
- Agent cost estimates should be treated as rough. The state.db telemetry is
  the source of truth for cache ratios; costs need list-price math until the
  DB finalizes billing for third-party providers.
- Single model, no delegation: the delegation path was blocked by the
  upstream sqlite WAL bug (#55305/#71498), already seen in Test 2. A run
  with a Qwen worker under a DeepSeek orchestrator is the natural follow-up.
- No automated screenshot grading.
