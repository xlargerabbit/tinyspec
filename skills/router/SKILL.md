---
name: router
description: |
  Use this skill when a tinyspec workflow session needs to advance.
  Invoked automatically by the SessionStart hook when .tinyspec/session-state.md is active.
  Invoke manually with: tinyspec:router
metadata:
  version: "0.1.0"
---

# Router

Stateless graph interpreter. Read state → invoke node skill → update state → repeat.

## Loop

1. Read `.tinyspec/session-state.md`
2. If `status` is `cancelled` or `complete` → print a summary of `checkpoints` and artifact file paths, stop
3. Check `loop_count`: if the same `phase` has appeared 3+ consecutive times without artifact progress, pause and ask the user: "The workflow appears stuck at `<phase>`. What would you like to do? [retry / skip / cancel]". Do not continue until the user responds.
4. Increment `loop_count` by 1 in `.tinyspec/session-state.md`
5. Read `graphs/<graph>.md` → find the node matching `phase`
6. **Before invoking the node skill**, check for special conditions:
   - If `artifacts.execute_status` contains "blocked on": do NOT invoke execute again. Surface the blocked task ID to the user and ask: "Task <id> failed. [R]etry / [S]kip task / [C]ancel?" Wait for user input before proceeding.
7. Invoke the node skill via the Skill tool: `tinyspec:<phase>`
8. Re-read `.tinyspec/session-state.md`
9. Re-read `.tinyspec/session-state.md` and re-read the current node definition from the graph file. Evaluate routing conditions:
   - Look at the node's `advance_when` field and evaluate it against current `artifacts` using string comparison operators: `==`, `starts with`, `contains`
   - If `advance_when` condition is met: advance phase to the first entry in the node's `next` list
   - If `retry_when` is defined on the node and its condition is met: route to the second entry in `next` (the loop-back target)
   - If neither condition is met: stay on current phase (do not advance) — the skill will be re-invoked on the next router tick
10. Write `phase` = next node to `.tinyspec/session-state.md`; mark current node `complete` in `checkpoints`; reset `loop_count` to 0 on phase change
11. Write `.tinyspec/STATUS.md` using the **STATUS.md Format** below
12. Return to step 1

## Rules

- Never read any SKILL.md file directly — always invoke by name via Skill tool
- Never carry artifact content in context — read file paths from artifacts and resolve only when needed
- The router does not do any implementation work — it only dispatches and updates state
- Never re-invoke execute when `execute_status` contains "blocked on" — always pause for user input first
- Routing is driven by `advance_when`/`retry_when` conditions in the graph node — never hardcode phase transitions in this file

---

## STATUS.md Format

Write `.tinyspec/STATUS.md` with this structure:

```
# Workflow Status
_Last updated: <ISO 8601 timestamp>_

**Phase**: <phase> — <node description from graph>
**Status**: <active | cancelled | complete>

## Progress
<ASCII graph in graph order, e.g.:>
✓ design → ● plan → ○ execute → ○ review → ○ finish

↺ <back-edges, one per line: "<node> can loop back to <target>">

## Artifacts
- <key>: <value or file path>
(or "none yet" if all null)
```

**Rules for STATUS.md:**
- `✓` = node name appears in `checkpoints` as complete; `●` = current `phase`; `○` = pending
- Only list artifacts whose value is non-null
- Omit the back-edges block if the graph has none
- Always overwrite the file (never append)
