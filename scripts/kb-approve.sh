#!/bin/bash
# kb-approve.sh — Approve a knowledge candidate (move from staging to approved).
# Usage: scripts/kb-approve.sh STAGING_BLOB_NAME [APPROVED_NAME]
# If APPROVED_NAME is not given, uses the staging filename under approved/.
set -euo pipefail

STAGING_NAME="${1:?Usage: kb-approve.sh STAGING_BLOB_NAME [APPROVED_NAME]}"
APPROVED_NAME="${2:-approved/$(basename "$STAGING_NAME")}"

# Ensure approved/ prefix
if [[ "$APPROVED_NAME" != approved/* ]]; then
    APPROVED_NAME="approved/$APPROVED_NAME"
fi

ACCOUNT="agentfishbowlstorage"
CONTAINER="org-knowledge"

az login --identity --client-id "$MANAGED_IDENTITY_CLIENT_ID" --output none 2>/dev/null || {
    echo "ERROR: Azure login failed" >&2; exit 1
}

# Copy staging → approved
SOURCE_URL="https://${ACCOUNT}.blob.core.windows.net/${CONTAINER}/${STAGING_NAME}"
az storage blob copy start \
    --account-name "$ACCOUNT" \
    --destination-container "$CONTAINER" \
    --destination-blob "$APPROVED_NAME" \
    --source-uri "$SOURCE_URL" \
    --auth-mode login 2>/dev/null

# Delete staging copy
az storage blob delete \
    --account-name "$ACCOUNT" \
    --container-name "$CONTAINER" \
    --name "$STAGING_NAME" \
    --auth-mode login 2>/dev/null

echo "Approved: $STAGING_NAME → $APPROVED_NAME"
