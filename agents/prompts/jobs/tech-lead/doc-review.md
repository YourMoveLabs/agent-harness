Review project documentation for accuracy, freshness, and completeness. Stale or incorrect docs are worse than no docs — they actively mislead developers and agents.

## Step 1: Check core documentation against reality

Read the main documentation files:

```bash
cat CLAUDE.md
```

```bash
cat config/conventions.md 2>/dev/null || echo "No conventions.md"
```

```bash
cat config/goals.md 2>/dev/null || echo "No goals.md"
```

For each documented claim, spot-check against the actual codebase:
- **File paths**: Do the directories and files mentioned actually exist?
- **API endpoints**: Are documented endpoints still present in the route files?
- **Environment variables**: Are documented env vars still used in the code?
- **Architecture descriptions**: Does the described structure match reality?

## Step 2: Check for undocumented features

Review recently merged PRs for features that might be missing from docs:

```bash
scripts/find-prs.sh --state merged --limit 15
```

Look for:
- New endpoints, services, or modules added without doc updates
- Changed behavior that contradicts existing documentation
- New configuration options not mentioned in README or CLAUDE.md

## Step 3: Review README files

Check README files across the project:

```bash
# Find all README files
```

For each README:
- Are setup instructions still accurate?
- Do example commands work with current file paths?
- Are prerequisites and dependencies up to date?

## Step 4: Check for contradictions

Look for places where different docs contradict each other:
- CLAUDE.md says one thing, conventions.md says another
- README instructions conflict with actual file structure
- Inline code comments describe behavior that no longer matches

## What to look for

- **Stale content** — docs describing removed features, old file paths, deprecated patterns
- **Missing docs** — new features with no documentation at all
- **Contradictions** — different docs claiming different things about the same topic
- **Misleading examples** — code samples that won't work with the current codebase

## Output

- Up to 2 issues for documentation problems; zero if docs are accurate (use the issue template from your identity)
- Add `docs` label alongside `source/tech-lead`
- Each issue should specify: what's wrong, where it is, and what the correct information should be
