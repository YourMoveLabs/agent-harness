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
| 2 | `agents/{role}.sh` | **CREATE** | One-liner: `exec "$(dirname "$0")/run-agent.sh" {role}` |
| 3 | `agents/run-agent.sh` | **EDIT** | Add case to tool allowlist + update usage/roles line |
| 4 | `scripts/run-{role}.sh` | **CREATE** (optional) | Orchestration with pre-flight checks. Use if agent needs setup validation before running. |
| 5 | `docs/project-board-readme.md` | **EDIT** | Add to "The Team" section with role description |

### Agent Fishbowl (`YourMoveLabs/agent-fishbowl`)

| # | File | Action | Notes |
|---|------|--------|-------|
| 6 | `.github/workflows/agent-{role}.yml` | **CREATE** | Schedule + `workflow_dispatch`, uses harness composite action |
| 7 | `CLAUDE.md` | **EDIT** | Add to: workflows table, project structure, coordination flow, source labels |
| 8 | Labels | **CREATE** | `source/{role}` (if creates intake issues), via `gh label create` |

### Cross-Agent Prompt Updates (agent-harness)

| # | File | Condition | Action |
|---|------|-----------|--------|
| 9 | `agents/prompts/po.md` | Agent creates `source/*` intake issues for the PO | Add `find-issues.sh --label "source/{role}"` to Step 3 intake scan |
| 10 | `agents/prompts/triage.md` | Agent creates `source/*` issues | Add `--no-label "source/{role}"` to Step 1 exclusion filter |
| 11 | `agents/prompts/pm.md` | Agent reports proposals to the PM | Add review step for `source/{role}` issues |

### Infrastructure (Human Tasks)

| # | Task | Details |
|---|------|---------|
| 12 | GitHub App | Create `fishbowl-{role}` app on GitHub.com. Permissions: issues (r/w), contents (read), PRs (read). Install on `YourMoveLabs/agent-fishbowl`. |
| 13 | PEM Key | Generate private key from GitHub App settings → save to `~/.config/agent-fishbowl/fishbowl-{role}.pem` on runner VM |
| 14 | .env vars | Add to `~/.config/agent-harness/.env` on runner VM (`20.127.56.119`): `GITHUB_APP_{ROLE_UPPER}_ID`, `_INSTALLATION_ID`, `_KEY_PATH`, `_USER_ID`, `_BOT_NAME` |
| 15 | Blob container | If agent uploads to blob storage: `az storage container create --account-name agentfishbowlstorage --name {container} --auth-mode login` |
| 16 | API keys | If agent needs external APIs (Stripe, analytics, etc.): add keys to runner `.env` |
| 17 | Harness tag | After all harness changes pushed, create new tag: `git tag -a vX.Y.Z -m "..." && git push origin vX.Y.Z` |
| 18 | Workflow version | Update `.github/workflows/agent-{role}.yml` to reference new harness tag |

## Tool Category Reference

| Category | Allowlist | Used By |
|----------|-----------|---------|
| `read-only` | `${COMMON_TOOLS},Bash(scripts/*)` | PO, Reviewer, Triage, UX |
| `api-caller` | `Bash(curl:*),Bash(az:*),Bash(gh:*),Bash(jq:*),Bash(cat:*),Bash(date:*),Bash(scripts/*),Read,Glob,Grep` | Writer, Product Analyst, SRE |
| `strategic` | `Bash(gh:*),Bash(cat:*),Bash(scripts/*),Read` | PM (no Glob/Grep — product-level only) |
| `code-writer` | `Bash(gh:*),Bash(git:*),Bash(ruff:*),Bash(npx:*),Bash(pip:*),Bash(scripts/*),Bash(cat:*),Bash(chmod:*),Read,Write,Edit,Glob,Grep` | Engineer |
| `code-reviewer` | `${COMMON_TOOLS},Bash(ruff:*),Bash(npx:*),Bash(pip:*),Bash(scripts/*),Write,Edit` | Tech Lead |

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
| Wrapper | `agents/{slug}.sh` | `agents/product-analyst.sh` |
| Workflow | `agent-{slug}.yml` | `agent-product-analyst.yml` |
| GitHub App | `fishbowl-{slug}` | `fishbowl-product-analyst` |
| Bot name | `fishbowl-{slug}[bot]` | `fishbowl-product-analyst[bot]` |
| Env var prefix | `GITHUB_APP_{SLUG_UPPER}_*` | `GITHUB_APP_PRODUCT_ANALYST_*` |
| Source label | `source/{slug}` | `source/product-analyst` |
| Concurrency group | `agent-{slug}` | `agent-product-analyst` |
