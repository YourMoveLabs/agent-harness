Review how the QA Analyst agent is doing its job and identify opportunities to give it better tools. The goal is a self-improving loop: you spot gaps, file tooling issues, the engineer builds scripts, and QA auto-discovers them on its next run.

## Step 1: Review recent QA work

Check what the QA agent has been doing recently:

```bash
scripts/find-issues.sh --label "source/qa-analyst" --limit 10
```

For each recent QA issue, read it and note:
- What data did QA check?
- How did it check it (manual curl/jq vs scripts)?
- What did it miss that a script could have caught?
- Was the evidence thorough or shallow?

```bash
gh issue view N
```

## Step 2: Inventory existing QA tools

List what QA already has available:

```bash
ls scripts/qa-* 2>/dev/null || echo "No QA scripts yet"
```

For any existing scripts, check what they do:

```bash
scripts/qa-SCRIPT_NAME --help 2>/dev/null || cat scripts/qa-SCRIPT_NAME | head -20
```

## Step 3: Read the QA prompt

Understand what QA is supposed to do and what tools it can use:

```bash
cat .harness/agents/prompts/qa-analyst.md
```

Note:
- What checks does QA perform manually that could be scripted?
- What checks should QA be doing but isn't (because there's no easy way)?
- Where is QA doing repetitive work that a script would do better?

## Step 4: Identify tooling gaps

Compare what QA does manually against what scripts already exist. A good QA tool:

- **Automates a repeated manual check** — something QA does with curl/jq every run
- **Is more thorough than manual work** — checks all endpoints, not just a sample
- **Has clear pass/fail output** — QA can act on the results without interpretation
- **Follows the script convention** — `scripts/qa-*.sh`, supports `--help`, outputs structured results

Bad candidates for scripts:
- One-off checks that won't repeat
- Checks that require human judgment (is this copy good?)
- Things that change too fast to codify

## Step 5: File tooling issues

For each gap (maximum 2 per run), create a tooling issue for the engineer:

```bash
gh issue create \
  --title "Tooling: scripts/qa-TOOL_NAME.sh — WHAT_IT_DOES" \
  --label "agent-created,source/tech-lead,type/tooling,priority/medium" \
  --body "## QA Tooling Gap

**What QA currently does manually**: DESCRIBE_THE_MANUAL_WORK

**What this script should do**: DESCRIBE_THE_AUTOMATION

**Why it helps QA**: HOW_THIS_IMPROVES_QA_COVERAGE

## Script Spec

**Name**: \`scripts/qa-TOOL_NAME.sh\`

**Inputs**: FLAGS_AND_ARGUMENTS

**Output**: WHAT_IT_RETURNS (structured JSON preferred)

**Example usage**:
\`\`\`bash
scripts/qa-TOOL_NAME.sh --flag value
\`\`\`

**Expected output**:
\`\`\`json
{ \"checks\": [...], \"passed\": N, \"failed\": N }
\`\`\`

## Evidence

- QA issue #N: QA manually did X — this script would have done it automatically
- QA issue #M: QA missed Y — this script would have caught it

## Acceptance Criteria

- [ ] Script exists at \`scripts/qa-TOOL_NAME.sh\`
- [ ] Supports \`--help\` flag
- [ ] Returns structured output (JSON preferred)
- [ ] QA agent can discover and use it via \`ls scripts/qa-*\`"
```

If no gaps are found (QA's tooling is sufficient), don't create issues. Report that in the summary.

## What to look for

- **Repetitive manual work** — QA curling the same 10 endpoints one by one instead of a single script
- **Missing coverage** — areas QA should check but doesn't because it's too tedious manually
- **Shallow checks** — QA only spot-checks when a script could be exhaustive
- **Inconsistent checks** — QA checks different things each run because there's no standardized script

## Output

- Max 2 tooling issues with `type/tooling,source/tech-lead` labels
- Each issue includes a clear script spec (name, inputs, outputs, example usage)
- If QA tooling is sufficient, report "QA tooling is adequate — no gaps found"
