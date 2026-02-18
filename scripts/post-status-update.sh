#!/bin/bash
# post-status-update.sh — Post a GitHub Project V2 status update.
# Wraps the createProjectV2StatusUpdate GraphQL mutation.
# Outputs JSON (the created status update) to stdout.
# Uses GH_TOKEN from environment for authentication.
set -euo pipefail

# --- Defaults ---
PROJECT_ID="PVT_kwDOD5pXLM4BPRda"
STATUS=""
BODY=""
START_DATE=""
TARGET_DATE=""

# --- Help ---
usage() {
    cat <<'EOF'
Usage: scripts/post-status-update.sh --status STATUS --body "MARKDOWN" [OPTIONS]

Post a status update to the GitHub Project board.

Required:
  --status STATUS       One of: INACTIVE, ON_TRACK, AT_RISK, OFF_TRACK, COMPLETE
  --body "TEXT"         Markdown body for the status update

Options:
  --start-date DATE     Start date (YYYY-MM-DD format, optional)
  --target-date DATE    Target date (YYYY-MM-DD format, optional)
  --project-id ID       Project node ID (default: PVT_kwDOD5pXLM4BPRda)
  --help                Show this help

Examples:
  # Simple status update
  scripts/post-status-update.sh --status ON_TRACK --body "All objectives on track."

  # With date range
  scripts/post-status-update.sh --status AT_RISK \
    --start-date "2026-02-17" --target-date "2026-02-21" \
    --body "Objective 3 at risk: no agent diversity in 48h."

Output: JSON with the created status update (id, status, createdAt).
EOF
    exit 0
}

# --- Parse args ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --status) STATUS="$2"; shift 2 ;;
        --body) BODY="$2"; shift 2 ;;
        --start-date) START_DATE="$2"; shift 2 ;;
        --target-date) TARGET_DATE="$2"; shift 2 ;;
        --project-id) PROJECT_ID="$2"; shift 2 ;;
        --help|-h) usage ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# --- Validate required args ---
if [[ -z "$STATUS" ]]; then
    echo "Error: --status is required" >&2
    exit 1
fi

if [[ -z "$BODY" ]]; then
    echo "Error: --body is required" >&2
    exit 1
fi

# Validate status enum
case "$STATUS" in
    INACTIVE|ON_TRACK|AT_RISK|OFF_TRACK|COMPLETE) ;;
    *) echo "Error: --status must be one of: INACTIVE, ON_TRACK, AT_RISK, OFF_TRACK, COMPLETE" >&2; exit 1 ;;
esac

# --- Build optional input fields ---
OPTIONAL_FIELDS=""
if [[ -n "$START_DATE" ]]; then
    OPTIONAL_FIELDS="${OPTIONAL_FIELDS}, startDate: \"${START_DATE}\""
fi
if [[ -n "$TARGET_DATE" ]]; then
    OPTIONAL_FIELDS="${OPTIONAL_FIELDS}, targetDate: \"${TARGET_DATE}\""
fi

# --- Escape body for GraphQL ---
ESCAPED_BODY=$(printf '%s' "$BODY" | jq -Rs '.')

# --- Execute GraphQL mutation ---
gh api graphql -f query="
mutation {
  createProjectV2StatusUpdate(input: {
    projectId: \"${PROJECT_ID}\"
    status: ${STATUS}
    body: ${ESCAPED_BODY}${OPTIONAL_FIELDS}
  }) {
    statusUpdate {
      id
      status
      createdAt
    }
  }
}" --jq '.data.createProjectV2StatusUpdate.statusUpdate'
