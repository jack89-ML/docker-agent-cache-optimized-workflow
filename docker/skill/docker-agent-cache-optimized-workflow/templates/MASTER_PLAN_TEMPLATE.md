# MASTER PLAN — <PROJECT_NAME>

> Status: **READY FOR SPRINT 1** · Executed by: autonomous agent <MODEL_A> + subagent <MODEL_B>
> Reference document: `CONTEXT.md` (mandatory: read it FIRST)

## TARGET ARCHITECTURE

```
<ASCII diagram: data source → service/API → app/client>
```

**GOLDEN ARCHITECTURE RULES (binding)**:
1. NEVER run CLI scripts per request (slow + DB locks).
2. NEVER write to production data from the service (read-only, WAL).
3. In-memory cache; invalidate ONLY on data-update events.
4. Zero heavy dependencies in the service.
5. Access ONLY via LAN/VPN — NEVER exposed to the Internet.

## SPRINT PLAN (4 sequential sprints + phase 0)

### PHASE 0 — Documentation (immediate)
- [x] CONTEXT.md in the container workspace
- [x] Master plan (this file)
- [ ] Verify the container reads both files

### SPRINT 1 — <NAME> (model: <X>)
- [ ] 1.1 <goal>
- [ ] 1.2 <goal>
- [ ] 1.3 <goal>
- [ ] 1.4 <goal>
- [ ] 1.5 <goal>
- [ ] 1.6 <goal>
- [ ] 1.7 <goal>
- [ ] 1.8 <goal>
- [ ] 1.9 <goal>
- [ ] 1.10 <goal>
- [ ] 1.11 <goal>
- [ ] 1.12 Real test (curl/build/run)

### SPRINT 2 — <NAME> (model: <X>)
- [ ] 2.1 <goal>
- [ ] 2.2 <goal>
- [ ] 2.3 <goal>
- [ ] 2.4 <goal>
- [ ] 2.5 <goal>

### SPRINT 3 — <NAME> (model: <X>)
- [ ] 3.1 <goal>
- [ ] 3.2 <goal>
- [ ] 3.3 <goal>

### SPRINT 4 — <NAME> (model: <X>)
- [ ] 4.1 <goal>
- [ ] 4.2 <goal>
- [ ] 4.3 <goal>

## BUDGET & GUARDRAILS
- Allocated budget per sprint: <$X> — the agent records cost in every STATUS file.
- Kill-switch: `docker stop agent-<PROJECT_NAME>` / `tmux kill-session -t agent`.
- Destructive actions require human approval (see AGENT_PROMPT.md).
