#!/bin/bash
# submit-knowledge.sh — Submit an organizational knowledge candidate to staging.
# Agents call this to record durable business insights for triage curation.
#
# Usage: scripts/submit-knowledge.sh --role ROLE --insight "TEXT"
set -euo pipefail

ROLE=""
INSIGHT=""
STORAGE_ACCOUNT="agentfishbowlstorage"
CONTAINER="org-knowledge"

usage() {
    cat <<'EOF'
Usage: scripts/submit-knowledge.sh --role ROLE --insight "TEXT"

Submit a knowledge candidate to the organizational knowledge base staging area.
The Triage agent reviews submissions and promotes approved ones.

Required:
  --role ROLE       Your agent role (e.g., pm, engineer, reviewer)
  --insight "TEXT"  The insight to submit (free-form text, 1-3 paragraphs)

What's worth submitting:
  - Durable business insights about our audience, positioning, or approach
  - Patterns about how agent coordination works (or fails)
  - Strategic learnings that would help future decisions
  - Operational insights (cost patterns, workflow bottlenecks)

What's NOT worth submitting:
  - Generic AI/tech knowledge (already in training data)
  - Feature implementation details (tracked in issues/PRs)
  - Temporary status or one-time observations
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --role) ROLE="$2"; shift 2 ;;
        --insight) INSIGHT="$2"; shift 2 ;;
        --help|-h) usage ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

if [[ -z "$ROLE" ]]; then
    echo "Error: --role is required" >&2
    exit 1
fi

if [[ -z "$INSIGHT" ]]; then
    echo "Error: --insight is required" >&2
    exit 1
fi

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
BLOB_NAME="staging/$(date -u +%Y%m%d-%H%M%S)-${ROLE}.json"
RUN_ID="${GITHUB_RUN_ID:-local}"

# Build JSON envelope
PAYLOAD=$(jq -n \
    --arg role "$ROLE" \
    --arg insight "$INSIGHT" \
    --arg submitted_at "$TIMESTAMP" \
    --arg run_id "$RUN_ID" \
    '{
        author_role: $role,
        insight: $insight,
        submitted_at: $submitted_at,
        run_id: $run_id
    }')

# Login with Managed Identity (idempotent)
az login --identity --client-id "$MANAGED_IDENTITY_CLIENT_ID" --output none 2>/dev/null || {
    echo "WARNING: Azure login failed — cannot submit knowledge"
    exit 1
}

az storage blob upload \
    --account-name "$STORAGE_ACCOUNT" \
    --container-name "$CONTAINER" \
    --name "$BLOB_NAME" \
    --data "$PAYLOAD" \
    --content-type "application/json" \
    --auth-mode login \
    --overwrite 2>/dev/null

echo "Knowledge candidate submitted: $BLOB_NAME"
