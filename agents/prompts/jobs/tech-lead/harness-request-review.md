Review open issues labeled `harness/request` to determine if the requested harness changes have been made. These issues were created when a feature or fix required changes to the agent-harness infrastructure. If the harness now provides what was requested, clear the label so the engineer can pick up the remaining work.

## Step 1: Find harness request issues

```bash
scripts/find-issues.sh --label "harness/request" --state open
```

If there are no `harness/request` issues, report "No pending harness requests" and stop.

## Step 2: Review each request against the current harness

For each issue:

1. **Read the issue** to understand what harness change was requested:
```bash
gh issue view N
```

2. **Check the harness** to see if the requested capability now exists. The harness is checked out at `.harness/` — explore its files:
```bash
ls .harness/agents/prompts/
ls .harness/config/
ls .harness/scripts/
cat .harness/action.yml
```

   Look for evidence that the request has been addressed:
   - New scripts, prompts, or configs that match what was asked for
   - Updated action.yml inputs that provide the requested capability
   - New roles or job files that deliver the requested functionality
   - README or changelog entries describing the change

3. **Make a judgment call**:
   - **Fulfilled**: The harness now provides what was requested. The remaining work (if any) is application-level, not infrastructure.
   - **Partially fulfilled**: Some of the request is done but key parts are missing. Leave as-is.
   - **Still needed**: The harness hasn't changed in a way that addresses this. Leave as-is.

## Step 3: Clear fulfilled requests

For each fulfilled request:

1. Remove the `harness/request` label:
```bash
gh issue edit N --remove-label "harness/request"
```

2. Add a comment explaining what changed:
```bash
gh issue comment N --body "Harness now provides [brief description of what changed]. Removing harness/request — this is now actionable as application-level work."
```

3. If the issue also has `status/blocked` and the harness was the only blocker, remove that too:
```bash
gh issue edit N --remove-label "status/blocked"
```

## What NOT to do

- Don't close the issues — they still represent work to be done (the engineer will pick them up)
- Don't change priority labels — that's the PO's job
- Don't create new issues — this job is purely about reviewing existing requests
- Don't guess — if you can't find clear evidence the request was fulfilled, leave it alone

## Output

For each `harness/request` issue, report:
- Issue number and title
- Status: Fulfilled (label removed), Still needed, or Partially fulfilled
- Evidence: what you found (or didn't find) in the harness
