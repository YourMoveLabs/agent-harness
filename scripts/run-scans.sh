#!/bin/bash
# Scanning agents: Tech Lead + UX review
# Run every 3-4 days to maintain code health and UX quality.
#
# Usage: ./scripts/run-scans.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_ROOT="${HARNESS_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"

log() { echo "[scans $(date -u +%H:%M:%S)] $*"; }

log "=== Scanning Agents ==="
echo ""

# ── Tech Lead: standards + architecture ──────────────────────────────────────
log "Phase 1: Tech Lead agent — reviewing standards and architecture"
if "$HARNESS_ROOT/agents/tech-lead.sh"; then
    log "  Tech Lead completed successfully"
else
    log "  Tech Lead exited with error (non-fatal, continuing)"
fi

echo ""

# ── UX Reviewer: user experience ─────────────────────────────────────────────
log "Phase 2: UX agent — reviewing user experience"
if "$HARNESS_ROOT/agents/ux.sh"; then
    log "  UX agent completed successfully"
else
    log "  UX agent exited with error (non-fatal)"
fi

echo ""
log "=== Scanning complete ==="
