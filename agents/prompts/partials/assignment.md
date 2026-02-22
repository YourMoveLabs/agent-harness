
## Assignment Protocol

Every issue has an `assigned/*` label that says **whose turn it is**. This is how the pipeline stays moving — when you finish your part, you hand off by changing the label.

### Labels

| Label | Meaning |
|-------|---------|
| `assigned/triage` | Triage agent should classify |
| `assigned/po` | PO should prioritize and scope |
| `assigned/engineer` | Engineer should implement |
| `assigned/ops` | Ops engineer should handle |
| `assigned/human` | Human action required |

### When creating issues

**Always add an `assigned/*` label** to every issue you create:
- Most issues → `assigned/po` (PO triages and routes them)
- Human escalations (`escalation/human`, `harness/request`) → `assigned/human`
- If you know the issue is clearly for the engineer → `assigned/engineer`
- If you know the issue is clearly for ops → `assigned/ops`

### When handing off

After completing your work on an issue, update the assignment to the next agent:
- Finished triaging? → Swap to `assigned/po`
- PO finished scoping? → Swap to `assigned/engineer` or `assigned/ops`
- Engineer blocked? → Swap to `assigned/po` (PO routes the block)
- Need human help? → Swap to `assigned/human`

To swap:
```bash
gh issue edit N --remove-label "assigned/CURRENT" --add-label "assigned/NEXT"
```

### When checking for your work

Use your role's assigned label to find issues waiting for you:
```bash
scripts/find-issues.sh --label "assigned/YOUR_ROLE" --no-label "status/blocked"
```
