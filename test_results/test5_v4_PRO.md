# Test 5 — Same literature review with /goal mode · deepseek-v4-pro

**Status: PASSED** · Date: 2026-08-25 · ~23 min · 0 human interventions

## Overview

Same task as Test 4 (academic literature review on Human Terrain Systems),
same container, same model. The only intended difference: the session was
started with the `/goal <text>` mode (goal set to the research task, then
the full agent prompt injected as the working message), instead of the
plain prompt used in Test 4. The purpose of the run is to measure whether
the goal mode changes the agent's working behavior, output breadth, cost
and cache behavior. The deliverables were written to a separate workspace
so the two runs can be compared without overwriting.

## Setup

| Item | Value |
|---|---|
| Container | `agent-research-test` (nousresearch/hermes-agent) |
| Model | deepseek-v4-pro (official API), single, no delegation |
| Context | CONTEXT / MASTER_PLAN / TASK_LIST / AGENT_PROMPT (4 files) + `/goal` at session start |
| Task | Academic literature review on HTS (identical to Test 4) |
| Budget | $3.00 hard cap |
| Workspace | separate (`hts-goal`) to keep Test 4 deliverables intact |

## Cost summary

| Metric | Value |
|---|---|
| Cache-hit | **98.9%** — 5,182,208 cache-read / (5,182,208 + 60,068 miss) |
| Planned budget | $3.00 |
| Actual cost | $0.12 (recorded) |
| Budget used | 4% |
| API calls | 54 |
| Input (miss) / output | 60,068 / 86,323 |
| Cache-read | 5,182,208 |

## Verification

- 28 distinct academic sources (24 DOI + 4 OpenAlex IDs), all verified:
  28/28 HTTP 200, 0 not found. Five more sources than Test 4.
- Coverage explicitly balanced and documented: 16 foundational works
  (<=2014) + 12 recent (>=2015); the 2013-2014 gap is explained in the
  report (literature pattern: critique peak 2007-2012, closure 2014,
  post-mortems from 2015).
- Citation consistency check performed automatically: every number
  [1]-[28] appears in the text and in the bibliography, no out-of-range
  numbers, no uncited bibliography entries.
- HTML: 61 citation anchors linked to the 28 bibliography entries,
  balanced tags (0 mismatches), zero external dependencies, inline CSS.
- Independent spot check after the run confirmed sample DOIs resolve
  (Crossref HTTP 200).

## Agent behavior

- Same method as Test 4: context files in order, STATUS files, public
  academic APIs, grounding rules, no fabrication.
- The goal mode produced a more refined internal pipeline than Test 4:
  query log (query_log.json), collected papers index, renumbering script
  for citations, dedicated HTML builder. The run inherited the
  "academic-literature-search" skill the agent created for itself during
  Test 4 (self-improvement across runs).
- Higher breadth at similar marginal cost: +5 sources, stricter automated
  verification, longer report (21.2KB vs 19.4KB) for +25% cost.
- One TUI quirk: injecting the goal and the prompt as a single multiline
  paste interrupted the first response; the TUI queued the messages and
  the run completed normally. Documented for reference.

## Scores

| Dimension | Score |
|---|---|
| Autonomy (0 interventions, self-verification) | 9.5/10 |
| Cost efficiency (4% of budget) | 9.5/10 |
| Cache strategy (98.9% hit, better than Test 4) | 10/10 |
| Output quality (28 verified sources, balanced coverage, stricter checks) | 9.5/10 |
| Process fidelity (status files, inherited skill, documented quirk) | 9.5/10 |
| **Overall** | **9.6/10** |

## Limitations

- Same as Test 4: synthesis from abstracts/metadata, not full text;
  anglophone bias declared.
- The comparison is two runs of the same task, not a controlled
  experiment: the second run also benefited from the skill created in the
  first, so part of the improvement comes from self-improvement, not from
  the goal mode alone.
