Identify accumulated technical debt in the codebase. Tech debt is code that works but makes future work harder, slower, or riskier. Focus on debt that's actively causing friction, not theoretical concerns.

## Step 1: Find aging TODOs and FIXMEs

Search for TODO/FIXME comments and assess their age and relevance:

```bash
# Search for TODO/FIXME markers in source files
```

Categorize what you find:
- **Stale TODOs** — things that should have been done long ago or are no longer relevant
- **Valid TODOs** — legitimate future work that should be tracked as issues
- **FIXMEs** — known problems that need attention

## Step 2: Check for dead code and unused dependencies

```bash
scripts/file-stats.sh --over-limit 500
```

Look for:
- Files that are never imported or referenced
- Dependencies in package files that aren't used in source code
- Feature flags or config options that are always one value
- Test files that don't run or test deprecated code

## Step 3: Review duplication and abstraction opportunities

Read through the codebase looking for repeated patterns:
- Same logic copy-pasted across multiple files
- Similar functions that differ only slightly (candidates for parameterization)
- Boilerplate that could be generated or abstracted
- Inconsistent error handling (some places handle errors, some don't)

## Step 4: Check for dependency freshness

Review dependency files for outdated packages:
- Major version upgrades available (potential breaking changes to plan)
- Minor/patch updates with bug fixes or security patches
- Deprecated packages that should be replaced

## What to look for

- **Active friction** — debt that's causing real problems (failing tests, blocking features, recurring bugs in reviews)
- **Growing debt** — patterns that get worse as the codebase grows (duplicated logic that must be updated in N places)
- **Stale artifacts** — dead code, unused configs, outdated comments that mislead developers
- **Missing automation** — manual processes that should be scripted or enforced by tooling

## Output

- Max 2 issues for the highest-impact tech debt (use the issue template from your identity)
- Be honest about urgency — most tech debt can wait. Flag it only when it's actively causing friction or will compound.
- Updated conventions if you identify a pattern that should be enforced to prevent future debt
