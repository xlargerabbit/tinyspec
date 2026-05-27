# tinyspec

## Orchestration Docs Location

Skills use `.tinyspec/specs/` for design specs, `.tinyspec/plans/` for implementation plans, and `.tinyspec/session-state.md` for session continuity. Use no other paths unless the consumer repo explicitly overrides them.

## Design and Plan Spec Standards

When tinyspec skills generate or update design specs or implementation plans, they must follow these rules:

**Do not include code** unless it is critical — e.g., a non-obvious interface contract, a data schema where field names and types are the spec, or a tricky invariant that prose cannot convey precisely. Pseudocode and prose outlines are preferred.

Motivation: specs exceeding 1000 lines of detailed code defeat the purpose of a design document. The implementation belongs in the code, not the spec. Keep specs concise and intent-focused.
