---
name: finish
description: Internal — phase "finish" handler. Router-only, do not invoke manually.
user-invocable: false
metadata:
  version: "0.1.0"
---

# Finish

Complete the branch. This is the terminal node — it sets status: complete.

## Steps

0. Read `.tinyspec/session-state.md` → verify `phase` = "finish". If not, print "finish invoked out of sequence (current phase: <phase>). Stopping." and stop.
1. Read `.tinyspec/session-state.md`. Check ALL of the following — halt if any fail:
   - `artifacts.verification` starts with "passed"
   - `artifacts.execute_status` = "all tasks complete" (not null or blocked)
   - If `execute_status` was set after `verification` was written, require the user to re-run verify before proceeding. Tell them: "More execution happened after the last verification pass. Please re-verify before finishing."
2. Present options to the user:
   - Open a pull request (default)
   - Merge directly to main
   - Tag a release
   - Just clean up the branch (no merge)
3. Execute the chosen action using standard git/gh commands
4. Update `.tinyspec/session-state.md`:
   - Write `artifacts.branch_complete` = "<what was done> — <PR URL or merge SHA>"
   - Set `status: complete`

## Rules

- Never merge without confirmed passing verification AND confirmed all tasks complete
- If execute ran after the last verification, always require re-verification
- Always confirm the action with the user before executing git push or gh pr create
