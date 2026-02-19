#!/bin/bash
# Triage: process human-created issues
# Run every 12-24 hours to keep response times low for external contributors.
#
# Usage: ./scripts/run-triage.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_ROOT="${HARNESS_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"

log() { echo "[triage $(date -u +%H:%M:%S)] $*"; }

log "=== Triage ==="
echo ""

# Check if there are any unprocessed human issues
HUMAN_ISSUES=$(gh issue list --state open --json number,labels \
    --jq '[.[] | select(
        ([.labels[].name] | index("agent-created") | not) and
        ([.labels[].name] | map(startswith("source/")) | any | not)
    )] | length')

# Check if there are knowledge base submissions awaiting curation
STAGING_COUNT=0
if STAGING_LIST=$("$HARNESS_ROOT/scripts/kb-list-staging.sh" 2>/dev/null); then
    STAGING_COUNT=$(echo "$STAGING_LIST" | grep -c . || true)
fi

if [ "$HUMAN_ISSUES" -gt 0 ] || [ "$STAGING_COUNT" -gt 0 ]; then
    log "Found $HUMAN_ISSUES human issue(s), $STAGING_COUNT KB submission(s) — running triage agent"
    if "$HARNESS_ROOT/agents/triage.sh"; then
        log "  Triage agent completed successfully"
    else
        log "  Triage agent exited with error"
    fi
else
    log "No human issues or KB submissions — skipping triage"
fi

echo ""
log "=== Triage complete ==="
