---
name: docker-agent-cache-optimized-workflow
description: "Use when deploying a Docker agent with cache-hit strategy."
version: 1.1.0
author: Jacopo Peracchio (crafted with Hermes Agent)
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [docker, agent, autonomous, caching, cost-optimization, delegation, tmux, security, watchdog]
---

# Docker Agent Workflow with Cache-Hit Strategy

Deploy a long-running autonomous agent in a Docker container, give it a task
list and stable context files, and maximize LLM prompt-cache hits to cut API
costs (typically 90%+ of input tokens served from cache). Built with and for
[Hermes](https://hermes-agent.nousresearch.com) (Nous Research's personal AI
agent); the caching rules are provider-agnostic and the Hermes-specific
commands (`hermes config`, `hermes chat`, tmux sessions) are shown as
examples.

## When to Use

- User wants an autonomous agent to execute a multi-sprint project (hours/days)
- The agent must read project context, run tools, and delegate subtasks
- Cost matters: the agent will make many sequential LLM calls (cron, dev work)
- You want observable progress (status files, monitoring, Telegram/chat updates)

## Quick Start (scaffold)

```bash
# Generate the templates once, then for EVERY new project:
bash scripts/scaffold_agent.sh <project_name> <image> <volume> <env_file> [docker_args...]

# Example:
bash scripts/scaffold_agent.sh myapp nousresearch/hermes-agent /opt/myapp-data /opt/myapp.env
```

The script generates the 4 context files from `templates/`, creates the
container, starts the persistent tmux session and injects the agent prompt.
After launch: **fill in the `<...>` placeholders** in the 4 files
(project-specific details).

## Key Insight: Prompt Caching Is Prefix-Based

Most providers (DeepSeek, Qwen, Anthropic, OpenAI) cache the **prefix** of a
conversation automatically: if request N+1 starts with the same tokens as
request N, those tokens are billed at a heavily discounted "cache read" rate
(e.g. DeepSeek v4-flash off-peak: $0.007/M hit vs $0.22/M miss; v4-pro
$0.022/M vs $0.66/M — roughly 97% off).

**The strategy is therefore: keep a STABLE PREFIX and push all changing data
to the TAIL of the context.** Never interleave static and dynamic content.
The gain scales with prefix STABILITY, not prefix size.

## Measured Validation (2026-08-23/24)

Real run of this strategy on a dedicated deepseek-v4-pro agent container,
305 API calls in a single session block (project VITA, health-monitoring app):

- Cache-read: 49.86M tokens out of 50.38M input = **98.96%** (99.2% in the
  first session, 99.0% in the second)
- Miss tokens per call: ~1.3-1.6K against a ~177K stable context — proof that
  dynamic data stayed at the tail of the prefix
- Real cost: **~$1.2 instead of ~$21.7 without cache → -94% (≈20×)**
- The cache survived 4 hours between two sessions with the same prefix
- Only cache break observed: context compression (necessary, ~$0.03 each)

Health rule: if miss tokens per call climb above ~2K with a context >100K, a
rule was violated (raw dumps, re-read files, interleaved prefix).

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
6. Command allowlist: only the tools needed for the sprint; destructive
   commands (rm, drop, force-push, writes to production data) require human
   approval and are logged.
7. Budget awareness: report accumulated token/cost in every STATUS file; stop
   and ask if the sprint exceeds its allocated budget.

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

**Robustness note.** Interactive paste is the pragmatic default, but it is
fragile (timing, TTY state). For production, prefer an idempotent injection:
an entrypoint script in the image that reads `AGENT_PROMPT.md` from the
workspace and starts the agent itself, so `docker restart` resumes cleanly
(cold cache, but state preserved). Never rely on interactive paste for
recovery.

### 3. Give the agent access to its data sources

- **Network**: use `--network host` ONLY when the agent must reach the host or
  other LAN hosts (bridge mode is firewalled by default). It exposes the host
  network namespace to the container: prefer a dedicated bridge or an
  internal network when possible, and never use it with untrusted images.
  Verify reachability FROM the container (ping/nc/ssh) before declaring done.
- **SSH key**: copy the key into the persistent volume (`<VOL>/.ssh/`),
  chown to the container UID, restrict permissions to 0600, and TELL the
  agent the exact command to use. The agent cannot guess credentials that
  exist but were never communicated.
- **Databases**: connect read-only (WAL mode, `mode=ro` URI) with scoped
  credentials; never let the agent write to production data.
- **Secrets**: keep API keys in the env-file, chmod 0600, never commit them;
  one key per line (duplicate lines break naive `grep` parsing — if you edit
  an env file by hand, check for duplicates). Env vars are loaded only at
  container CREATE — `docker restart` does NOT re-read the env file.

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

### 5. Monitor cost, tokens and cache (zero-token watchdog)

A ready-made script is included: `scripts/usage_report.sh <state.db>` — reads
the `session_model_usage` table (columns `input_tokens`, `output_tokens`,
`cache_read_tokens`, `cache_write_tokens`, `estimated_cost_usd`) and prints a
compact 24h report (calls, in/out/cache tokens, cache-hit %, estimated cost).

For change-only alerts, wrap it in a cron job with `no_agent: true` and
hash-dedup (send a message ONLY when the state hash changes — the pattern
used by api-cost-monitoring). Example:

```
* * * * *  usage_report.sh /opt/data/state.db > /tmp/usage.txt \
           && sha256sum /tmp/usage.txt | diff -q - <(cat /tmp/usage.hash) \
           && telegram-send < /tmp/usage.txt || sha256sum /tmp/usage.txt > /tmp/usage.hash
```

## Security Hardening (production)

- **Non-root**: run the container as a non-root user (`docker run --user
  10000:10000 ...`) when the image supports it; keep root only for
  bootstrapping (e.g. installing tmux with `docker exec -u 0 ...`).
- **Read-only filesystem**: mount the workspace read-write but the rest of the
  filesystem read-only (`--read-only` with tmpfs for /tmp) when the agent
  does not need to write outside the workspace.
- **Minimal capabilities**: `--cap-drop ALL` unless the task needs raw
  networking.
- **Network exposure**: see §3 — `--network host` is opt-in, not the default.
- **Secrets**: env-file 0600, never in the repo, never printed by the agent.

## Robustness & Recovery

- **State files are the checkpoint**: STATUS_*.md + the task list are the
  source of truth. If the container restarts (cache dies), the agent resumes
  from the state files — the first call after restart is a cold miss (one
  full context at miss price), then caching resumes.
- **Idempotent injection**: prefer an entrypoint that reads AGENT_PROMPT.md
  from the workspace over interactive paste (see §2).
- **Locking**: a single long-running session per container; don't run two
  agents on the same workspace (they would fight over the task list).

## Cache Portability (provider notes)

| Provider | Cache type | TTL / notes |
|---|---|---|
| DeepSeek | Automatic prefix cache | TTL in the order of hours; weekend and off-peak hours (01-04, 06-10 UTC Mon-Fri) bill at half price; accounts may be grandfathered on older price tiers |
| Qwen / DashScope | Automatic prefix cache | Same prefix-caching model; cache-write tokens billed separately |
| Anthropic | Automatic (min 1024-token prefix) | TTL ~5 min; long sessions need a heartbeat or the prefix expires |
| OpenAI | Automatic (min 1024-token prefix) | TTL ~5-10 min on most models |

The rules (stable prefix, dynamic tail, read-once) apply to all of them; the
prices and TTLs differ — verify per provider and per account tier.

**Context compression** rewrites the history and breaks the prefix: it costs
a full cold call (~$0.03 on a 177K context). Acceptable once, never in a
loop — bound the context instead (aggregate, don't dump).

## Operational Guardrails

- **Budget**: a cron that polls the provider balance (e.g. DeepSeek
  `GET /user/balance`) and alerts under a threshold; the agent records
  accumulated cost in every STATUS file.
- **Kill-switch**: document the stop command (`docker stop <container>` /
  `tmux kill-session -t agent`) and a hard budget cap per sprint.
- **Destructive actions**: no rm/drop/force-push/write-to-prod without human
  approval (encode in AGENT_PROMPT.md — see §1 rule 6).
- **Read-only data**: the agent never opens data DBs in write mode; auth/user
  data lives in a separate writable DB.

## Verification Checklist

- [ ] Context files exist in the persistent volume, visible from the container
- [ ] Agent read them in the fixed order (visible in session capture)
- [ ] Container reaches its data source (ssh/ping/curl verified)
- [ ] tmux session alive after N minutes; agent not stuck on a question
- [ ] cache_read_tokens / (input_tokens + cache_read_tokens) ≥ 90%
- [ ] Watchdog reports cost+tokens; dedup works (no spam)
- [ ] Status files (STATUS_*.md) appear in the workspace as the agent works
- [ ] Container runs non-root; secrets file is 0600; no secrets in the repo
- [ ] `bash -n` passes on all shipped scripts; tests/test_scaffold.sh is green

## Pitfalls

- **Quoting**: injecting prompts via `tmux send-keys '...'` breaks on
  apostrophes (`ALL'AVVIO`). Use load-buffer + paste-buffer instead.
- **Restart kills cache**: never `docker restart` mid-sprint for config
  changes — recreate only when env keys change, accept the cache loss.
- **Bridge network isolation**: default bridge cannot reach the host's LAN IP;
  the host's port 22 appears closed. Use `--network host` only when needed
  (see Security Hardening).
- **Env not re-read on restart**: `docker restart` ignores updated env files.
- **Duplicate keys in env files**: two identical `KEY=` lines concatenate
  under naive grep → broken Authorization headers. Dedupe env files.
- **Agent invents data when blocked**: if a source is unreachable the agent may
  fabricate. Prompt must forbid this ("never invent data — document the block").
- **One-shot vs persistent**: `chat -q` per task = no cache reuse. Always tmux.
- **`hermes chat -c` means "continue session"**, not "chat with this prompt".
  Use `-q` for single queries, tmux for long sessions.
- **Cron "NO-AGENT" without the flag**: a job named "(NO-AGENT)" but without
  `no_agent=true` consumes tokens on every run (real case: an hourly
  dashboard job spending $0.07/day just confirming the script had already
  done its work). Always verify the real flag in the job.
- **Grandfathered pricing**: a provider may keep an account on OLD prices
  after a price change (verified 2026-08-24: v4-pro still billed at
  $0.0084/$0.42/$0.84 per M instead of the new $0.022/$0.66/$1.98). Hermes'
  recorded estimates use stale price snapshots: revalue against the official
  current prices and check both tiers (see the llm-cost-telemetry skill).

## Repository Layout

```
├── SKILL.md                        # this playbook
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
