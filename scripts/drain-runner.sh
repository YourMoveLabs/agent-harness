#!/bin/bash
# Drain the self-hosted runner — wait for in-progress runs to finish.
# Usage: ./scripts/drain-runner.sh [REPO]
# After this completes, it's safe to deallocate the VM.
set -euo pipefail

REPO="${1:-YourMoveLabs/agent-fishbowl}"

echo "Draining runner for $REPO..."

# Disable all agent workflows
for wf in agent-engineer.yml agent-infra-engineer.yml agent-reviewer.yml agent-product-owner.yml agent-scans.yml agent-user-experience.yml agent-strategic.yml agent-triage.yml agent-site-reliability.yml agent-content-creator.yml agent-product-analyst.yml agent-qa-analyst.yml agent-financial-analyst.yml agent-customer-ops.yml agent-marketing-strategist.yml agent-escalation-lead.yml agent-human-ops.yml; do
  gh workflow disable "$wf" --repo "$REPO" 2>/dev/null && echo "  Disabled $wf" || true
done

echo "Workflows disabled. Waiting for in-progress runs to complete..."

# Wait for any in-progress runs to finish (check every 30s, max 30min)
for i in $(seq 1 60); do
  ACTIVE=$(gh run list --repo "$REPO" --status in_progress --json databaseId --jq 'length' 2>/dev/null || echo "0")
  if [ "$ACTIVE" -eq 0 ]; then
    echo "No active runs. Safe to take the VM offline."
    exit 0
  fi
  echo "  $ACTIVE run(s) still active... waiting 30s (attempt $i/60)"
  sleep 30
done

echo "WARNING: Timed out waiting for runs to complete. $ACTIVE run(s) still active."
exit 1
