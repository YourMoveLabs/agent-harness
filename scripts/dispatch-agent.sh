#!/bin/bash
# Emit a repository_dispatch event to trigger a downstream agent workflow.
# Automatically propagates chain depth to prevent infinite dispatch loops.
#
# Usage: scripts/dispatch-agent.sh <event_type> [payload_json]
#
# Event types:
#   agent-product-owner-complete  -- PO finished triaging, engineer should pick up work
#   agent-reviewer-feedback       -- Reviewer requested changes, engineer should fix
#   agent-product-manager-feedback -- PM flagged misalignment, PO should re-scope
#
# Chain depth:
#   Reads AGENT_CHAIN_DEPTH from env (default 0), increments by 1, and includes
#   it in the payload as "chain_depth". The harness action.yml checks this value
#   and halts if >= 5 to prevent runaway dispatch chains.
set -euo pipefail

EVENT_TYPE="${1:?Usage: dispatch-agent.sh <event_type> [payload_json]}"
PAYLOAD="${2:-'{}'}"

REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY must be set}"

# Propagate chain depth
CURRENT_DEPTH="${AGENT_CHAIN_DEPTH:-0}"
NEW_DEPTH=$((CURRENT_DEPTH + 1))

# Merge chain_depth into payload
PAYLOAD=$(echo "$PAYLOAD" | jq --argjson depth "$NEW_DEPTH" '. + {chain_depth: $depth}')

echo "Dispatching event: $EVENT_TYPE -> $REPO (chain_depth: $NEW_DEPTH)"
echo "Payload: $PAYLOAD"

gh api "repos/$REPO/dispatches" \
  --input - <<EOF
{"event_type": "$EVENT_TYPE", "client_payload": $PAYLOAD}
EOF

echo "Dispatched successfully"
