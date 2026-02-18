#!/bin/bash
# Scanning agents: Tech Lead code review
# Run every 3-4 days to maintain code health.
# UX review is now PO-dispatched (see po.md Step 8).
#
# Usage: ./scripts/run-scans.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_ROOT="${HARNESS_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"

log() { echo "[scans $(date -u +%H:%M:%S)] $*"; }

log "=== Tech Lead Scan ==="
echo ""

# ── Tech Lead: standards + architecture ──────────────────────────────────────
log "Tech Lead agent — reviewing standards and architecture"
if "$HARNESS_ROOT/agents/tech-lead.sh"; then
    log "  Tech Lead completed successfully"
else
    log "  Tech Lead exited with error (non-fatal)"
fi

echo ""
log "=== Scan complete ==="
