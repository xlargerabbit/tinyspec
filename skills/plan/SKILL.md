---
name: plan
description: Internal — phase "plan" handler. Router-only, do not invoke manually.
user-invocable: false
metadata:
  version: "0.1.0"
---

# Plan

Turn the approved design into a concrete implementation plan with a dependency graph.

## Steps

0. Read `.tinyspec/session-state.md` → verify `phase` = "plan". If not, print "plan invoked out of sequence (current phase: <phase>). Stopping." and stop.
1. Read `.tinyspec/session-state.md` → resolve `artifacts.design_spec` path. Reject the path if it contains `..` or starts with `/` or `~`. For "bug fix" intents, `design_spec` may be null — proceed without it.
2. Map out all files to create or modify and their responsibilities.
3. Decompose the work into tasks. Each task must be completable in ~5 minutes. If a task would take longer, split it into smaller tasks that each fit within 5 minutes. Tasks that can run independently of each other should be expressed at the same dependency level so the executor can parallelize them.
4. Write the implementation plan to `.tinyspec/plans/YYYY-MM-DD-<feature-name>-plan.md` using the task format below.
5. Present the task DAG to the user: "Here is the task DAG. Does this look right? [Y/n]". Wait for the user's response. On Y (or no response), update `.tinyspec/session-state.md`:
   - Set `artifacts.plan` to the file path (not the content)
   - Write `artifacts.plan_status`: "ready"
   This is the last human checkpoint before execution. On N, return to step 3 and revise the plan.

## Task Format

Every task in the plan must use exactly this structure:

```
### T<N> — <short task name>

- **id**: T<N>
- **status**: pending
- **depends-on**: [T<x>, T<y>]   ← list task IDs this task requires to be done first; [] if none
- **estimate**: <N> min           ← target ≤5 min; flag and split anything over 5 min
- **files**: `path/a`, `path/b`  ← every file this task may touch; subagents are constrained to this list
- **verify**: `<command>`         ← one runnable command that confirms this task's work is correct
- **self-verify**: `<command>`   ← command the executor runs inline after the task completes (can be the same as verify or simpler)
- **auto_retry**: true|false     ← if true, executor retries the task once on self-verify failure before blocking

**Steps**
1. <concrete step — no placeholders>
2. ...
TDD: write failing test → confirm it fails → implement → confirm it passes → commit
```

**Dependency rules:**
- `depends-on: []` means the task can start immediately (root task)
- `depends-on: [T1, T2]` means this task cannot start until both T1 and T2 are `done`
- Avoid circular dependencies — the DAG must be acyclic
- Group independent tasks at the same dependency level so they can run in parallel

## Rules

- No placeholders — every step must contain what an engineer needs to act on it
- Each task must include a `**verify**` command; no task may have an empty verify
- Each task must include a `**self-verify**` command and an `**auto_retry**` value. No task may omit these fields.
- Split any task estimated over 5 minutes into smaller tasks before writing the plan
- Implementation plan doc must be written to disk; never write full content into .tinyspec/session-state.md; never write detail code in the plan, instead let the task execution handles it.
- Never resolve a file path that contains `..` or starts with `/` or `~`
