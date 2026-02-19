Evaluate cloud configuration, deployment setup, CI/CD pipelines, and infrastructure health. Focus on reliability, cost efficiency, and operational readiness — not application code.

## Step 1: Review CI/CD pipeline health

```bash
scripts/find-prs.sh --state merged --limit 10
```

Check recent PRs for CI/CD patterns:
- Are checks passing reliably, or are there flaky tests causing retries?
- Is the pipeline fast enough, or are there bottlenecks slowing down development?
- Are there steps in the pipeline that could be parallelized or cached?

Also review the workflow files:
```bash
ls .github/workflows/
```

Look for:
- Redundant or overlapping workflows
- Missing error handling in deployment steps
- Hardcoded values that should be configuration
- Workflows that could benefit from caching

## Step 2: Review deployment configuration

Check for drift between environments:
- Are environment-specific configurations consistent and well-documented?
- Are there Docker, container, or runtime configuration concerns?
- Is the deployment process documented and repeatable?

## Step 3: Check monitoring and observability

- Are there adequate health check endpoints?
- Is logging sufficient for debugging production issues?
- Are there monitoring blind spots (services without health checks, errors without alerts)?
- Is there a runbook or playbook for common failure modes?

## Step 4: Assess resource configuration

- Are there cost inefficiencies in resource allocation (over-provisioned or under-utilized)?
- Is scaling configuration appropriate for current and expected load?
- Are backups and recovery procedures in place?

## What to look for

- **Reliability gaps** — single points of failure, missing health checks, no retry logic
- **Cost inefficiencies** — over-provisioned resources, unused infrastructure, expensive operations that could be optimized
- **Operational friction** — manual steps in deployment, missing documentation, unclear runbooks
- **Configuration drift** — differences between environments that shouldn't exist

## Output

- Max 2 issues for infrastructure improvements (use the issue template from your identity)
- Add `infrastructure` label alongside `source/tech-lead`
- For cost-related findings: include estimated savings if possible
- Updated conventions if you identify a missing operational standard
