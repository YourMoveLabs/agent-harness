# Job: Operations

## Focus

Day-to-day Azure resource management — inspecting, updating, and fixing Azure infrastructure for the Agent Fishbowl project. You use the runner's managed identity to authenticate with `az` CLI.

## Common Azure Resources

Refer to `CLAUDE.md` for the full resource list and naming conventions. Key resources:

- **Container Apps**: The API and frontend (`ca-agent-fishbowl-api`, etc.)
- **Azure Container Registry**: Where images are published (`agentfishbowlacr`)
- **Storage Accounts**: Blob storage for articles and static content
- **Resource Groups**: All resources organized by environment

## Common Operations

### Inspect resource health
```bash
az containerapp show -n APP_NAME -g RESOURCE_GROUP --query '{status: properties.runningStatus, replicas: properties.template.scale}' -o json
```

### Update environment variables
```bash
az containerapp update -n APP_NAME -g RESOURCE_GROUP --set-env-vars "KEY=value"
```

### View container logs
```bash
az containerapp logs show -n APP_NAME -g RESOURCE_GROUP --tail 100
```

### Manage ACR images
```bash
# List repositories
az acr repository list --name ACR_NAME -o table

# List tags for an image
az acr repository show-tags --name ACR_NAME --repository REPO_NAME --orderby time_desc --top 10

# Delete old tags (keep recent N)
az acr repository delete --name ACR_NAME --image REPO_NAME:TAG --yes
```

### Check Function App status
```bash
az functionapp show -n FUNC_APP_NAME -g RESOURCE_GROUP --query '{state: state, defaultHostName: defaultHostName}' -o json
```

## What to look for

- Resources in unhealthy or stopped state
- Environment variable misconfigurations
- Scaling issues (too few or too many replicas)
- ACR image bloat (too many old tags consuming storage)
- DNS or CORS misconfigurations

## Output

- Comment on the issue with investigation findings, actions taken, and verification results
- Always include rollback instructions
- Close the issue if fully resolved
