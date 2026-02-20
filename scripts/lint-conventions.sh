#!/bin/bash
# Check project conventions that ruff/eslint don't cover.
# Error messages are written to be read by AI agents — each includes a FIX instruction.
set -uo pipefail

FAILED=0

# --- Branch name convention ---
BRANCH=$(git branch --show-current 2>/dev/null || echo "")

if [ -n "$BRANCH" ] && [ "$BRANCH" != "main" ]; then
    if ! echo "$BRANCH" | grep -qE '^(feat|fix|chore)/issue-[0-9]+-'; then
        echo "ERROR: Branch name '$BRANCH' doesn't match the required pattern."
        echo "  PATTERN: feat/issue-{N}-description, fix/issue-{N}-description, or chore/issue-{N}-description"
        echo "  FIX: Create a new branch with: scripts/create-branch.sh <issue_number> [feat|fix]"
        echo "  Example: scripts/create-branch.sh 42 feat"
        FAILED=1
    fi
fi

# --- PR description must reference an issue (only check if we're in a PR context) ---
# This runs during `gh pr create` validation or CI — skip if no PR context
if [ -n "${GITHUB_HEAD_REF:-}" ] || [ -n "${PR_BODY:-}" ]; then
    BODY="${PR_BODY:-}"
    if [ -z "$BODY" ] && command -v gh &>/dev/null; then
        BODY=$(gh pr view --json body --jq '.body' 2>/dev/null || echo "")
    fi
    if [ -n "$BODY" ]; then
        if ! echo "$BODY" | grep -qiE '(closes|fixes|resolves)\s+#[0-9]+'; then
            echo "ERROR: PR description must reference an issue."
            echo "  PATTERN: Include 'Closes #N', 'Fixes #N', or 'Resolves #N' in the PR body."
            echo "  FIX: Edit the PR description to add 'Closes #<issue_number>' on its own line."
            FAILED=1
        fi
    fi
fi

# --- File size guard (agents sometimes generate bloated files) ---
MAX_LINES=500
LARGE_FILES=$(find api/ frontend/src/ -path 'api/.venv' -prune -o -type f \( -name "*.py" -o -name "*.ts" -o -name "*.tsx" \) -exec awk -v max="$MAX_LINES" -v f="{}" 'END { if (NR > max) print f " (" NR " lines)" }' {} \; 2>/dev/null)

if [ -n "$LARGE_FILES" ]; then
    echo "WARNING: Files exceeding $MAX_LINES lines:"
    echo "$LARGE_FILES" | while read -r line; do echo "  $line"; done
    echo "  GUIDELINE: Large files are harder to maintain. Consider splitting into smaller modules."
    echo "  This is a warning, not a failure."
fi

# --- httpx import guard ---
# All HTTP calls should use http_client.py helper, not raw httpx
if [ -d "api/services" ]; then
    HTTPX_VIOLATIONS=$(grep -rl "import httpx" api/services/ api/routers/ \
        --include="*.py" 2>/dev/null \
        | grep -v "http_client.py" \
        | grep -v "tests/" || true)

    # Allowlist for known exceptions (existing debt)
    HTTPX_ALLOWLIST="ingestion/rss.py|ingestion/scraper.py|routers/blog.py|goals_metrics.py"
    HTTPX_NEW=$(echo "$HTTPX_VIOLATIONS" | grep -vE "$HTTPX_ALLOWLIST" | grep -v '^$' || true)

    if [ -n "$HTTPX_NEW" ]; then
        echo "ERROR: New files importing httpx directly (use http_client.py helper):"
        echo "$HTTPX_NEW" | while read -r f; do echo "  $f"; done
        echo "  FIX: Import and use github_api_get() or the shared HTTP client instead."
        FAILED=1
    fi
fi

# --- Agent workflow/map consistency ---
# Detect when new agent-*.yml workflows are added but maps aren't updated
if [ -d ".github/workflows" ] && [ -f "api/services/github_status.py" ]; then
    WORKFLOW_COUNT=$(find .github/workflows -name "agent-*.yml" 2>/dev/null | wc -l)
    MAP_ENTRIES=$(grep -c '"agent-' api/services/github_status.py 2>/dev/null || echo "0")
    if [ "$WORKFLOW_COUNT" -gt "$((MAP_ENTRIES + 3))" ]; then
        echo "WARNING: $WORKFLOW_COUNT agent workflows but only ~$MAP_ENTRIES map entries"
        echo "  Check api/services/github_status.py WORKFLOW_AGENT_MAP for completeness"
        echo "  This is a warning, not a failure."
    fi
fi

if [ $FAILED -ne 0 ]; then
    exit 1
else
    echo "  PASS (conventions)"
    exit 0
fi
