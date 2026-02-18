# MCP Servers Catalog

A catalog of recommended MCP servers organized by category. Each entry includes setup instructions and key tools.

## Project Management

### mcp-atlassian (Jira + Confluence)

**Purpose**: Access Jira issues and Confluence pages

**Supports**: Claude Code, Cursor

**Configuration**:
```json
{
  "mcpServers": {
    "mcp-atlassian": {
      "command": "uvx",
      "args": ["--python=3.12", "mcp-atlassian"],
      "env": {
        "JIRA_URL": "https://jira.example.com",
        "CONFLUENCE_URL": "https://wiki.example.com",
        "JIRA_PERSONAL_TOKEN": "${JIRA_PERSONAL_TOKEN}",
        "CONFLUENCE_PERSONAL_TOKEN": "${CONFLUENCE_PERSONAL_TOKEN}"
      }
    }
  }
}
```

**Note**: Uses `uvx` (from `uv` package manager) to run without global install. Tokens are personal access tokens, not API tokens.

**Key Tools**:
| Tool | Purpose |
|------|---------|
| `jira_get_issue` | Get issue details |
| `jira_search` | Search with JQL |
| `jira_create_issue` | Create new issues |
| `jira_transition_issue` | Change issue status |
| `jira_add_comment` | Add comments |
| `jira_create_remote_issue_link` | Link external resources (PRs, docs) |
| `confluence_search` | Search pages |
| `confluence_get_page` | Get page content |
| `confluence_create_page` | Create new pages |

**Example Usage**:
```
# Get issue details
jira_get_issue(issue_key="PROJ-123")

# Search for open bugs
jira_search(jql="project = PROJ AND type = Bug AND status = Open")

# Link a PR to an issue
jira_create_remote_issue_link(
  issue_key="PROJ-123",
  url="https://github.com/org/repo/pull/456",
  title="PR #456: Fix login bug"
)
```

---

## Source Control

### GitHub MCP Server

**Purpose**: Access GitHub repositories, issues, PRs

**Supports**: Claude Code, Cursor

**Configuration (github.com)**:
```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp",
      "headers": {
        "Authorization": "Bearer ${GITHUB_TOKEN}"
      }
    }
  }
}
```

**Configuration (GitHub Enterprise)**:
```json
{
  "mcpServers": {
    "github-enterprise": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "-e", "GITHUB_PERSONAL_ACCESS_TOKEN", "-e", "GITHUB_HOST", "ghcr.io/github/github-mcp-server"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GH_ENTERPRISE_TOKEN}",
        "GITHUB_HOST": "https://git.corp.example.com"
      }
    }
  }
}
```

**Key Tools**:
| Tool | Purpose |
|------|---------|
| `list_issues` | List repository issues |
| `create_issue` | Create new issue |
| `list_pull_requests` | List PRs |
| `create_pull_request` | Create PR |
| `pull_request_read` | Get PR details, diff, status |
| `merge_pull_request` | Merge a PR |
| `create_branch` | Create new branch |
| `search_code` | Search code across repos |

**Example Usage**:
```
# List open PRs
list_pull_requests(owner="my-org", repo="my-app", state="open")

# Get PR diff
pull_request_read(method="get_diff", owner="my-org", repo="my-app", pullNumber=123)

# Create a branch
create_branch(owner="my-org", repo="my-app", branch="feature/new-api")
```

**Note**: For environments with both github.com and GitHub Enterprise, configure two servers with different names.

---

## Communication

### Slack MCP

**Purpose**: Read and send Slack messages

**Supports**: Claude Code, Cursor

**Configuration**:
```json
{
  "mcpServers": {
    "slack": {
      "command": "npx",
      "args": ["-y", "slack-mcp-server@latest", "--transport", "stdio"],
      "env": {
        "SLACK_MCP_XOXP_TOKEN": "${SLACK_MCP_XOXP_TOKEN}",
        "SLACK_MCP_ADD_MESSAGE_TOOL": "true"
      }
    }
  }
}
```

**Note**: Uses `npx` with the `slack-mcp-server` package. Requires a user token (`xoxp-...`) not a bot token.

**Key Tools**:
| Tool | Purpose |
|------|---------|
| `channels_list` | List available channels |
| `conversations_history` | Get channel messages |
| `conversations_replies` | Get thread replies |
| `conversations_add_message` | Post a message |
| `conversations_search_messages` | Search messages |

**Example Usage**:
```
# Post to a channel
conversations_add_message(
  channel_id="#engineering",
  payload="Deployment complete for v1.2.3"
)

# Search for messages
conversations_search_messages(
  search_query="deployment failed",
  filter_in_channel="#alerts"
)
```

---

## Observability

### Splunk MCP

**Purpose**: Query Splunk logs

**Supports**: Claude Code

**Configuration**:
```json
{
  "mcpServers": {
    "splunk": {
      "command": "mcp-splunk",
      "env": {
        "SPLUNK_URL": "https://splunk-api.example.com",
        "SPLUNK_USERNAME": "${SPLUNK_USERNAME}",
        "SPLUNK_PASSWORD": "${SPLUNK_PASSWORD}"
      }
    }
  }
}
```

**Key Tools**:
| Tool | Purpose |
|------|---------|
| `search_splunk` | Execute SPL query |
| `list_indexes` | List available indexes |
| `get_index_info` | Get index metadata |

**Example Usage**:
```
# Search for errors in the last hour
search_splunk(
  search_query="index=app_logs level=ERROR | head 100",
  earliest_time="-1h",
  latest_time="now"
)
```

### Coralogix MCP

**Purpose**: Query Coralogix logs and metrics

**Supports**: Claude Code

**Configuration**:
```json
{
  "mcpServers": {
    "coralogix": {
      "command": "npx",
      "args": ["-y", "@nickholden/coralogix-mcp-server@latest"],
      "env": {
        "CORALOGIX_API_KEY": "${CORALOGIX_API_KEY}",
        "CORALOGIX_REGION": "auto",
        "CORALOGIX_ENV": "production"
      }
    }
  }
}
```

**Note**: Uses the `@nickholden/coralogix-mcp-server` community package.

**Key Tools**:
| Tool | Purpose |
|------|---------|
| `coralogix_query` | Query logs with Lucene or DataPrime |
| `list_alerts` | List configured alerts |
| `get_alert` | Get alert details |

---

## Databases

### PostgreSQL MCP

**Purpose**: Query PostgreSQL databases

**Supports**: Claude Code, Cursor

**Configuration**:
```json
{
  "mcpServers": {
    "postgres-dev": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-postgres@latest",
        "${DATABASE_URL}"
      ]
    }
  }
}
```

**Note**: Uses the official `@modelcontextprotocol/server-postgres` package. Set `DATABASE_URL` in your shell profile (see [Environment & Secrets](../env-secrets.md)).

**Key Tools**:
| Tool | Purpose |
|------|---------|
| `query` | Execute read-only SQL |

**Example Usage**:
```
# Query recent records
query(sql="SELECT * FROM users WHERE created_at > NOW() - INTERVAL '1 day' LIMIT 10")
```

**Note**: Configure separate servers for each environment (dev, stage, prod) with appropriate credentials.

---

## Deployment

### Flex MCP

**Purpose**: Deployment validation (Helm charts, Argo CD)

**Supports**: Claude Code

**Configuration**:
```json
{
  "mcpServers": {
    "flex": {
      "command": "mcp-flex",
      "env": {
        "FLEX_API_KEY": "${FLEX_API_KEY}"
      }
    }
  }
}
```

**Key Tools**:
| Tool | Purpose |
|------|---------|
| `ValidateDeployment` | Validate Helm charts and Argo CD |
| `PreDeploymentCheck` | Pre-deployment validation |
| `GetFlexLinks` | Get DevHome, Argo CD links |
| `GetFlexDocumentation` | Access Flex docs |

**Example Usage**:
```
# Validate a deployment
ValidateDeployment(
  orgName="my-org",
  repoName="my-app-deploy",
  gitRef="main"
)

# Get deployment links
GetFlexLinks(
  orgName="my-org",
  repoName="my-app-deploy"
)
```

---

## Server Comparison

### Observability Options

| Server | Best For | Query Language |
|--------|----------|----------------|
| Splunk | Internal logs | SPL |
| Coralogix | Cloud-native logging | Lucene/DataPrime |
| CloudWatch (via AWS CLI) | AWS-native apps | CloudWatch Insights |

### Source Control Options

| Server | Best For | Notes |
|--------|----------|-------|
| GitHub MCP (HTTP) | github.com | Easiest setup |
| GitHub MCP (Docker) | GitHub Enterprise | Requires Docker |
| `gh` CLI | Quick commands | Not MCP, but works well |

---

## Secrets Management with 1Password

For servers requiring secrets (API keys, tokens, passwords), use 1Password CLI (`op`) to inject credentials at runtime. This keeps secrets out of your `.mcp.json` file.

### The Wrapper Script Pattern

Create a wrapper script that reads secrets from 1Password and launches the MCP server:

**Example: `run-with-op.sh`**
```bash
#!/bin/bash
# Wrapper script to inject 1Password secrets into MCP server

# Read secrets from 1Password
export SPLUNK_USERNAME=$(op read "op://Private/Splunk/username")
export SPLUNK_PASSWORD=$(op read "op://Private/Splunk/password")

# Launch the MCP server
exec uvx mcp-splunk
```

**Configuration using the wrapper**:
```json
{
  "mcpServers": {
    "splunk": {
      "command": "bash",
      "args": ["/path/to/run-with-op.sh"],
      "env": {}
    }
  }
}
```

### Benefits

- **No secrets in config files** — `.mcp.json` can be committed to git
- **Automatic rotation** — Update 1Password, servers pick up new credentials
- **Audit trail** — 1Password logs access to secrets
- **Single source of truth** — Same secrets used across all tools

### Prerequisites

1. Install 1Password CLI: https://developer.1password.com/docs/cli/
2. Sign in: `op signin`
3. Verify access: `op read "op://Private/YourItem/field"`

### Creating Wrapper Scripts

For each MCP server needing secrets:

1. Create `~/.claude/mcp-servers/<server-name>/run-with-op.sh`
2. Add `op read` commands for each required secret
3. Export as environment variables
4. Use `exec` to launch the actual server
5. Reference the wrapper in your `.mcp.json`

---

## Adding New Servers

When adding a new MCP server to your setup:

1. **Test locally first**:
   ```bash
   # Run server standalone
   mcp-server-name --help
   ```

2. **Add minimal config**:
   ```json
   {
     "mcpServers": {
       "new-server": {
         "command": "mcp-server-name"
       }
     }
   }
   ```

3. **Verify in AI tool**:
   - Restart Claude Code / Cursor
   - Check server appears in tool list
   - Test a simple operation

4. **Document for team**:
   - Required credentials/tokens
   - Setup steps
   - Common usage patterns

## See Also

- [MCP Overview](overview.md) - What MCP is and how it works
- [MCP Workflows](workflows.md) - End-to-end examples
- [Environment & Secrets](../env-secrets.md) - Managing credentials
