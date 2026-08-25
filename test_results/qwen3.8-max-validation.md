# Validation Test 3 — Qwen3.8-Max as the primary agent model

**Status: PASSED** · Date: 2026-08-25 · Two runs, both fully autonomous

Tests 1 and 2 validated the workflow with deepseek-v4-pro as the primary model.
This test answers a different question: does the same setup hold up when the
agent container runs Qwen3.8-Max (QwenCloud/DashScope) as the primary model,
with no delegation to a second model?

Two runs were executed on the same container image:

1. A focused cache-hit benchmark (homogeneous tasks, stable prefix).
2. A full end-to-end app build (FocusPulse, a Pomodoro PWA with backend,
   frontend, tests and visual verification).

---

## Run 1 — Cache-hit benchmark

**Status: PASSED** · Homogeneous task set

| Item | Value |
|---|---|
| Agent container | `agent-qwen-test` (nousresearch/hermes-agent) |
| Model | qwen3.8-max (QwenCloud/DashScope), primary, no delegation |
| Context files | CONTEXT / MASTER_PLAN / TASK_LIST / AGENT_PROMPT |
| Tasks | 7/7 completed |
| Automated tests | 8/8 PASS |
| Cache-hit ratio | **99.5%** of input tokens |
| Real cost | **$0.43** |
| Counterfactual without cache discipline | ~$1.78 |
| Saving vs counterfactual | **~76%** |

What this run shows: with a stable system prefix and homogeneous tasks, the
cache-hit rate reaches the same territory as the DeepSeek runs (97-99%).
The cost structure is the same as we saw in tests 1 and 2: the input side
shrinks to almost nothing, and the remaining cost is dominated by output tokens.

---

## Run 2 — FocusPulse end-to-end app build

**Status: PASSED** · Date: 2026-08-25 · 10/10 tasks verified

| Item | Value |
|---|---|
| Agent container | `agent-qwen-test` (nousresearch/hermes-agent) |
| Model | qwen3.8-max (QwenCloud/DashScope), primary, no delegation |
| Task | FocusPulse: Pomodoro PWA (FastAPI backend, vanilla JS timer, charts, settings) |
| Budget | $10.00 hard cap |
| Human interventions | 0 |
| Tasks completed | 10/10 (T0-T9) |
| pytest | 14 passed (10 API + 4 smoke) |
| JS unit tests | 10 passed (timer state machine) |
| Live verification | server on :8000; `/`, 4 assets, health, stats all HTTP 200 |
| Visual verification | Playwright headless, 5 screenshots (desktop, running countdown, mode themes, settings, mobile 390px), zero JS errors |
| Real cost (estimated) | **~$0.63** (6% of budget) |
| Cache-hit ratio | ~21% of input tokens |

The cache number needs context, because it is the honest part of this run.
The container had restarted before the session, so the prompt cache from the
previous run was gone and the stable prefix only covered part of the input.
Cache discipline was applied from the start of the session, but the reuse rate
stayed low. The interesting thing: cost stayed at $0.63 anyway.

Why. Input tokens were roughly 280K total. At miss prices that alone would be
$0.56, and with the partial cache it was $0.455 (a 19% saving on the input
side, not the 70-90% we see with a warm cache). The dominant lever was
something else: output tokens. The agent wrote code to files with its tools
instead of pasting it into chat, which kept output at ~30K tokens. Without
that discipline, the same work typically lands at 120K+ tokens of output, or
roughly $0.54 of extra cost. In other words, on a cold cache the output
discipline alone did more for the bill than the cache did.

## Bugs found and fixed during Run 2

These were caught by the browser verification step, which pytest could not
have seen:

1. `index.html` did not load `timer.js`, so the app was completely dead
   (`FocusPulseTimer is not defined`). Fixed by adding the script tag.
2. A global `*{margin:0}` reset killed the auto margins on the native
   `<dialog>`, leaving the settings dialog stuck in the top-left corner.
   Fixed with `margin:auto` on the dialog class.

## What did not go smoothly

- The previous workspace was wiped by the container restart. The agent
  rebuilt everything from scratch in a new directory, as instructed.
- 5 of 6 UI skill symlinks were broken in the container (they pointed to a
  non-existent directory). The agent reported this honestly and applied the
  anti-slop principles from general knowledge instead. The one skill that was
  loadable (`popular-web-designs`, Linear template) drove the visual design.
- No system Chrome was available and `playwright install chromium` failed
  (slow download, `--with-deps` needs root). The agent found a headless-shell
  already present on the image that matched its Playwright version, which
  made real visual verification possible.

## Grade

| Dimension | Score |
|---|---|
| Autonomy (0 interventions, self-verification) | 9.5/10 |
| Cost efficiency (6% of budget, cold cache) | 9.5/10 |
| Cache strategy (99.5% warm / 21% cold) | 8/10 |
| Output quality (functional app, browser-verified, 2 real bugs caught and fixed) | 9/10 |
| Process fidelity (status files, honest blocker reporting, no fabrication) | 9.5/10 |
| **Overall** | **9.1/10** |

## What this means for the workflow

- Qwen3.8-Max is a viable primary model for the container setup. It holds the
  same autonomy, verification and cost profile as deepseek-v4-pro on this
  workload.
- The cache-hit strategy works best with a warm cache, but the workflow does
  not collapse without one. The output discipline ("write to files, never
  paste code into chat") is the lever that keeps costs low in both cases.
- A cold start after a container restart is the worst case worth planning
  for; the workflow absorbs it, it just does not get the headline cache
  numbers.

## Limitations / next steps

- Cache-hit % in Run 2 was measured from the agent's own estimate, not from
  provider billing data. A run with provider-side usage logs would pin the
  exact figure.
- Single model, no delegation: the delegation path to a second model was
  configured in Test 2 but blocked by an upstream framework bug (sqlite WAL
  corruption, issues #55305/#71498). Once that is fixed, a run with a Qwen
  worker under a DeepSeek orchestrator would be the natural follow-up.
- No automated screenshot grading; visual checks were read by the agent from
  its own Playwright output.
