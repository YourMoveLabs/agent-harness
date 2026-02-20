Review the project's quality gates — pre-commit hooks, CI checks, linters, and build pipeline — for gaps and improvement opportunities. The goal is catching bugs deterministically before they reach code review, not after.

## Step 1: Inventory current quality gates

Check what's enforced automatically:

```bash
cat .pre-commit-config.yaml 2>/dev/null || echo "No pre-commit config"
```

```bash
scripts/run-checks.sh --help 2>/dev/null || echo "No run-checks script"
```

```bash
ls .github/workflows/
```

Map what's currently enforced:
- **Pre-commit**: What runs before every commit? (linting, formatting, type checks, tests)
- **CI on PR**: What runs on pull requests? (tests, build, lint, security scans)
- **CI on merge**: What runs after merge to main? (deploy, integration tests, release)
- **Manual only**: What quality checks exist but aren't automated?

## Step 2: Identify gaps in the pipeline

Compare what's enforced against what could be:
- **Missing linting rules** — code patterns that cause bugs but aren't caught by any linter
- **Missing type checking** — are type annotations enforced? Is there a type checker in CI?
- **Missing test gates** — are tests required to pass before merge?
- **Missing format enforcement** — is code formatting consistent, or does it drift?
- **Missing dependency checks** — are outdated or vulnerable deps flagged automatically?

## Step 3: Review recent CI failures

```bash
scripts/find-prs.sh --state merged --limit 15
```

Look at recent PRs for CI patterns:
- **Repeated failures** — same type of failure appearing across multiple PRs (suggests a missing pre-commit check)
- **Flaky checks** — tests or builds that fail intermittently (suggests a stability issue)
- **Slow checks** — steps that take too long and slow down the feedback loop
- **Bypassed checks** — PRs merged despite failing checks (suggests the gates aren't trusted)

## Step 4: Evaluate script and tooling opportunities

Look for manual processes that could be scripted:
- Are there checks the reviewer catches every time that a linter rule could enforce?
- Are there validation steps developers run manually that could be a pre-commit hook?
- Are there data format or schema validations that could be automated?
- Are there build or deployment steps that could fail earlier with better validation?

## What to look for

- **Missing deterministic checks** — bugs that reach review because no automated check catches them
- **Slow feedback loops** — checks that run in CI but could run locally in pre-commit
- **Untrusted pipeline** — checks that fail so often they get ignored or bypassed
- **Missing scripts** — manual processes that should be `scripts/*.sh` with `--help`
- **Package opportunities** — third-party tools or plugins that would add valuable checks

## Output

- Up to 2 issues for pipeline improvements; zero if pipeline is solid (use the issue template from your identity)
- Add `type/tooling` label alongside `source/tech-lead`
- Each issue should describe: what the tool/check does, where it runs (pre-commit vs CI), and what bugs it would catch
