# Test 4 — Academic literature review (HTS) · deepseek-v4-pro

**Status: PASSED** · Date: 2026-08-25 · ~20 min · 0 human interventions

## Overview

This test moves the workflow out of the coding domain: the task is an
exploratory academic literature review on Human Terrain Systems (HTS), the
US Army counterinsurgency program (2007-2015) that embedded social
scientists in combat brigades. The research question covers five axes:
historical and institutional context (2006-2014), theoretical and
methodological foundations, academic and ethical critiques (AAA 2007
resolution), program closure and legacy, and contemporary evolutions
toward data-driven and algorithmic warfare. The review was designed to
rely exclusively on academic sources through public APIs (OpenAlex,
Crossref, arXiv, Semantic Scholar), with a hard requirement: no statement
without a verifiable citation, and no fabricated papers, DOIs or authors.
Deliverables: a structured report in markdown and a standalone HTML page.

## Setup

| Item | Value |
|---|---|
| Container | `agent-research-test` (nousresearch/hermes-agent) |
| Model | deepseek-v4-pro (official API), single, no delegation |
| Context | CONTEXT / MASTER_PLAN / TASK_LIST / AGENT_PROMPT (4 files) |
| Task | Academic literature review on HTS, 5 research axes, Italian report |
| Budget | $3.00 hard cap |
| Sources | OpenAlex, Crossref, arXiv, Semantic Scholar (public APIs, curl) |

## Cost summary

| Metric | Value |
|---|---|
| Cache-hit | **97.5%** — 2,438,144 cache-read / (2,438,144 + 62,283 miss) |
| Planned budget | $3.00 |
| Actual cost | $0.096 (recorded) |
| Budget used | 3.2% |
| API calls | 39 |
| Input (miss) / output | 62,283 / 69,023 |
| Cache-read | 2,438,144 |

## Verification

- 23 distinct academic sources (19 DOI + 4 OpenAlex IDs), all identifiers
  verified via Crossref and OpenAlex APIs before delivery: 23/23 HTTP 200,
  0 not found.
- Report: 8 sections covering the 5 required axes, abstract, numbered
  bibliography, "Limitations" section. Independent spot check after the
  run confirmed the key DOIs resolve (McFate 2005, Kipp et al. 2006,
  Gonzalez 2007, Gusterson 2007, Zehfuss 2012) and the cited authors and
  dates are historically accurate.
- HTML deliverable: standalone file, inline CSS, no external dependencies.

## Agent behavior

- Read context files in the mandated order, wrote STATUS_SPRINT1..3 with
  accumulated cost estimates.
- Built its own pipeline of Python scripts (collection, selection,
  Crossref lookup, verification) instead of ad-hoc calls.
- Environment blocker handled correctly: the delivery folder was owned by
  another uid and not writable; the agent documented the block and
  delivered to a fallback folder (rule: document, never fabricate).
- Semantic Scholar was rate-limited (429) and excluded, documented in the
  report limitations.

## Scores

| Dimension | Score |
|---|---|
| Autonomy (0 interventions, self-verification) | 9.5/10 |
| Cost efficiency (3.2% of budget) | 10/10 |
| Cache strategy (97.5% hit) | 9.5/10 |
| Output quality (historically accurate, 23 verified sources, honest limits) | 9.5/10 |
| Process fidelity (status files, documented blockers, no fabrication) | 9.5/10 |
| **Overall** | **9.5/10** |

## Limitations

- Synthesis based on abstracts and metadata from APIs, not full-text
  reading: a first-level literature map, not a deep full-text analysis.
- Anglophone bias in the source base, declared in the report.
- Semantic Scholar excluded due to rate limiting; OpenAlex + Crossref +
  arXiv covered the ground.
