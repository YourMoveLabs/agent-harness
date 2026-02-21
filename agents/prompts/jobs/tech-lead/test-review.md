Sweep the test suite to ensure tests are actually protecting the project — not just inflating counts or creating false confidence. A test that passes but wouldn't catch a real bug is worse than no test: it makes the team *feel* safe without *being* safe.

## Step 1: Run coverage (programmatic)

Run the test suite with coverage reporting — let the tool measure what's tested:

```bash
scripts/test-coverage.sh
```

This gives you hard data: pass/fail counts, per-file coverage percentages, and which lines are uncovered. **Do not guess at coverage — read the numbers.**

From the output, note:
- Any failing tests (your first priority — a red suite everyone ignores is the worst form of false confidence)
- Files with very low coverage on critical paths (auth, billing, state machines, integrations)
- Files with suspiciously high coverage that you should spot-check for test quality
- Skipped or xfail tests — why are they skipped?

## Step 2: Read tests critically (AI judgment)

Now use the coverage data to guide your reading. The tool told you *what* is tested; your job is to evaluate *how well*.

Sample 3-5 test files — prioritize:
- Files the coverage report shows as high-coverage on critical paths (verify the coverage is meaningful, not illusory)
- Files with the most tests (high test count doesn't mean high value)
- Any test files that correspond to low-coverage source files (understand why coverage is low)

For each test you read, ask:

1. **What does this test prove?** State it in one sentence. If you can't, the test is unclear.
2. **Could the code be broken in a way this test wouldn't catch?** If yes, the test may be giving false confidence on that code path.
3. **Is this testing the application or testing the mocks?** If every dependency is mocked and the assertion is just "mock was called with args X" — the test proves nothing about whether the real system works.
4. **Would deleting this test make the codebase less safe?** If no, it's noise.

## Step 3: Identify false confidence

Look specifically for these patterns:

- **Over-mocked tests**: Every collaborator is mocked; the test only verifies that mocks were called. This tests your test setup, not your application.
- **Assertion-free tests**: Tests that just call a function and check it "doesn't throw." This only tests the happy path exists, not that it works correctly.
- **Tautological tests**: Tests where the expected value is computed the same way as the actual value (e.g., building the expected dict by copying the same logic the function uses).
- **Duplicate coverage**: Multiple tests that exercise the same code path with trivially different inputs, without testing meaningfully different behavior.
- **Happy-path-only on complex code**: Code with significant error handling or branching logic where tests only cover the success case. The test suite says "covered" but the dangerous parts are untested.

## Step 4: Identify noise

Tests that cause maintenance burden without catching bugs:

- **Implementation-coupled tests**: Tests that break whenever the code is refactored but wouldn't catch a behavioral bug. Example: asserting on internal method calls, specific SQL query strings, or exact log messages.
- **Dead tests**: Skipped, commented out, or testing deleted features. These clutter the suite and slow CI.
- **Trivial tests**: Testing that a constant equals itself, that a constructor sets attributes, or that a simple getter returns a field. These pad coverage without providing safety.
- **Flaky tests**: Tests that pass/fail non-deterministically. These train the team to ignore red CI.

## Step 5: Cross-reference coverage with critical paths

Use the coverage numbers from Step 1 to identify where coverage gaps *matter most*. Not all uncovered code is equal — focus on areas where bugs would be costly:

- **Authentication/authorization** — what does the coverage report show? Are auth modules tested with realistic scenarios, or just "mock returns True"?
- **Payment/billing** — are financial operations covered? Check for edge cases (insufficient credits, concurrent requests), not just happy paths.
- **State machines** — are all valid transitions tested? Are invalid transitions rejected?
- **External integrations** — API contract tests? Error handling for timeouts, rate limits, malformed responses?
- **Data integrity** — concurrent writes, uniqueness constraints, cascade deletes?

A coverage gap on a critical path is more important than 10 low-value tests on non-critical code. Conversely, 95% coverage on a billing module that only tests the happy path is false confidence.

## Step 6: Net assessment

Summarize: Is the test suite making the team **faster** (catching real issues, enabling confident refactors) or **slower** (maintenance burden, false confidence, noise)?

Rate the suite honestly:
- **Healthy**: Tests catch real bugs, coverage is focused on what matters, minimal noise
- **Mixed**: Some valuable tests alongside noise — net positive but needs pruning
- **False confidence**: High test count but tests don't catch real issues — worse than fewer, better tests
- **Neglected**: Tests are failing, skipped, or clearly outdated — the suite has been abandoned

## What to look for

- **Tests to delete** — If a test provides zero safety, recommend deleting it. Fewer, better tests > more, weaker tests.
- **Tests to strengthen** — Tests that cover the right code but with weak assertions. Suggest specific improvements.
- **Missing tests that matter** — Critical paths with no meaningful coverage. Focus on where bugs would be costly.
- **Structural issues** — Fixture sprawl, slow test runs, poor isolation that discourages writing good tests.

## Output

- Up to 2 issues for test improvements; zero if test suite is adequate
- Add `testing` label alongside `source/tech-lead`
- Each issue should be specific: name the test files, explain what's wrong, and propose what a better test looks like
- Prioritize: (1) false confidence on critical paths, (2) noise removal, (3) coverage gaps
