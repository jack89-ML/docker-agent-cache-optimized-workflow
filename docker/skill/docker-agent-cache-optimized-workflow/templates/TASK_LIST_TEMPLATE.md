# AGENT TASK LIST — <PROJECT_NAME>

> **Instructions**: execute these tasks in order. For EVERY task: complete → verify → mark done →
> update `STATUS_<sprint>.md`. Do not skip tasks. If a task is blocked, document the block
> and move to the next one.

## PHASE 0 — PREREQUISITES (do first)
- [ ] 0.1 Read `CONTEXT.md` (mandatory, cache-hit)
- [ ] 0.2 Read `TASK_LIST.md` (this file) and `MASTER_PLAN.md`
- [ ] 0.3 Verify access to the data source (SSH/API) — if missing, document how to reach it
- [ ] 0.4 Create `STATUS_SPRINT1.md` with the start date

## SPRINT 1 — <NAME> (model: <X>)
- [ ] 1.1 <task>
- [ ] 1.2 <task>
- [ ] 1.3 <task>
- [ ] 1.4 <task>
- [ ] 1.5 <task>
- [ ] 1.6 <task>
- [ ] 1.7 <task>
- [ ] 1.8 <task>
- [ ] 1.9 <task>
- [ ] 1.10 <task>
- [ ] 1.11 <task>
- [ ] 1.12 Real test (curl/build/run)

## SPRINT 2 — <NAME> (model: <X>)
- [ ] 2.1 <task>
- [ ] 2.2 <task>
- [ ] 2.3 <task>
- [ ] 2.4 <task>
- [ ] 2.5 <task>

## SPRINT 3 — <NAME> (model: <X>)
- [ ] 3.1 <task>
- [ ] 3.2 <task>
- [ ] 3.3 <task>

## SPRINT 4 — <NAME> (model: <X>)
- [ ] 4.1 <task>
- [ ] 4.2 <task>
- [ ] 4.3 <task>

## STATUS FILE FORMAT (STATUS_<sprint>.md)
```markdown
# STATUS <sprint> — <PROJECT_NAME>
Date: <YYYY-MM-DD> · Started: <time> · Model: <X>
## Done
- <task> — verified via <how>
## In progress
- <task>
## Blocked
- <task> — reason + what is needed
## Cost
- tokens in/out/cache + estimated $ (from usage_report.sh)
```
