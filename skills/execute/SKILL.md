---
name: execute
description: Internal — phase "execute" handler. Router-only, do not invoke manually.
metadata:
  version: "0.1.0"
---

# Execute

Implement the plan using dependency-aware parallel subagent dispatch.
The plan file is the shared communication channel — it is the only source of task truth.

## Steps

0. Read `.tinyspec/session-state.md` → verify `phase` = "execute". If not, print "execute invoked out of sequence (current phase: <phase>). Stopping." and stop.
1. Read `.tinyspec/session-state.md` → resolve `artifacts.plan` path. Reject the path if it contains `..` or starts with `/` or `~`.
2. Read the plan file. Parse every task block, extracting: `id`, `status`, `depends-on`.
3. Register all tasks in the Claude Code task system:
   - Call `TaskCreate` once per plan task: name = "T<N>: <task name>", description = the task's steps summary
   - Note the Claude task ID returned for each plan task ID (you will use these for status updates)
4. Run the execution loop until all tasks are `done` or the workflow is blocked:

### Execution Loop

**a. Re-read the plan file** (never rely on in-memory state from a previous iteration).

**b. Compute ready tasks:** a task is "ready" if:
   - its `status` = `pending`, AND
   - every task listed in its `depends-on` has `status` = `done`

**c. Detect deadlock:** if no tasks are ready but pending tasks remain:
   - If any pending task has a `depends-on` entry whose status is `failed` or `timeout` → set `artifacts.execute_status` = "blocked on <that task-id>" and stop.
   - Otherwise warn: "Possible circular dependency — no ready tasks. Review the plan." and stop.

**d. Select a batch:** pick up to 5 ready tasks (in plan order — lower task IDs first).

**e. Mark each selected task `in_progress`** in the plan file and call `TaskUpdate` to set each corresponding Claude task to `in_progress`.

**f. Spawn each task as a background subagent** — all in the same invocation so they run in parallel. Pass ONLY these inputs per subagent:
   - Path to the plan file
   - The task ID (e.g., "T3")
   - Path to `AGENTS.md`
   - The following constraint block, verbatim:
     ```
     CONSTRAINTS:
     - Only modify files listed in this task's **files** field
     - Do not modify .tinyspec/session-state.md
     - Do not push to remote
     - Do not delete files not explicitly listed in the task
     - Complete within 10 minutes. If you cannot finish, update the task status to "failed: timeout" in the plan file and stop.
     - Update the task's **status** field in the plan file to "done" on success or "failed: <reason>" on failure
     - Commit your changes before returning
     ```

**g. Wait for all spawned subagents to return.**

**h. Re-read the plan file.** For each task that was dispatched:
   - If `status` = `done` → call `TaskUpdate` to mark that Claude task `completed`
   - If `status` = `failed` or still `in_progress` (subagent returned without updating) → set `status` = `failed: timeout` in the plan file; call `TaskUpdate` to mark it `failed`

**h2. Self-verify each task that transitioned to `done` in this batch:**
   - For each such task, read its `self-verify` command from the plan file.
   - Run the `self-verify` command.
   - If it exits 0: task stays `done`.
   - If it exits non-zero AND `auto_retry: true`: re-spawn that task as a single background subagent with the same constraint block, wait for it to return, then re-run the `self-verify` command once more. If self-verify now exits 0: keep `done`. If it still exits non-zero: set task `status` = `failed: self-verify failed` in the plan file and call `TaskUpdate` to mark it `failed`.
   - If it exits non-zero AND `auto_retry: false`: immediately set task `status` = `failed: self-verify failed` in the plan file and call `TaskUpdate` to mark it `failed`.

**i. If any task is `failed`** → write `artifacts.execute_status` = "blocked on <task-id>" and stop.

**j. Write `.tinyspec/STATUS.md`** — read session-state.md + the graph file, then overwrite STATUS.md using the same format as the router's STATUS.md Format section, appending a Tasks block:
```
## Tasks
- [<status>] T<N> — <task name>
(one line per task, in plan order)
```

**k. Continue the loop.**

5. When all tasks are `done`: write `artifacts.execute_status` = "all tasks complete", then write a final STATUS.md (same format as step j)

## Rules

- Subagents receive only file paths and their constraint block — never session context
- Always re-read the plan file after subagents return; never trust return values alone
- Never dispatch a task whose dependencies are not yet `done`
- Maximum 5 subagents running concurrently
- Do not attempt to fix a failed task here — set `execute_status` blocked and let the router decide
- Never resolve a file path that contains `..` or starts with `/` or `~`
- Run self-verify for every task after it completes. Never mark a task done without a passing self-verify.
