#!/usr/bin/env bash
# Injects tinyspec workflow context at session start.
# If .tinyspec/session-state.md exists and is active: surfaces phase/status + asks router to resume.
# If absent: tells agent to start the coding workflow on first user request.
# Security: only structured metadata is injected — artifact content is never embedded.

STATE_FILE=".tinyspec/session-state.md"

json_encode() {
  # Prefer jq; fall back to python3
  if command -v jq &>/dev/null; then
    printf '%s' "$1" | jq -Rs .
  elif command -v python3 &>/dev/null; then
    printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
  else
    # Minimal bash fallback: escape backslashes, quotes, and newlines
    printf '"%s"' "$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n')"
  fi
}

if [ -f "$STATE_FILE" ]; then
  STATUS=$(grep -m1 "^status:" "$STATE_FILE" | awk '{print $2}')
  PHASE=$(grep -m1 "^phase:" "$STATE_FILE" | awk '{print $2}')
  GRAPH=$(grep -m1 "^graph:" "$STATE_FILE" | awk '{print $2}')
  LOOP=$(grep -m1 "^loop_count:" "$STATE_FILE" | awk '{print $2}')

  if [ "$STATUS" = "active" ]; then
    MSG="tinyspec workflow resuming. Graph: ${GRAPH:-coding}, Phase: ${PHASE:-unknown}, Loop: ${LOOP:-0}. Full state is in .tinyspec/session-state.md — read it directly for artifact details. Invoke tinyspec:router via the Skill tool to continue."
  else
    MSG="tinyspec workflow is ${STATUS:-unknown} (phase: ${PHASE:-unknown}). Run /reset to start fresh or /status for details."
  fi
else
  MSG="tinyspec is active. When the user describes something to build or fix, create .tinyspec/session-state.md with the content below, then invoke tinyspec:router via the Skill tool.

\`\`\`
graph: coding
phase: intent
status: active
loop_count: 0

artifacts:
  user_intent: null
  intent_status: null
  design_spec: null
  brainstorm_status: null
  plan: null
  plan_status: null
  execute_status: null
  verification: null
  branch_complete: null

checkpoints:
\`\`\`"
fi

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}' "$(json_encode "$MSG")"
