Scan the codebase for security concerns. Focus on vulnerabilities that could be exploited, not style issues. A security finding is something that could lead to data exposure, unauthorized access, or service disruption.

## Step 1: Check for exposed secrets

Search the codebase for hardcoded credentials, API keys, tokens, or connection strings:

```bash
# Look for common secret patterns in source files
```

Check configuration files, environment variable defaults, and test fixtures. Verify that `.gitignore` covers all sensitive files.

## Step 2: Review dependency security

Check dependency files for known vulnerabilities:

```bash
# Check Python dependencies
cat requirements.txt 2>/dev/null || cat pyproject.toml 2>/dev/null
```

```bash
# Check JavaScript dependencies
cat package.json 2>/dev/null
```

Look for:
- Outdated packages with known CVEs
- Dependencies that are no longer maintained
- Packages pulled from untrusted sources

## Step 3: Review authentication and authorization

Read the auth-related code paths:
- Are all API endpoints properly protected?
- Are there routes that should require authentication but don't?
- Is input validation present at API boundaries?
- Are tokens (JWT, API keys, OAuth) handled securely (not logged, not exposed in URLs)?

## Step 4: Check data handling

- Are user inputs sanitized before use in queries, templates, or shell commands?
- Is sensitive data (PII, credentials) excluded from logs?
- Are CORS and security headers configured correctly?
- Is error handling safe (no stack traces or internal details in production responses)?

## What to look for

- **Exposed secrets** in code, config, or test fixtures
- **Missing auth** on endpoints that modify data
- **Injection risks** — SQL injection, command injection, template injection, XSS
- **Insecure defaults** — debug mode enabled, CORS too permissive, weak crypto
- **Dependency vulnerabilities** — outdated packages with known CVEs

## Output

- Max 2 issues for security findings (use the issue template from your identity)
- Security-specific labels: add `security` label alongside `source/tech-lead`
- For critical findings (exposed secrets, missing auth on sensitive endpoints): note urgency clearly in the Risk section
- Updated conventions if you identify a missing security standard
