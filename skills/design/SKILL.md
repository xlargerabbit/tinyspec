---
name: design
description: "Internal — phase 'design' handler. Router-only, do not invoke manually."
user-invocable: false
metadata:
  version: "0.1.0"
---

# Design

Capture the user's intent and produce a validated design spec (or inline approval for small changes) before planning begins.

## Steps

0. Read `.tinyspec/session-state.md` → verify `phase` = "design". If not, print "design invoked out of sequence (current phase: <phase>). Stopping." and stop.

1. Read `.tinyspec/session-state.md` → check `artifacts.user_intent`.
   - If null or empty: ask one open question — "What would you like to build, fix, or change?" — and wait for the user's answer before proceeding.

2. Classify scope internally (do not ask the user). A change is **small** if ALL of the following are true:
   - Touches ≤ 2 files
   - Estimated < 50 lines changed
   - No new API surface, no new dependencies, no new public interface

   Otherwise treat as **full design**.

3. **Small-change path:**
   - Describe the change in one paragraph: what file(s) will change, what exactly will be added or removed, and the expected outcome.
   - List the affected files.
   - Ask: "Does this match what you want? [Y/n]"
   - On Y (or no response): write the one-paragraph description as the spec to `.tinyspec/specs/YYYY-MM-DD-<topic>-design.md` (where `<topic>` is a 2-4 word kebab-case summary of the intent). If the inline description fully captures the intent without ambiguity, `design_spec` may be set to the file path; write it regardless.
   - Set `artifacts.design_status` = "approved" in `.tinyspec/session-state.md`.
   - Set `artifacts.design_spec` to the spec file path in `.tinyspec/session-state.md`.

4. **Full-design path:**
   - Explore the codebase: read relevant files and recent commits to understand what already exists.
   - Gather up to 5 targeted clarifying questions and ask them all in ONE batch — do not ask one at a time. Focus on: purpose and success criteria, constraints or non-goals, and any integration points that are unclear.
   - Propose 2-3 approaches with trade-offs; state your recommendation.
   - After the user selects an approach, write the spec to `.tinyspec/specs/YYYY-MM-DD-<topic>-design.md`.
   - Present the spec section by section and confirm each section with the user.
   - On final approval: set `artifacts.design_status` = "approved" in `.tinyspec/session-state.md`.
   - Set `artifacts.design_spec` to the spec file path in `.tinyspec/session-state.md`.

5. Update `.tinyspec/session-state.md`:
   - `artifacts.design_spec` — path to the spec file (or null if no file was written)
   - `artifacts.design_status` — "approved" (only after explicit user confirmation)

## Rules

- No code written during design — only design docs (prose, outlines, pseudocode where critical).
- Max 5 clarifying questions total across the entire design phase unless critical information missed requires user's feedback. Ask them in one batch, never one at a time.
- Never write content (spec text, intent text) directly into `.tinyspec/session-state.md` — only paths and status values.
- Never resolve a file path that contains `..` or starts with `/` or `~` — reject and report it.
- Do not set `design_status` = "approved" without explicit user confirmation (Y or equivalent).
