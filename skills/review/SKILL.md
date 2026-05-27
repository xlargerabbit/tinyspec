---
name: review
description: Internal — phase 'review' handler. Router-only, do not invoke manually.
metadata:
  version: "0.1.0"
---

# Review

Confirm implementation is complete and all checks pass. Produce a concise diff summary for the user before advancing to finish.

## Steps

0. Read `.tinyspec/session-state.md` → verify `phase` = "review". If not, print "review invoked out of sequence (current phase: <phase>). Stopping." and stop.

1. **Run plan verification commands**
   - Read `.tinyspec/session-state.md` → resolve `artifacts.plan` path. Reject the path if it contains `..` or starts with `/` or `~`.
   - Read the plan file. Collect every `**verify**` command listed in all task blocks.
   - Run each command in sequence. Read the full output of each — do not skim.

2. **Run project-level fallback checks**
   - If `package.json` is present → run `npm test`
   - If `pyproject.toml`, `setup.py`, or `pytest.ini` is present → run `pytest`
   - If `go.mod` is present → run `go test ./...`
   - If `Cargo.toml` is present → run `cargo test`
   - If none of the above are detected, skip this step.

3. **Handle failures**
   - If any command from step 1 or step 2 exits non-zero: write `artifacts.verification` = "failed — <command that failed>: <short error summary>" and stop. The router's `retry_when` condition will detect this and automatically route back to `execute`.

4. **Collect changed files**
   - Run `git diff main...HEAD --stat` and capture the output.

5. **Write review_summary**
   - Count the number of files changed from the git stat output.
   - Infer key behavioral changes from the task names in the plan file.
   - Note which test commands ran (from steps 1 and 2).
   - Compose a concise `review_summary`: files changed count, key behavioral changes, what tests ran.

6. **Update session-state artifacts**
   - Write `artifacts.verification` = "passed — <one-line summary of what ran and passed>"
   - Write `artifacts.review_summary` = "<the review_summary text from step 5>"

7. **Present summary to user**
   - Print: "All checks passed. Here's what changed: <review_summary>. Looks good? [Y/n]"
   - On Y (or no response): stop. The router will read `verification="passed"` and auto-advance to `finish` via `advance_when`.

## Rules

- Run ALL verification commands — never skip a subset
- Read the full output of each command before deciding pass/fail
- A passing test suite with a lint error is still a failure
- Never claim passing without running the actual commands and reading their output
- Never resolve a file path that contains `..` or starts with `/` or `~`
