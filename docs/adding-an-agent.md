# Adding a New Agent — Checklist

> **Automated by**: `/fishbowl:add-agent` skill in Claude Code
> **This doc is the canonical reference.** The skill implements this checklist.

## Prerequisites

Before adding an agent, you need:
- The role name (slug, e.g., `product-analyst`)
- A clear purpose statement
- Which goal(s) it serves
- Tool requirements (what Bash commands it needs)
- Schedule or trigger pattern
- Reporting relationship (who receives this agent's output)

## Repo Checklist

### Agent Harness (`YourMoveLabs/agent-harness`)

| # | File | Action | Notes |
|---|------|--------|-------|
| 1 | `agents/prompts/{role}.md` | **CREATE** | Full prompt: role, voice, sandbox rules, tools, steps, rules |
| 2 | `config/roles.json` | **EDIT** | Add role entry with tools, partials, and optional instances/prompt_role |
| 3 | `scripts/run-{role}.sh` | **CREATE** (optional) | Orchestration with pre-flight checks. Use if agent needs setup validation before running. |
| 4 | `docs/project-board-readme.md` | **EDIT** | Add to "The Team" section with role description |

### Agent Fishbowl (`YourMoveLabs/agent-fishbowl`)

| # | File | Action | Notes |
|---|------|--------|-------|
| 5 | `.github/workflows/agent-{role}.yml` | **CREATE** | Uses reusable workflow or direct harness action with `role` input |
| 6 | `CLAUDE.md` | **EDIT** | Add to: workflows table, project structure, coordination flow, source labels |
| 7 | Labels | **CREATE** | `source/{role}` (if creates intake issues), via `gh label create` |

### Cross-Agent Prompt Updates (agent-harness)

| # | File | Condition | Action |
|---|------|-----------|--------|
| 8 | `agents/prompts/product-owner.md` | Agent creates `source/*` intake issues for the PO | Add `find-issues.sh --label "source/{role}"` to Step 3 intake scan |
| 9 | `agents/prompts/triage.md` | Agent creates `source/*` issues | Add `--no-label "source/{role}"` to Step 1 exclusion filter |
| 10 | `agents/prompts/product-manager.md` | Agent reports proposals to the PM | Add review step for `source/{role}` issues |

### Infrastructure (Human Tasks)

| # | Task | Details |
|---|------|---------|
| 11 | GitHub App | Create `fishbowl-{role}` app on GitHub.com. Permissions: issues (r/w), contents (read), PRs (read). Install on `YourMoveLabs/agent-fishbowl`. |
| 12 | PEM Key | Generate private key from GitHub App settings → save to `~/.config/agent-fishbowl/fishbowl-{role}.pem` on runner VM |
| 13 | .env vars | Add to `~/.config/agent-harness/.env` on runner VM (`20.127.56.119`): `GITHUB_APP_{ROLE_UPPER}_ID`, `_INSTALLATION_ID`, `_KEY_PATH`, `_USER_ID`, `_BOT_NAME` |
| 14 | Blob container | If agent uploads to blob storage: `az storage container create --account-name agentfishbowlstorage --name {container} --auth-mode login` |
| 15 | API keys | If agent needs external APIs (Stripe, analytics, etc.): add keys to runner `.env` |
| 16 | Harness tag | After all harness changes pushed, create new tag: `git tag -a vX.Y.Z -m "..." && git push origin vX.Y.Z` |
| 17 | Workflow version | Update reusable workflow `reusable-agent.yml` harness ref if needed |

## Role Configuration (`config/roles.json`)

Every role needs an entry in `config/roles.json`. This is the single source of truth for tool allowlists and prompt partial eligibility.

```json
{
  "roles": {
    "your-new-role": {
      "tools": "${API}",
      "partials": ["reflection", "knowledge-base"]
    }
  }
}
```

**Fields:**

| Field | Required | Description |
|-------|----------|-------------|
| `tools` | Yes | Claude Code `--allowedTools` string. Use `${COMMON}` or `${API}` presets, or specify explicitly. |
| `partials` | Yes | Array of prompt partials to append. Options: `"reflection"`, `"knowledge-base"`, or `[]` for none. |
| `instances` | No | Array of instance slugs (e.g., `["engineer-alpha", "engineer-bravo"]`). Instances share parent's tools, partials, and prompt. |
| `prompt_role` | No | Override prompt file lookup (e.g., `"po"` makes it use `prompts/po.md` instead of `prompts/product-owner.md`). |
| `deprecated` | No | Name of the replacement role. Prints warning, uses deprecated role's own config. |

**Tool presets** (defined in `_tool_presets`):

| Preset | Expands to |
|--------|-----------|
| `${COMMON}` | `Bash(gh:*),Bash(git:*),Bash(cat:*),Read,Glob,Grep` |
| `${API}` | `Bash(curl:*),Bash(az:*),Bash(gh:*),Bash(jq:*),Bash(cat:*),Bash(date:*),Bash(scripts/*),Read,Glob,Grep` |

**Tool categories mapped to config values:**

| Category | `tools` value | Used by |
|----------|---------------|---------|
| `read-only` | `${COMMON},Bash(scripts/*)` | Product Owner, Reviewer, Triage, UX, Escalation Lead |
| `api-caller` | `${API}` | Content Creator, Product Analyst, Financial Analyst, etc. |
| `strategic` | `Bash(gh:*),Bash(cat:*),Bash(scripts/*),Read` | Product Manager |
| `code-writer` | Full explicit list (see engineer in config) | Engineer |
| `code-reviewer` | `${COMMON},Bash(ruff:*),Bash(npx:*),Bash(pip:*),Bash(scripts/*),Write,Edit` | Tech Lead |

## Workflow Templates

### Simple agent (uses reusable workflow)

```yaml
name: "Agent: {Display Name}"

on:
  schedule:
    - cron: "{schedule}"
  workflow_dispatch: {}

permissions:
  contents: read
  issues: write

jobs:
  run:
    uses: ./.github/workflows/reusable-agent.yml
    with:
      role: {role}
    secrets: inherit
```

### Agent with orchestration script

```yaml
name: "Agent: {Display Name}"

on:
  schedule:
    - cron: "{schedule}"
  workflow_dispatch: {}

permissions:
  contents: read
  issues: write

jobs:
  run:
    uses: ./.github/workflows/reusable-agent.yml
    with:
      entry-point: scripts/run-{role}.sh
    secrets: inherit
```

### Agent with post-dispatch steps (needs its own job definition)

```yaml
name: "Agent: {Display Name}"

on:
  schedule:
    - cron: "{schedule}"
  workflow_dispatch: {}

permissions:
  contents: read
  issues: write
  actions: write

concurrency:
  group: agent-{role}
  cancel-in-progress: false

jobs:
  run:
    name: Run {Display Name} agent
    runs-on: self-hosted
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4

      - name: Run {Display Name} agent
        uses: YourMoveLabs/agent-harness@v1.2.0
        with:
          role: {role}
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Dispatch PO if intake batch ready
        if: success()
        run: .harness/scripts/lib/dispatch-po-if-ready.sh
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Prompt Structure Template

Every prompt follows this structure:

```markdown
# {Display Name} Agent

You are the {Display Name} Agent. Your job is {purpose}. You do NOT {anti-patterns}. You must complete ALL steps below.

**First**: Read `CLAUDE.md` to understand the project's architecture, current phase, and domain.

## Voice

{2-3 sentences describing persona and communication style}

## Sandbox Compatibility

{Standard sandbox rules — same for all non-code agents}

## Available Tools

| Tool | Purpose | Example |
|------|---------|---------|
| ... | ... | ... |

## Step 1: {First step}
...

## Step N: STOP
**STOP here.** One {unit of work} per run.

## Rules
- **Always label issues with `agent-created`.**
- **One {unit} per run.** {Explanation}
- {Role-specific rules}
```

## Coordination Patterns

| Pattern | Label | Flow |
|---------|-------|------|
| Agent creates work for PO to triage | `source/{role}` | Agent → PO Step 3 intake |
| Agent proposes to PM for roadmap | `source/{role}` | Agent → PM Step 4.5+ review |
| Agent dispatches another agent | `repository_dispatch` | Agent → `scripts/dispatch-agent.sh` → target workflow |
| Agent is dispatched by another | `repository_dispatch` | Source workflow → target `agent-{role}.yml` |
| Agent escalates to human | `escalation/human` | Agent → human reviews issue |

## Naming Conventions

| Resource | Pattern | Example |
|----------|---------|---------|
| Role slug | `kebab-case` | `product-analyst` |
| Prompt file | `agents/prompts/{slug}.md` | `agents/prompts/product-analyst.md` |
| Config entry | `roles.{slug}` in `config/roles.json` | `"product-analyst": {...}` |
| Workflow | `agent-{slug}.yml` | `agent-product-analyst.yml` |
| GitHub App | `fishbowl-{slug}` | `fishbowl-product-analyst` |
| Bot name | `fishbowl-{slug}[bot]` | `fishbowl-product-analyst[bot]` |
| Env var prefix | `GITHUB_APP_{SLUG_UPPER}_*` | `GITHUB_APP_PRODUCT_ANALYST_*` |
| Source label | `source/{slug}` | `source/product-analyst` |
| Concurrency group | `agent-{slug}` | `agent-product-analyst` |
