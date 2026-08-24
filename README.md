# Docker Agent Cache-Optimized Workflow

Deploy long-running autonomous agents in Docker containers with a prompt-cache-hit strategy that cuts LLM API costs by **70-94%** — validated in production on a 305-call agent session (98.96% cache-hit, ~$1.2 real cost vs ~$21.7 without cache).

**Built with [Hermes](https://hermes-agent.nousresearch.com)** — Nous Research's personal AI agent. The caching rules are provider-agnostic (DeepSeek, Qwen, Anthropic, OpenAI); the Hermes-specific commands (`hermes config`, `hermes chat`, tmux sessions) are shown as working examples.

## What it does

A complete playbook + scaffold for running multi-hour / multi-day autonomous agent projects (sprint-based development, data pipelines, app builds) at minimal token cost:

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

Three independent validation runs on dedicated `deepseek-v4-pro` agent containers (no human interventions):

| Run | Cache-hit | Cost (real) | Cost w/o cache | Saving | Grade |
|---|---|---|---|---|---|
| Test 1 — FocusPulse PWA (35 calls) | 97.2% | $0.105 | ~$1.16 | ~91% | 9.3/10 |
| Test 2 — FocusPulse Android (67 calls) | 98.5% | $0.147 | ~$2.39 | ~94% | 9.0/10 |
| VITA web+Android (305 calls, prod) | 98.96% | ~$1.2 | ~$21.7 | ~94% | — |
| **Combined** | **98.8%** | **~$1.45** | **~$25.3** | **~94%** | — |

> **Savings ≈94% (~20×)** across all runs.

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

- [TEST_RESULTS.md](TEST_RESULTS.md) — Test 1 (2026-08-24): FocusPulse PWA for Windows 11, 35 calls, 97.2% cache-hit, 18% of budget, 24/24 tasks, 28/28 smoke tests, grade 9.3/10 · Test 2 (2026-08-24): FocusPulse Android native, 67 calls, 98.5% cache-hit, 10% of budget, 4/4 sprints, APK installed on device, grade 9.0/10

## Run the tests

```bash
bash tests/test_scaffold.sh
```

## License

MIT — see [LICENSE](LICENSE).
