# Test 1 — FocusPulse PWA · deepseek-v4-pro

**Status: PASSED** · Date: 2026-08-24 · ~21 min wall time (15 active) · 0 human interventions

## Overview

FocusPulse is the Pomodoro web app used to validate the workflow: a 25/5/15
timer (focus, short break, long break), 7-day statistics, sound, dark/light
theme, installable as a PWA. The project for this test: full app build inside
an autonomous agent container, with a hard budget and real verification
(tests, browser, installability) instead of trust. The app was designed to be
quick to use from keyboard and screen: 25/5 and 50/10 presets, custom
durations, shortcuts, a 7-day bar chart, inline SVG icon. Nothing more. The
first run produced it with deepseek-v4-pro alone, no delegation to a second
model.

## Setup

| Item | Value |
|---|---|
| Container | `agent-pomodoro` (nousresearch/hermes-agent, non-root uid 10000) |
| Model | deepseek-v4-pro (official API), single, no delegation |
| Context | CONTEXT / MASTER_PLAN / TASK_LIST / AGENT_PROMPT (4 files) |
| Task | FocusPulse: installable Pomodoro PWA for Windows 11 |
| Verification | 24/24 tasks · 28/28 smoke tests (re-run independently) |

## Cost summary

| Metric | Value |
|---|---|
| Cache-hit | **97.2%** — 2,527,744 cache-read / (2,527,744 + 72,987 miss) |
| Planned budget | $0.60 |
| Actual cost | ~$0.11 (recorded $0.105, legacy pricing tier) |
| Budget used | 18% |
| No-cache counterfactual | ~$1.16 |
| Effective saving | ~90% |
| API calls | 35 |
| Input (miss) / output | 72,987 / 74,529 |
| Cache-read | 2,527,744 |

## Verification

Browser check of the running app: start/pause/reset/skip, countdown
accuracy, 25/5 and 50/10 presets, custom durations, sound toggle,
dark/light theme, keyboard shortcuts, 7-day chart, manifest + service
worker, inline SVG icon. Installability criteria met on Chromium. The UI on
Windows 11 was responsive and bug-free.

## Agent behavior

- Read the context files in the mandated order and wrote STATUS_SPRINT1..4,
  each with accumulated cost.
- Executed all 4 sprints sequentially with real verification (Node smoke
  tests, curl, manifest JSON validation, installability criteria check).
- Found and fixed a real bug during testing (`setBreakType` not updating
  live state).
- Created a `headless-frontend-verification` skill inside its own container.
- Guardrails respected: no destructive commands, no fabricated data, server
  left running and verified (HTTP 200).

## Bugs

One real bug found and fixed during the run: `setBreakType` did not update
the live state. Caught by the agent's own testing, before delivery.

## Scores

| Dimension | Score |
|---|---|
| Autonomy (0 interventions, self-verification) | 9.5/10 |
| Cost efficiency (18% of budget) | 10/10 |
| Cache strategy (97.2%, ~90% saving) | 9.5/10 |
| Output quality (verified, bug-free) | 9/10 |
| Process fidelity (order, status files, guardrails) | 9.5/10 |
| **Overall** | **9.3/10** |

## Limitations

- The deliverable is a PWA, not a native app: the spec said PWA, but the
  goal was a native build. This is why Test 2 exists.
- Single model, no delegation exercised.
- Visual QA was manual, no automated screenshot grading.
