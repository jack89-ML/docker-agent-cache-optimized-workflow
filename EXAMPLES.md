# End-to-End Example — "health-dashboard"

A worked example of the full workflow, modeled on the production run that
validated this skill (a personal health-monitoring app built by an autonomous
agent over ~20 hours at a real cost of ~$1.2 in LLM tokens).

## 1. Scaffold

```bash
bash scripts/scaffold_agent.sh health-dashboard nousresearch/hermes-agent \
  /opt/health-data /opt/health.env
# WARNING: env file not 0600 — chmod 0600 /opt/health.env
# WARNING: --network host ...   (only if you passed it)
```

The script creates `/opt/health-data/workspace/` with the 4 template files.

## 2. Fill in the placeholders (first 30 minutes, by a human or a quick LLM pass)

`CONTEXT.md` — mission, stack, data access rules.
`MASTER_PLAN.md` — architecture (watch DB → thin API → PWA) + 4 sprints.
`TASK_LIST.md` — concrete tasks per sprint.
`AGENT_PROMPT.md` — role, cache rules, guardrails, delegation (which sprint → which model).

## 3. Verify the container

```bash
docker exec health-dashboard bash -c 'tmux capture-pane -t agent -p | tail -20'
# → the agent should have read CONTEXT.md first, then MASTER_PLAN, then TASK_LIST
docker exec health-dashboard bash -c 'env | grep -c API_KEY'   # keys present
curl -s http://10.x.x.x:8766/healthz                          # reachability
```

## 4. Monitor (zero-token)

```bash
bash scripts/usage_report.sh /opt/health-data/state.db
# usage_report · last 24h · 2 model(s)
#   deepseek-v4-pro            calls=  305 in=   525,033 out=   645,056 cacheR=  49,855,744 ... hit= 99.0% est=$0.97
#   TOTAL                      calls=  305 in=   525,033 out=   645,056 cacheR=  49,855,744 ... hit= 99.0% est=$0.97
```

Wrap it in a `no_agent` cron with hash-dedup for change-only Telegram alerts
(see SKILL.md §5).

## 5. Expected session flow (what "it works" looks like)

```
18:40  agent starts, reads CONTEXT/MASTER_PLAN/TASK_LIST (cold call: ~20K miss)
18:41  first tool calls (miss tokens grow with tool output, prefix stays cached)
...    per-call pattern stabilizes: ~177K cached + ~1.3K miss per call
20:22  sprint 1 done, STATUS_SPRINT1.md written
00:36  session 2 starts 4h later — prefix STILL cached (same system prompt)
08:17  project complete, STATUS_SPRINT4.md written
```

Health checks: miss/call ≈ 1-2K (if it climbs, a cache rule was violated);
cache-hit ≥ 90% (this run: 98.96%); total cost within the sprint budget.
