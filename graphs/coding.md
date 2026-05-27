---
name: coding
description: Standard software delivery workflow
start: design
nodes:
  design:
    description: Capture user intent, explore design space, and produce an approved spec
    next: [plan]
    advance_when: "artifacts.design_status == 'approved'"
  plan:
    description: Break design into concrete implementation tasks
    next: [execute]
    advance_when: "artifacts.plan_status == 'ready'"
  execute:
    description: Implement tasks, one subagent per task
    next: [review]
    advance_when: "artifacts.execute_status == 'all tasks complete'"
  review:
    description: Run all verification checks and confirm work is complete
    next: [finish, execute]
    advance_when: "artifacts.verification starts with 'passed'"
    retry_when: "artifacts.verification starts with 'failed'"
  finish:
    description: Merge, open PR, or clean up branch
    next: []
---
