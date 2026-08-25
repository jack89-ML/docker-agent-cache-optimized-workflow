# Test 2 — FocusPulse Android (native) · deepseek-v4-pro + qwen3.8-max delegation

**Status: PASSED** · Date: 2026-08-24 · ~26 min · 0 interventions during build, 1 evaluation pass after

## Overview

FocusPulse native Android version (Kotlin + Jetpack Compose): the same
Pomodoro logic as the PWA, but as an installable APK. The project for this
test: exercise delegation to a second model (qwen3.8-max) under a
deepseek-v4-pro orchestrator, with a $1.50 budget. The app was designed as:
timer with presets, sound settings, installable on a Samsung A137F. The
result, stated plainly: it works, but the UI came out basic. Sound was
missing and the +/- buttons for minutes were buggy; both were fixed in the
post-run evaluation round.

## Setup

| Item | Value |
|---|---|
| Container | `agent-focuspulse` (nousresearch/hermes-agent) |
| Model | deepseek-v4-pro (official API) + delegation configured to qwen3.8-max (provider alibaba) |
| Context | CONTEXT / MASTER_PLAN / TASK_LIST / AGENT_PROMPT (4 files) |
| Task | FocusPulse: native Android app (Kotlin + Jetpack Compose) |
| Verification | 4/4 sprints · aapt dump badging PASS · APK install PASS · launch + zero crash PASS |

## Cost summary

| Metric | Value |
|---|---|
| Cache-hit | **98.5%** — 5,141,888 cache-read / (5,141,888 + 77,634 miss) |
| Planned budget | $1.50 |
| Actual cost | $0.147 (recorded) |
| Budget used | 10% |
| No-cache counterfactual | ~$2.39 |
| Effective saving | ~94% |
| API calls | 67 |
| Input (miss) / output | 77,634 / 109,198 |
| Cache-read | 5,141,888 |

## Agent behavior

- Same rigor as Test 1: context files in order, STATUS files with
  accumulated cost, real verification at every sprint (gradle build, unit
  tests).
- The part that needs no dressing up: delegation to qwen3.8-max was
  configured but blocked by a framework bug (sqlite WAL corruption in
  `async_delegation.py`, upstream issues #55305/#71498). Not a skill
  failure: the agent documented the block, saved a memory note to skip
  re-diagnosis, and implemented the design directly with DeepSeek.
  Delegation was never exercised.

## Post-run fixes

Two defects surfaced in the evaluation pass:

1. +/- buttons: `coerceAtLeast(1)` applied only the minimum, never the
   maximum, so the value could exceed the limit and disable the buttons
   incoherently. Replaced with `coerceIn(1,180)`, `coerceIn(1,60)`,
   `coerceIn(1,60)`, `coerceIn(1,12)`. Rebuild: BUILD SUCCESSFUL.
2. Sound: it existed only in the notification (`setSound`), which does not
   fire when the app is in foreground. Added a `ToneGenerator` double-beep
   in `MainViewModel.onPhaseCompleted`, gated by the existing Sound
   setting.
3. Reinstalled on the Samsung A137F: Success, app in foreground, zero crash.

## Scores

| Dimension | Score |
|---|---|
| Autonomy (0 interventions during build) | 9/10 |
| Cost efficiency (10% of budget) | 10/10 |
| Cache strategy (98.5%, ~94% saving) | 9.5/10 |
| Output quality (functional, basic UI) | 7/10 |
| Process fidelity (order, status files, honest blocker reporting) | 9.5/10 |
| **Overall** | **9.0/10** |

## Limitations

- Delegation to a second model was not exercised: the framework WAL bug
  blocked it. A run on a fixed framework is the natural follow-up.
- UI is functional but basic. A design pass via direct Qwen API call
  (bypassing the WAL bug) is the recommended next step.
- No automated screenshot grading; visual QA on the device was manual.
