---
name: cancel
description: "Use this skill when the user runs /cancel or asks to stop the current workflow. Stops the active tinyspec workflow without deleting state."
argument-hint: ""
metadata:
  version: "0.1.0"
---

# Cancel

Stop the active workflow. State is preserved — run `tinyspec:reset` to clear it.

## Steps

1. Read `.tinyspec/session-state.md`
2. If file doesn't exist: "No active workflow to cancel."
3. If `status` is already `cancelled` or `complete`: "Workflow is already <status>."
4. Otherwise: set `status: cancelled` in `.tinyspec/session-state.md`
5. Confirm: "Workflow cancelled at phase: <phase>. Run `tinyspec:reset` to start fresh or `tinyspec:status` to review state."
