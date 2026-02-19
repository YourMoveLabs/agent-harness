#!/bin/bash
# Product Analyst: market research, pricing strategy, Stripe ops, revenue tracking
# Runs daily (initially) to build up market intelligence for Goal 3.
#
# Usage: ./scripts/run-product-analyst.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_ROOT="${HARNESS_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"

log() { echo "[product-analyst $(date -u +%H:%M:%S)] $*"; }

log "=== Product Analyst ==="
echo ""

# Ensure goals.md exists — the agent needs it for strategic context
if [ ! -f config/goals.md ]; then
    log "ERROR: config/goals.md not found — Product Analyst cannot run without strategic goals"
    exit 1
fi

log "Running Product Analyst agent — market research and revenue strategy"
if "$HARNESS_ROOT/agents/product-analyst.sh"; then
    log "  Product Analyst agent completed successfully"
else
    log "  Product Analyst agent exited with error"
fi

echo ""
log "=== Product Analyst complete ==="
