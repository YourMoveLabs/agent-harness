#!/bin/bash
# Check if unprocessed intake batch is ready, and dispatch PO if so.
# Used by reviewer and triage workflows to trigger PO processing.
#
# Usage: scripts/lib/dispatch-po-if-ready.sh [threshold]
#   threshold: minimum unprocessed items to trigger PO (default: 5)
set -euo pipefail

THRESHOLD="${1:-5}"

# Count unprocessed intake: has source/* label but no priority/* yet
INTAKE=$(gh issue list --state open --json labels \
    --jq '[.[] | select(
        (.labels | map(.name) | any(test("^source/"))) and
        (.labels | map(.name) | any(test("^priority/")) | not)
    )] | length')

if [ "$INTAKE" -ge "$THRESHOLD" ]; then
    echo "Batch ready: $INTAKE unprocessed intake items (threshold: $THRESHOLD) — dispatching PO"
    gh workflow run agent-product-owner.yml
else
    echo "Only $INTAKE unprocessed items — accumulating (threshold: $THRESHOLD)"
fi
