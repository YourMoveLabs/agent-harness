Review the project's test suite for coverage gaps, broken tests, and quality issues. Good tests catch bugs before they ship; missing tests let bugs through.

## Step 1: Inventory the test suite

Find all test files and understand the test structure:

```bash
scripts/file-stats.sh
```

Look at the test directories and files:
- What test frameworks are in use?
- How are tests organized (unit vs integration, by feature, by layer)?
- What's the approximate test count?

## Step 2: Check for untested critical paths

Read `CLAUDE.md` and `config/conventions.md` to understand what the project considers critical:

```bash
cat CLAUDE.md
```

Cross-reference critical paths against test coverage:
- **Authentication/authorization** — are auth flows tested?
- **Payment/billing logic** — are credit operations, subscriptions tested?
- **State machines** — are status transitions tested (draft → processing → ready → published)?
- **External integrations** — are API contracts with external services tested?
- **Error handling** — are failure cases tested, not just happy paths?

## Step 3: Check recent CI for test failures

```bash
scripts/find-prs.sh --state merged --limit 10
```

Look at recent PRs for patterns:
- Are tests failing intermittently (flaky tests)?
- Are new features being merged without corresponding tests?
- Are test failures being fixed or just retried?

## Step 4: Review test quality

Read a sample of test files to assess quality:
- Do tests test behavior or implementation details?
- Are tests independent (no ordering dependencies)?
- Are test fixtures well-organized and reusable?
- Are tests named descriptively (can you understand what failed from the name)?

## What to look for

- **Coverage gaps** — critical code paths with no tests at all
- **Flaky tests** — tests that pass sometimes and fail sometimes (undermines CI trust)
- **Missing test types** — only unit tests when integration tests are needed, or vice versa
- **Dead tests** — tests that are skipped, commented out, or test deleted code
- **Test anti-patterns** — tests that mock everything (test nothing), overly broad assertions

## Output

- Up to 2 issues for test improvements; zero if test suite is adequate (use the issue template from your identity)
- Add `testing` label alongside `source/tech-lead`
- Prioritize coverage gaps on critical paths over general test quality improvements
