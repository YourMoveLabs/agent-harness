# Agent Harness

Agent team infrastructure for autonomous software development. Contains generic agent prompts, the runner script, utility scripts, and a GitHub Actions composite action.

**Philosophy**: See [docs/philosophy.md](docs/philosophy.md) for the full thesis on why this exists.

## What's Here

```
agents/
  run-agent.sh          # Core runner: identity, tools, Claude invocation
  {role}.sh             # Role wrappers (engineer, po, reviewer, etc.)
  prompts/{role}.md     # Generic role prompts (read CLAUDE.md for project context)
scripts/
  dispatch-agent.sh     # Cross-agent orchestration (repository_dispatch)
  run-site-reliability.sh # Site Reliability controller (playbook routing + Claude escalation)
  run-scans.sh          # Tech Lead + UX scan orchestration
  run-strategic.sh      # PM strategic review orchestration
  run-triage.sh         # Triage pre-check orchestration
  find-issues.sh        # Agent tool: issue queries
  find-prs.sh           # Agent tool: PR queries
  check-duplicates.sh   # Agent tool: duplicate detection
  project-fields.sh     # Agent tool: GitHub Project field mapping
  roadmap-status.sh     # Agent tool: roadmap status
  workflow-status.sh    # Agent tool: workflow queries
  file-stats.sh         # Agent tool: codebase metrics
  setup-labels.sh       # Label bootstrapping
  lint-conventions.sh   # Convention enforcement
action.yml              # Composite action (the bridge between repos)
```

## Usage

### In GitHub Actions (project repo)

Project workflows use the composite action to pull in the harness:

```yaml
steps:
  - uses: actions/checkout@v4

  - uses: YourMoveLabs/agent-harness@main
    with:
      entry-point: agents/engineer.sh
```

### Local Development

```bash
# Clone both repos side by side
git clone git@github.com:YourMoveLabs/agent-harness.git
git clone git@github.com:YourMoveLabs/agent-fishbowl.git

# Run an agent locally
cd agent-fishbowl
HARNESS_ROOT=../agent-harness PROJECT_ROOT=$(pwd) ../agent-harness/agents/engineer.sh
```

## Environment Variables

| Variable | Purpose | Where Set |
|----------|---------|-----------|
| `HARNESS_ROOT` | Path to harness checkout | Composite action |
| `PROJECT_ROOT` | Path to project checkout | Composite action |
| `GITHUB_APP_{ROLE}_ID` | GitHub App ID per role | `.env` |
| `GITHUB_APP_{ROLE}_INSTALLATION_ID` | Installation ID | `.env` |
| `GITHUB_APP_{ROLE}_KEY_PATH` | PEM key path | `.env` |
| `REVIEWER_BOT_NAME` | Reviewer bot login name | `.env` (optional) |
| `PROJECT_NUMBER` | GitHub Project number | `.env` (optional, default: 1) |
| `PROJECT_OWNER` | GitHub org/user | `.env` (optional, default: YourMoveLabs) |
| `SOURCE_DIRS` | Colon-separated source dirs for file-stats | `.env` (optional, auto-detect) |

## How It Works

1. Project workflow triggers (schedule, dispatch, PR, manual)
2. Composite action checks out this harness repo to `.harness/`
3. Sets `HARNESS_ROOT` and `PROJECT_ROOT` environment variables
4. Loads `.env` from project or runner config
5. Runs the specified entry point (agent or orchestration script)
6. Agent reads `CLAUDE.md` from project root for context
7. Agent executes its role using project-agnostic prompts
