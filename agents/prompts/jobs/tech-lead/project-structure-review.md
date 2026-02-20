Review the project's file organization, directory structure, and naming conventions. Good structure makes the codebase navigable; bad structure makes every task harder.

## Step 1: Map actual structure against documented structure

Read `CLAUDE.md` for the intended directory layout:

```bash
cat CLAUDE.md
```

Then verify reality matches:

```bash
# List top-level directories and key subdirectories
```

Look for:
- Directories that exist in docs but not on disk (or vice versa)
- Files placed in unexpected locations (e.g., a route file in services/, a model in blueprints/)
- Empty directories or placeholder files that serve no purpose

## Step 2: Check file sizes and complexity

```bash
scripts/file-stats.sh --over-limit 500
```

Look for:
- Oversized files that should be split (multiple responsibilities in one file)
- Files that have grown far beyond their original scope
- Directories with too many files (suggests need for subdirectories)

## Step 3: Review naming conventions

Scan file and directory names for consistency:
- **Backend files**: Are they consistently `snake_case.py`?
- **Frontend components**: Are they consistently `PascalCase.vue`?
- **Route files**: Do they follow the `*_routes.py` pattern?
- **Service files**: Do they follow the `*_service.py` pattern?
- **Test files**: Do they follow `test_*.py` or `*.test.js` patterns?

## Step 4: Check for orphaned files

Look for files that may no longer be needed:
- Source files that are never imported by any other file
- Config files that are no longer referenced
- Script files that are no longer called from anywhere
- Legacy files from removed features

## What to look for

- **Misplaced files** — files in the wrong directory for their purpose
- **Naming inconsistencies** — mixed naming conventions within the same layer
- **Overgrown files** — files that should be split into focused modules
- **Orphaned artifacts** — files that serve no purpose and add clutter
- **Missing structure** — flat directories that need organization as they grow

## Output

- Up to 2 issues for structural improvements; zero if structure is clean (use the issue template from your identity)
- Add `structure` label alongside `source/tech-lead`
- Be specific about what should move where — vague "reorganize this" issues aren't actionable
