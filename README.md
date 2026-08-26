# Docker Agent Cache-Optimized Workflow

Deploy long-running autonomous agents in Docker containers with a prompt-cache-hit strategy that cuts LLM API costs by **84-95%** — validated on 7 real runs (96.8-99.99% cache-hit) across two task categories: app builds and academic literature reviews.

**Built with [Hermes](https://hermes-agent.nousresearch.com)** — Nous Research's personal AI agent. The caching rules are provider-agnostic (DeepSeek, Qwen, Anthropic, OpenAI); the Hermes-specific commands (`hermes config`, `hermes chat`, tmux sessions) are shown as working examples.

## Installation

This repo IS a skill: `SKILL.md` is the playbook your agent loads, `scripts/` and `templates/` are the tools it uses. Install it as a skill, or use it directly:

```bash
# Native Hermes install
hermes skills install jack89-ML/docker-agent-cache-optimized-workflow

# Any skills-based agent (Claude Code, Codex, ...)
npx skills add jack89-ML/docker-agent-cache-optimized-workflow -g -y

# Or clone and point your agent at SKILL.md
git clone https://github.com/jack89-ML/docker-agent-cache-optimized-workflow.git
```

Full instructions (options, verification, update): **[INSTALL.md](INSTALL.md)**

## What it does

A complete playbook + scaffold for running multi-hour / multi-day autonomous agent projects (sprint-based development, app builds, academic literature reviews, data pipelines) at minimal token cost:

- **Stable-prefix context files** — `CONTEXT.md`, `MASTER_PLAN.md`, `TASK_LIST.md`, `AGENT_PROMPT.md`: one role per file, never mixed with dynamic data.
- **Persistent tmux sessions** instead of one-shot calls — the prompt cache lives in the running process.
- **Cache-first rules encoded in the agent prompt** — read files once, pass aggregates only, never restart mid-sprint.
- **Security hardening** — non-root container user, read-only data access, 0600 secrets, `--network host` as explicit opt-in (never default).
- **Operational guardrails** — command allowlist, human approval for destructive actions, per-sprint budgets, kill-switch.
- **Robustness & recovery** — STATUS_*.md checkpoints, idempotent injection guidance, cold-restart budgeting.
- **Zero-token watchdogs** — `usage_report.sh` reads a Hermes `state.db` and prints cost/cache; hash-dedup for change-only alerts.
- **Delegation to a second model** for specialized sprints (cheap orchestrator + top-tier worker).
- **`scaffold_agent.sh`** — one command: generates the 4 context files from templates, creates the container (non-root), launches the tmux session, injects the prompt.

## Why prompt caching matters

Most LLM providers cache the **prefix** of a conversation automatically. If request N+1 starts with the same tokens as request N, those tokens are billed at a heavily discounted *cache-read* rate (e.g. DeepSeek v4-flash off-peak: $0.007/M hit vs $0.22/M miss). The strategy is therefore: **keep a stable prefix, push all changing data to the tail of the context.** Never interleave static and dynamic content.

## Measured results (production validation)

Seven real runs on dedicated agent containers (no human interventions), grouped by task category. Full per-test accounting (cache-hit, budget, cost, counterfactual, scores) in **[TEST_RESULTS.md](TEST_RESULTS.md)**.

| Category | Runs | Cache-hit | Cost (real) | Cost w/o cache | Saving |
|---|---|---|---|---|---|
| App (PWA + Android, 3 runs) | 3 | 97.2-99.99% | ~$1.67 | ~$12.2 | ~86% |
| Academic review (3 runs) | 3 | 96.8-98.9% | ~$0.30 | ~$4.39 | ~93% |
| VITA production (305 calls) | 1 | 98.96% | ~$1.2 | ~$21.7 | ~94% |
| **Combined** | **7** | **96.8-99.99%** | **~$3.2** | **~$38.3** | **~92%** |

> Savings 84-95% across all runs (~6-20x). Provider pricing differs (DeepSeek, Qwen); per-test numbers use each account's effective tier.

## Local models (docker container)

For running agents against a LOCAL model backend (e.g. FreeToken with a MoE
model), a parameterized Docker image is included in `docker/`: first boot
renders `config.yaml` from env vars (`FREETOKEN_BASE_URL`, `MODEL_NAME`), no
author data baked in. Build/run instructions and measured notes (KV cache
budget, expert offload, thinking toggle) are in `docker/README.md`.

## Quick start

```bash
# Requirements: docker, a Hermes-compatible agent image (tmux is installed automatically)
bash scripts/scaffold_agent.sh <project_name> <image> <volume> <env_file> [docker_args...]

# Example:
bash scripts/scaffold_agent.sh myapp nousresearch/hermes-agent /opt/myapp-data /opt/myapp.env
```

The script generates the 4 context files from `templates/`, creates the container, starts the persistent tmux session and injects the agent prompt. After launch: **fill in the `<...>` placeholders** in the 4 files (project-specific details).

Then monitor cost and cache with the zero-token watchdog:

```bash
bash scripts/usage_report.sh /opt/myapp-data/state.db
```

See [EXAMPLES.md](EXAMPLES.md) for a full end-to-end worked example.

## Install as a Hermes skill

```bash
cp -r docker-agent-cache-optimized-workflow ~/.hermes/skills/autonomous-ai-agents/
```

## Repository contents

```
├── SKILL.md                        # the full playbook (rules, workflow, hardening, pitfalls, verification)
├── scripts/
│   ├── scaffold_agent.sh           # one-shot scaffold: context files + container + tmux + prompt
│   └── usage_report.sh             # zero-token cost/cache report from a Hermes state.db
├── templates/
│   ├── AGENT_PROMPT_TEMPLATE.md    # role prompt with cache rules + guardrails baked in
│   ├── CONTEXT_TEMPLATE.md         # stable project context (mission, stack, constraints)
│   ├── MASTER_PLAN_TEMPLATE.md     # architecture + sprint plan
│   └── TASK_LIST_TEMPLATE.md       # executable task list with verification steps
├── tests/
│   └── test_scaffold.sh            # syntax + arg-validation smoke test
├── EXAMPLES.md                     # end-to-end worked example
├── README.md
└── CITATION.cff
```

## Validation

- [TEST_RESULTS.md](TEST_RESULTS.md) — 6 documented tests across two task categories: App (FocusPulse PWA, FocusPulse Android, FocusPulse PWA on qwen3.8-max) and Academic review (HTS, HTS with /goal mode, division of labor). Cache-hit 96.8-99.99%, saving 84-95%, grades 9.0-9.6/10.
- [EXAMPLES.md](EXAMPLES.md) — end-to-end worked example.

## Run the tests

```bash
bash tests/test_scaffold.sh
```

## License

MIT — see [LICENSE](LICENSE).
