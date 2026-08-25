# INSTALL — Docker Agent Workflow with Cache-Hit Strategy

A skill for agents (Hermes and others) that deploy autonomous Docker agents
with a prompt-cache optimization strategy. This repo IS a skill: `SKILL.md`
is the playbook the agent loads and follows; `scripts/` and `templates/`
are the tools the playbook uses.

## Prerequisites

- Linux x86_64 with Docker installed
- A skills-based agent (Hermes, Claude Code, Codex, OpenClaw...)
- (Recommended) `uv` for the Python scripts

## Option A — Native install as a Hermes skill

```bash
hermes skills install jack89-ML/docker-agent-cache-optimized-workflow
```

Or via the ecosystem package manager (works with any skills-based agent):

```bash
npx skills add jack89-ML/docker-agent-cache-optimized-workflow -g -y
```

Verify:

```bash
hermes skills list | grep docker-agent-cache
# or
npx skills list
```

## Option B — Manual clone into the skills directory

```bash
git clone https://github.com/jack89-ML/docker-agent-cache-optimized-workflow.git
# Hermes:
mkdir -p ~/.hermes/skills/autonomous-ai-agents
cp -r docker-agent-cache-optimized-workflow ~/.hermes/skills/autonomous-ai-agents/
# Claude Code:
# cp -r docker-agent-cache-optimized-workflow ~/.claude/skills/
```

The agent will load the skill automatically when the task matches its
description ("Use when deploying a Docker agent with cache-hit strategy"),
or on explicit request.

## Option C — Direct use without installing

```bash
git clone https://github.com/jack89-ML/docker-agent-cache-optimized-workflow.git
cd docker-agent-cache-optimized-workflow
```

Then ask your agent: "use the skill at <path>/SKILL.md and apply the
workflow to project X". The agent will read the playbook from the path.

## Operational flow (what happens after install)

1. The agent loads `SKILL.md` (the playbook)
2. It generates the 4 context files for the project from `templates/`:
   `AGENT_PROMPT.md`, `CONTEXT.md`, `MASTER_PLAN.md`, `TASK_LIST.md`
   (via `scripts/scaffold_agent.sh <project> <image> <volume> <env_file>`)
3. It fills in the `<...>` placeholders (project name, models, endpoint)
4. It creates the Docker container and starts the persistent session (tmux)
5. It injects the agent prompt and work begins
6. It monitors cost and cache-hit with `scripts/usage_report.sh <state.db>`

## Quick post-install verification

```bash
bash -n scripts/*.sh                  # syntax OK
bash tests/test_scaffold.sh           # scaffold smoke test
./scripts/scaffold_agent.sh --help    # correct arguments
```

## Updates

The skill updates with `git pull` (if cloned) or:

```bash
hermes skills update docker-agent-cache-optimized-workflow
# or
npx skills update
```
