---
name: reset
description: "Use this skill when the user runs /reset or asks to start the workflow over. Clears all workflow state and starts fresh at phase: design."
argument-hint: ""
metadata:
  version: "0.1.0"
---

# Reset

Clear all workflow state and start fresh.

## Steps

1. Read `.tinyspec/session-state.md` if it exists. Note the current `graph:` value (default to `coding` if absent).
2. Warn the user: "This will erase all workflow state including artifacts and checkpoints. Continue? (yes/no)"
3. If user says no: stop, do nothing
4. If user says yes:
   a. Delete `.tinyspec/session-state.md`
   b. Create a new `.tinyspec/session-state.md` using the same `graph:` value that was active (not hardcoded to `coding`):

```
graph: <preserved graph name>
phase: design
status: active
loop_count: 0

artifacts:
  user_intent: null
  design_spec: null
  design_status: null
  plan: null
  plan_status: null
  execute_status: null
  review_summary: null
  verification: null
  branch_complete: null

checkpoints:
```

5. Confirm: "Workflow reset. Ready to start — describe what you want to build."
