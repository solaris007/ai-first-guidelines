# Environment Variables & Secrets

## Overview

Proper handling of environment variables and secrets is critical in AI-first development. AI assistants can see your code, configuration files, and sometimes environment—keeping secrets separate prevents accidental exposure.

## Core Principles

### 1. Never Commit Secrets

**MUST NOT** commit to version control:
- API keys and tokens
- Database passwords
- Private keys
- OAuth client secrets
- Encryption keys

### 2. Separate Configuration from Secrets

```
config.json          ← Commit (non-sensitive configuration)
.env                 ← Never commit (secrets)
.env.example         ← Commit (template without values)
```

### 3. Use Environment Variables

Secrets should be injected via environment, not files:
```bash
# In shell or CI/CD
export DATABASE_URL="postgres://user:password@host:5432/db"
export API_KEY="sk-xxxx"
```

## File Patterns

### .env Files

**Structure**:
```bash
# .env (NEVER commit)
DATABASE_URL=postgres://user:secretpassword@localhost:5432/mydb
API_KEY=sk-live-xxxxxxxxxxxx
JWT_SECRET=your-256-bit-secret-here
STRIPE_SECRET_KEY=sk_live_xxxxx
```

**Template**:
```bash
# .env.example (commit this)
DATABASE_URL=postgres://user:password@localhost:5432/mydb
API_KEY=your-api-key-here
JWT_SECRET=generate-a-secure-secret
STRIPE_SECRET_KEY=sk_test_xxxxx
```

### .gitignore

Always include:
```gitignore
# Environment files
.env
.env.local
.env.*.local
.env.production
.env.staging

# Secrets
*.pem
*.key
secrets/
credentials/

# IDE with potential secrets
.idea/
.vscode/settings.json  # If contains secrets
```

## MCP Server Configuration

### Safe Pattern

Use environment variable references in `.mcp.json`:

```json
{
  "mcpServers": {
    "postgres-dev": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres", "${DATABASE_URL}"]
    },
    "slack": {
      "command": "npx",
      "args": ["-y", "slack-mcp-server@latest", "--transport", "stdio"],
      "env": {
        "SLACK_MCP_XOXP_TOKEN": "${SLACK_MCP_XOXP_TOKEN}"
      }
    }
  }
}
```

### Setting Environment Variables

```bash
# Add to shell profile (~/.zshrc, ~/.bashrc)
export DATABASE_URL="postgres://..."
export SLACK_MCP_XOXP_TOKEN="xoxp-..."
export JIRA_API_TOKEN="..."

# Reload
source ~/.zshrc
```

### Secret Managers

For production environments, use secret managers:

**AWS Secrets Manager**:
```bash
export DATABASE_URL=$(aws secretsmanager get-secret-value \
  --secret-id prod/database/url --query SecretString --output text)
```

**HashiCorp Vault**:
```bash
export DATABASE_URL=$(vault kv get -field=url secret/database)
```

## CLAUDE.md and Secrets

### Safe Patterns

Reference environment variables without values:

```markdown
## Configuration

Required environment variables:
- `DATABASE_URL` - PostgreSQL connection string
- `API_KEY` - External service API key
- `JWT_SECRET` - Secret for JWT signing

Set these in your shell profile or use a secrets manager.
```

### Unsafe Patterns

**NEVER do this**:
```markdown
## Configuration

Database: postgres://admin:mysecretpassword@db.example.com:5432/prod
API Key: sk-live-xxxxxxxxxxxxxxxxxxxx
```

## CI/CD Secrets

### GitHub Actions

Use GitHub Secrets:

```yaml
# .github/workflows/deploy.yml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
          API_KEY: ${{ secrets.API_KEY }}
        run: |
          npm run deploy
```

### GitLab CI

Use CI/CD Variables:

```yaml
# .gitlab-ci.yml
deploy:
  script:
    - npm run deploy
  variables:
    DATABASE_URL: $DATABASE_URL  # Set in GitLab UI
    API_KEY: $API_KEY
```

### Jenkins

Use Credentials Plugin:

```groovy
pipeline {
    environment {
        DATABASE_URL = credentials('database-url')
        API_KEY = credentials('api-key')
    }
    stages {
        stage('Deploy') {
            steps {
                sh 'npm run deploy'
            }
        }
    }
}
```

## Development Workflow

### Local Development

1. Copy example file:
   ```bash
   cp .env.example .env
   ```

2. Fill in values (obtain from team/vault):
   ```bash
   # Edit .env with actual values
   ```

3. Verify .gitignore:
   ```bash
   git status  # .env should not appear
   ```

### Sharing Secrets with Team

**DO**:
- Use a password manager (1Password, LastPass)
- Use a secrets manager (Vault, AWS Secrets Manager)
- Share via encrypted channels (Signal, encrypted email)

**DON'T**:
- Send secrets in Slack/Teams/email unencrypted
- Commit secrets "just for now"
- Share production secrets for development

### Rotating Secrets

When secrets are exposed:

1. **Revoke immediately** - Generate new credentials
2. **Update all environments** - Dev, staging, production
3. **Check audit logs** - Look for unauthorized access
4. **Review git history** - If committed, consider history rewrite

## AI-Specific Considerations

### What AI Can See

AI assistants typically see:
- ✅ Source code files
- ✅ Configuration files (package.json, etc.)
- ✅ CLAUDE.md / .cursorrules
- ⚠️ Sometimes shell environment
- ❌ .env files (if properly gitignored)

### Protecting Secrets from AI

1. **Never paste secrets in chat** - Ask AI to "use environment variable X" instead
2. **Use placeholders in examples** - `your-api-key-here` not actual keys
3. **Review AI-generated code** - Ensure it doesn't hardcode values

### Safe AI Prompts

**Good**:
```
Create a database connection using the DATABASE_URL environment variable.
```

**Bad**:
```
Create a database connection to postgres://admin:password@host:5432/db
```

## Checklist

### Project Setup

- [ ] `.env.example` exists with all required variables (no values)
- [ ] `.env` is in `.gitignore`
- [ ] Secrets directory is in `.gitignore`
- [ ] README documents required environment variables
- [ ] No hardcoded secrets in source code

### Code Review

- [ ] No secrets in committed files
- [ ] Environment variables used for all sensitive values
- [ ] `.env.example` updated if new variables added
- [ ] CI/CD uses secret management

### Regular Audit

- [ ] Review git history for accidentally committed secrets
- [ ] Rotate secrets on regular schedule
- [ ] Remove unused/deprecated secrets
- [ ] Verify secret access is appropriately scoped

## See Also

- [Claude Code Configuration](ai-tools/claude-code.md) - CLAUDE.md patterns
- [MCP Overview](mcp/overview.md) - MCP configuration
- [MCP Servers](mcp/servers.md) - Server catalog with auth setup
- [MUST Rules](../05-guardrails/must-rules.md) - Security-related rules
- [Tools Checklist](../01-foundations/tools-checklist.md) - Vault CLI setup
