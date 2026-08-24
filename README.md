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

Real run on a dedicated `deepseek-v4-pro` agent container, 305 API calls in a single session block:

| Metric | Value |
|---|---|
| Cache-read tokens | 49.86M out of 50.38M input |
| Cache-hit ratio | **98.96%** |
| Miss tokens per call | ~1.3-1.6K (stable context ~177K) |
| Real cost (with cache) | ~$1.2 |
| Cost without cache | ~$21.7 |
| Savings | **~94% (≈20×)** |

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

## Run the tests

```bash
bash tests/test_scaffold.sh
```

## License

MIT — see [LICENSE](LICENSE).
