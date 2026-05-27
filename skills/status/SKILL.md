---
name: status
description: |
  Use this skill when the user runs /status or asks where the workflow is,
  what phase they are in, or what has been done so far.
  Reports the current phase, completed checkpoints, artifacts, and a visual graph diagram.
argument-hint: ""
metadata:
  version: "0.1.0"
---

# Status

Show the current workflow state at a glance, including a visual graph diagram.

## Steps

1. Read `.tinyspec/session-state.md`
2. If file doesn't exist or `graph` is null: print "No active workflow. Describe what you want to build to start one." and stop
3. Check if `.tinyspec/STATUS.md` exists. If it does, print its full contents and add a note: "_Live file: `.tinyspec/STATUS.md` — updated by the workflow on each state change._" then stop. (Skip remaining steps.)
4. Read `graphs/<graph>.md` → parse all nodes and their `next` edges
5. Render the **Graph Diagram** (see below)
6. Report the following sections:

### Sections to Report

**Phase**: `<current node>` — `<node description from graph>`

**Status**: active / cancelled / complete

**Completed**: bulleted list of checkpoint node names marked complete (or "none yet")

**Artifacts**: bulleted list of artifact keys that are non-null with their file paths (or "none yet")

**Next**: what the next node(s) will do, pulled from the `next` list of the current node in the graph

---

## Graph Diagram

Inline ASCII: `✓` = complete, `●` = current, `○` = pending, connected with ` → ` in graph order. List back-edges below as `↺ <node> can loop back to <target>`.

Example (`coding` graph at `plan`, `design` done):
```
✓ design → ● plan → ○ execute → ○ review → ○ finish

↺ review can loop back to execute
```
