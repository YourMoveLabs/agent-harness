#!/bin/bash
# Content Creator: blog post generation via Captain AI headless API
# Runs daily. Checks Marketing Strategist directives first, then self-selects.
#
# Usage: ./scripts/run-content-creator.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_ROOT="${HARNESS_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"

log() { echo "[content-creator $(date -u +%H:%M:%S)] $*"; }

log "=== Content Creator ==="
echo ""

# Ensure content strategy exists
if [ ! -f config/content-strategy.md ]; then
    log "WARNING: config/content-strategy.md not found — Content Creator will have limited editorial context"
fi

log "Running Content Creator agent — blog post generation"
if "$HARNESS_ROOT/agents/run-agent.sh" content-creator; then
    log "  Content Creator agent completed successfully"
else
    log "  Content Creator agent exited with error"
fi

echo ""
log "=== Content Creator complete ==="
