# Docker Agent Cache-Optimized Workflow

Deploy long-running autonomous agents in Docker containers with a prompt-cache-hit strategy that cuts LLM API costs by **70-94%** — validated in production on a 305-call agent session.

## What it does

A complete playbook + scaffold for running multi-hour / multi-day autonomous agent projects (sprint-based development, data pipelines, app builds) at minimal token cost:

- **Stable-prefix context files** — `CONTEXT.md`, `MASTER_PLAN.md`, `TASK_LIST.md`, `AGENT_PROMPT.md`: one role per file, never mixed with dynamic data.
- **Persistent tmux sessions** instead of one-shot calls — the prompt cache lives in the running process.
- **Cache-first rules encoded in the agent prompt** — read files once, pass aggregates only, never restart mid-sprint.
- **Delegation to a second model** for specialized sprints (cheap orchestrator + top-tier worker).
- **Zero-token watchdogs** — `no_agent` cron jobs with hash-dedup that report cost/tokens only when the state actually changes.
- **`scaffold_agent.sh`** — one command: generates the 4 context files from templates, creates the container, launches the tmux session, injects the prompt.

## Why prompt caching matters

Most LLM providers (DeepSeek, Qwen, Anthropic, OpenAI) cache the **prefix** of a conversation automatically. If request N+1 starts with the same tokens as request N, those tokens are billed at a heavily discounted *cache-read* rate (e.g. DeepSeek: ~$0.004-0.022/M hit vs $0.22-0.66/M miss). The strategy is therefore: **keep a stable prefix, push all changing data to the tail of the context.** Never interleave static and dynamic content.

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
# Requirements: docker, tmux (installed in the container automatically), a Hermes-compatible agent image
bash scripts/scaffold_agent.sh <project_name> <image> <volume> <env_file> [docker_args...]

# Example:
bash scripts/scaffold_agent.sh myapp nousresearch/hermes-agent /opt/myapp-data /opt/myapp.env --network host
```

The script generates the 4 context files from `templates/`, creates the container, starts the persistent tmux session and injects the agent prompt. After launch: **fill in the `<...>` placeholders** in the 4 files (project-specific details).

Then monitor cost and cache with a zero-token watchdog (see SKILL.md §5).

## Install as a Hermes skill

```bash
cp -r docker-agent-cache-optimized-workflow ~/.hermes/skills/autonomous-ai-agents/
```

## Repository contents

```
├── SKILL.md                        # the full playbook (rules, workflow, pitfalls, verification)
├── scripts/
│   └── scaffold_agent.sh           # one-shot scaffold: context files + container + tmux + prompt
├── templates/
│   ├── AGENT_PROMPT_TEMPLATE.md    # system/role prompt with cache-hit rules baked in
│   ├── CONTEXT_TEMPLATE.md         # stable project context (mission, stack, constraints)
│   ├── MASTER_PLAN_TEMPLATE.md     # architecture + sprint plan
│   └── TASK_LIST_TEMPLATE.md       # executable task list with verification steps
└── CITATION.cff
```

## License

MIT — see [LICENSE](LICENSE).
