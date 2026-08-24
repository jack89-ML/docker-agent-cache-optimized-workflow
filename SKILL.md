---
name: docker-agent-cache-optimized-workflow
description: "Use when deploying a Docker agent with cache-hit strategy."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [docker, agent, autonomous, caching, cost-optimization, delegation, tmux]
---

# Docker Agent Workflow with Cache-Hit Strategy

Deploy a long-running autonomous agent in a Docker container, give it a task
list and stable context files, and maximize LLM prompt-cache hits to cut API
costs (typically 70-90% of input tokens served from cache).

## When to Use

- User wants an autonomous agent to execute a multi-sprint project (hours/days)
- The agent must read project context, run tools, and delegate subtasks
- Cost matters: the agent will make many sequential LLM calls (cron, dev work)
- You want observable progress (status files, monitoring, Telegram/chat updates)

## Quick Start (scaffold)

```bash
# Compila i template una volta, poi per OGNI nuovo progetto:
bash scripts/scaffold_agent.sh <project_name> <image> <volume> <env_file> [docker_args...]

# Esempio:
bash scripts/scaffold_agent.sh myapp nousresearch/hermes-agent /opt/myapp-data /opt/myapp.env --network host
```

Lo script genera i 4 file di contesto dai template in `templates/`, crea il
container, avvia la sessione tmux e inietta il prompt. Dopo il lancio:
**compila i placeholder `<...>` nei 4 file** (il progetto specifico).

## Key Insight: Prompt Caching Is Prefix-Based

Most providers (DeepSeek, Qwen, Anthropic, OpenAI) cache the **prefix** of a
conversation automatically: if request N+1 starts with the same tokens as
request N, those tokens are billed at a heavily discounted "cache read" rate
(e.g. DeepSeek $0.004/M vs $0.44/M — ~99% off).

**The strategy is therefore: keep a STABLE PREFIX and push all changing data
to the TAIL of the context.** Never interleave static and dynamic content.

## Validazione misurata (progetto VITA, 23-24/08/2026)

Risultati reali dell'applicazione di questa strategia (container agente dedicato
deepseek-v4-pro, 305 chiamate, blocco unico di sessioni):

- Cache-read: 49,86M token su 50,38M di input = **98,96%** (99,2% nella prima
  sessione, 99,0% nella seconda)
- Token miss per chiamata: ~1,3-1,6K con contesto stabile ~177K — prova che i
  dati dinamici sono rimasti in coda al prefisso
- Costo reale: **~$1.2 invece di ~$21.7 senza cache → -94% (≈20×)**
- La cache è sopravvissuta 4 ore tra due sessioni con lo stesso prefisso
- Unica rottura registrata: la compressione di contesto (necessaria, ~$0.03)

Regola di salute: se i miss per chiamata salgono sopra ~2K con contesto >100K,
una regola è stata violata (dump grezzi, file riletti, prefisso mescolato).

## Workflow

### 1. Create the context files (in the container's persistent volume)

Four files, each with ONE role (never mixed):

```
<WORKSPACE>/CONTEXT.md        # static: mission, stack, design system, constraints
<WORKSPACE>/MASTER_PLAN.md    # static: architecture, sprint phases, model matrix
<WORKSPACE>/TASK_LIST.md      # near-static: checkboxes that change rarely
<WORKSPACE>/AGENT_PROMPT.md   # the system/role prompt injected at startup
```

Rules encoded INTO AGENT_PROMPT.md (make them binding):

1. Read CONTEXT/MASTER_PLAN/TASK_LIST in this exact order at session start.
2. Dynamic data (API responses, tool output) ALWAYS goes after static blocks.
3. Never re-read the same files every turn — read once, reuse.
4. Never paste large files/scripts verbatim into context — summarize + cite path.
5. Keep sessions long: do NOT restart the container mid-sprint (cache dies).

### 2. Launch a persistent interactive session (tmux, NOT one-shot)

One-shot `docker exec ... hermes chat -q "task"` per task = a new process each
time = **zero cache reuse** (cache lives in the running process). Instead:

```bash
# Inside the container: persistent session
docker exec -d <container> bash -c 'tmux new-session -d -s agent -x 200 -y 50 "hermes"'
sleep 10   # let hermes boot

# Inject the prompt ROBUSTLY (avoid shell quoting pitfalls with apostrophes):
docker cp <AGENT_PROMPT.md> <container>:/tmp/agent_prompt.md
docker exec <container> bash -c \
  'tmux load-buffer -b agent_prompt /tmp/agent_prompt.md \
   && tmux paste-buffer -b agent_prompt -t agent \
   && tmux send-keys -t agent Enter'
```

Send follow-up steering messages the same way (send-keys). Capture progress:
`tmux capture-pane -t agent -p | tail -40`.

### 3. Give the agent access to its data sources

- **Network**: if the agent must reach the host or other LAN hosts, run the
  container with `--network host` (bridge mode is firewalled by default).
  Verify reachability FROM the container (ping/nc/ssh) before declaring done.
- **SSH key**: copy the key into the persistent volume (`<VOL>/.ssh/`),
  chown to the container UID, and TELL the agent the exact command to use.
  The agent cannot guess credentials that exist but were never communicated.
- **Databases**: connect read-only (WAL mode); never let the agent write to
  production data.

### 4. Delegate heavy subtasks to a second model (optional)

If the orchestration model is cheap (e.g. DeepSeek) and a specialized model is
better for certain sprints (e.g. a top-tier model for design/backend), configure
delegation in Hermes:

```bash
hermes config set delegation.model <model-id>
hermes config set delegation.provider <provider>
hermes config set delegation.base_url <endpoint>
# key goes in the container env file: <PROVIDER>_API_KEY=...
```

Encode the delegation rules in AGENT_PROMPT.md (which sprint → which model).

### 5. Monitor cost, tokens and cache (watchdog)

If Hermes stores usage in a SQLite DB (`session_model_usage` table with
`input_tokens`, `output_tokens`, `cache_read_tokens`, `cache_write_tokens`,
`estimated_cost_usd`), build a watchdog script that:

- Reads SUM over the last 24h
- Computes cache-hit % = cache_read / (input + cache_read)
- Sends a Telegram/chat message ONLY when the state hash changes (dedup)
- Runs every 15 min via cron with `no_agent: true` (zero tokens)

Also verify `docker exec <container> bash -c 'env | grep <KEY>'` — env vars
are only loaded at container CREATE; `docker restart` does NOT re-read
`--env-file`. Recreate the container when adding keys.

## Verification Checklist

- [ ] Context files exist in the persistent volume, visible from the container
- [ ] Agent read them in the fixed order (visible in session capture)
- [ ] Container reaches its data source (ssh/ping/curl verified)
- [ ] tmux session alive after N minutes; agent not stuck on a question
- [ ] cache_read_tokens / (input_tokens + cache_read_tokens) ≥ 60%
- [ ] Watchdog reports cost+tokens; dedup works (no spam)
- [ ] Status files (STATUS_*.md) appear in the workspace as the agent works

## Pitfalls

- **Quoting**: injecting prompts via `tmux send-keys '...'` breaks on
  apostrophes (`ALL'AVVIO`). Use load-buffer + paste-buffer instead.
- **Restart kills cache**: never `docker restart` mid-sprint for config
  changes — recreate only when env keys change, accept the cache loss.
- **Bridge network isolation**: default bridge cannot reach the host's LAN IP;
  the host's port 22 appears closed. Use `--network host`.
- **Env not re-read on restart**: `docker restart` ignores updated env files.
- **Agent invents data when blocked**: if a source is unreachable the agent may
  fabricate. Prompt must forbid this ("never invent data — document the block").
- **One-shot vs persistent**: `chat -q` per task = no cache reuse. Always tmux.
- **`hermes chat -c` means "continue session"**, not "chat with this prompt".
  Use `-q` for single queries, tmux for long sessions.
- **Cron "NO-AGENT" senza flag**: un job che si chiama "(NO-AGENT)" ma senza
  `no_agent=true` consuma token a ogni run (caso watch-dashboard 24/08/2026:
  $0.07/giorno di chiamate che confermavano solo il lavoro già fatto dallo
  script). Verificare SEMPRE il flag reale nel job.
- **Account grandfathered**: DeepSeek può lasciare un account sui prezzi VECCHI
  anche dopo un cambio listino (verificato 24/08: v4-pro ancora a
  0.0084/0.42/0.84 per M invece dei nuovi 0.022/0.66/1.98). Le stime registrate
  da Hermes usano snapshot stantie: rivalutare coi prezzi ufficiali correnti e
  confrontare con entrambe le fasce (vedi llm-cost-telemetry).
