Comprehensive scan of the codebase — review recent work, check the roadmap, and evaluate overall health. This is the broadest scan; use it when no specific focus area is scheduled.

## Step 1: Review recent work

Check recently merged PRs to spot patterns:

```bash
scripts/find-prs.sh --state merged --limit 10
```

For each recent PR, read the review comments to find recurring feedback:

```bash
gh pr view N --comments
```

Look for:
- **Repeated reviewer feedback** — same type of comment appearing across multiple PRs
- **Copy-pasted patterns** — same boilerplate appearing in multiple places
- **Missing conventions** — things the reviewer has to catch because there's no written standard

## Step 2: Check the roadmap for architectural needs

```bash
scripts/roadmap-status.sh --active-only
```

Look ahead at upcoming features and active roadmap items:
- Do upcoming features share common needs that should be built once (shared utilities, abstractions)?
- Is any part of the codebase going to become a bottleneck as more features land?
- Are there dependencies between roadmap items that the PO should know about?

## Step 3: Evaluate current codebase health

Check file sizes and codebase metrics:

```bash
scripts/file-stats.sh --over-limit 500
```

Read through the key source files to assess the codebase:

Use the directory structure from `CLAUDE.md` to locate source directories:
```bash
# List the key backend and frontend directories described in CLAUDE.md
ls BACKEND_DIR/
ls FRONTEND_DIR/
```

Read the core files and evaluate:
- **Consistency**: Do similar operations follow the same patterns?
- **Abstraction**: Are there duplicated patterns that should be extracted?
- **Scalability**: Will current patterns hold as more features are added?
- **Dependencies**: Are there outdated or problematic packages?

Check dependency files (requirements.txt, pyproject.toml, package.json, etc.) for outdated or problematic packages.

## Output

- Up to 2 issues for the highest-impact findings (use the issue template from your identity)
- Zero issues is fine — if the codebase is healthy, report that and move on
- Focus on what matters most; don't create issues for minor concerns
