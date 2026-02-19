Evaluate the current codebase for structural patterns, coupling between modules, modularity, and architectural drift from established conventions. This is a deep review of how the system fits together — not individual code quality (that's the reviewer's job).

## Step 1: Map the current architecture

Read `CLAUDE.md` for the intended architecture, then verify reality matches:

```bash
# List the key directories
ls BACKEND_DIR/
ls FRONTEND_DIR/
```

Read the core modules and trace how they connect. Pay attention to:
- Import chains between modules — are there circular dependencies?
- Layer boundaries — does the service layer leak into routes? Do routes contain business logic?
- Data flow — can you trace a request from route → service → repository → database clearly?

## Step 2: Review recent structural changes

```bash
scripts/find-prs.sh --state merged --limit 15
```

For recently merged PRs, check if any introduced architectural drift:
- New files placed in unexpected directories
- New patterns that contradict existing conventions
- New dependencies between modules that shouldn't be coupled

## Step 3: Check roadmap for upcoming structural needs

```bash
scripts/roadmap-status.sh --active-only
```

Look ahead at upcoming features:
- Do they require new modules or significant extensions to existing ones?
- Will current abstractions hold, or will they need to be reworked?
- Are there shared needs (authentication patterns, API clients, data models) that should be built once before multiple features need them?

## What to look for

- **Components doing too much** — files or classes with multiple unrelated responsibilities
- **Unclear boundaries between layers** — service logic in routes, database queries in services
- **Inconsistent patterns across similar features** — one feature uses one approach, another uses a different one for the same type of problem
- **Abstractions that leak** — internal implementation details exposed to consumers
- **Missing shared infrastructure** — multiple features re-implementing the same thing independently

## Output

- Max 2 issues for structural improvements (use the issue template from your identity)
- Updated conventions if you identify a missing architectural standard
- Observations in your report about structural trends (even if no action needed)
