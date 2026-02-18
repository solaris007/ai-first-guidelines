# MCP Overview

## What is MCP?

**Model Context Protocol (MCP)** is an open standard for connecting AI assistants to external tools and data sources. It provides a structured way for AI to interact with services like Jira, Slack, databases, and deployment systems.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      AI Host                             │
│              (Claude Code, Cursor, etc.)                 │
└────────────────────────┬────────────────────────────────┘
                         │ MCP Protocol
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ MCP Server  │  │ MCP Server  │  │ MCP Server  │
│   (Jira)    │  │  (Slack)    │  │ (Postgres)  │
└──────┬──────┘  └──────┬──────┘  └──────┬──────┘
       │                │                │
       ▼                ▼                ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ Jira API    │  │ Slack API   │  │ PostgreSQL  │
└─────────────┘  └─────────────┘  └─────────────┘
```

**Components:**
- **Host**: The AI tool (Claude Code, Cursor) that uses MCP
- **Server**: A process that translates MCP requests to service APIs
- **Tools**: Actions the server exposes (e.g., `jira_get_issue`)
- **Resources**: Data the server can provide (e.g., project lists)

## Why MCP?

### Before MCP: CLI Parsing

```bash
# AI runs CLI command
gh pr list --json number,title,state

# AI must parse JSON output
# Fragile: format changes break parsing
# Limited: only what CLI exposes
```

### With MCP: Structured Access

```
# AI calls MCP tool
list_pull_requests(owner="my-org", repo="my-app", state="open")

# Returns structured data with schema
# Reliable: typed responses
# Rich: full API access
```

### Benefits

| Aspect | Without MCP | With MCP |
|--------|-------------|----------|
| Response format | Parse CLI output | Structured JSON with schema |
| Error handling | Parse stderr | Typed error responses |
| Discovery | Read --help | Tool schema introspection |
| Authentication | Manage per-tool | Centralized in config |
| Cross-tool | Different CLIs | Consistent protocol |

## When to Use MCP vs CLI

| Use Case | MCP | CLI |
|----------|-----|-----|
| Structured data extraction | ✓ | |
| Complex queries (JQL, SQL) | ✓ | |
| Multi-step workflows | ✓ | |
| Shell scripting, piping | | ✓ |
| Quick one-off commands | | ✓ |
| Tools without MCP server | | ✓ |

**Rule of thumb**: Use MCP when you need structured data or multi-step workflows. Use CLI for simple commands or when no MCP server exists.

## Supported AI Tools

| Tool | MCP Support | Config Location |
|------|-------------|-----------------|
| Claude Code | Native | `.mcp.json` |
| Cursor | Native | `.cursor/mcp.json` |
| VS Code + Continue | Via extension | Extension settings |
| Other tools | Varies | Check documentation |

## Configuration

### File Location

Place `.mcp.json` in your workspace root:

```
my-workspace/
├── .mcp.json          # MCP configuration
├── CLAUDE.md          # AI instructions
├── project-a/
└── project-b/
```

### Basic Structure

```json
{
  "mcpServers": {
    "server-name": {
      "command": "executable",
      "args": ["arg1", "arg2"],
      "env": {
        "API_KEY": "${ENV_VAR}"
      }
    }
  }
}
```

### Server Types

**stdio (local process)**:
```json
{
  "mcpServers": {
    "postgres-dev": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres@latest", "${DATABASE_URL}"]
    }
  }
}
```

**HTTP (remote server)**:
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

**Docker (containerized)**:
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

### Environment Variables

Use `${VAR_NAME}` to reference environment variables:

```json
{
  "mcpServers": {
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

Set variables in your shell profile:
```bash
# ~/.zshrc or ~/.bashrc
export SLACK_MCP_XOXP_TOKEN="xoxp-your-token"
export JIRA_PERSONAL_TOKEN="your-jira-token"
```

## Finding MCP Servers

### Official Sources

- **Anthropic MCP Registry**: [modelcontextprotocol.io](https://modelcontextprotocol.io)
- **GitHub MCP Server**: [github.com/github/github-mcp-server](https://github.com/github/github-mcp-server)
- **npm**: Search for `mcp-` prefixed packages

### Evaluating Servers

When choosing an MCP server:

1. **Maintenance**: Is it actively maintained?
2. **Authentication**: Does it support your auth method?
3. **Coverage**: Does it expose the tools you need?
4. **Security**: Review permissions it requires

### Building Custom Servers

For internal tools or custom integrations, you can build MCP servers:

- **TypeScript SDK**: `@modelcontextprotocol/sdk`
- **Python SDK**: `mcp`
- **Specification**: [MCP Spec](https://spec.modelcontextprotocol.io)

## Best Practices

### Security

1. **Never commit secrets** - Use environment variables
2. **Minimal permissions** - Request only needed API scopes
3. **Review server code** - Understand what a server does before using
4. **Audit access** - Regularly review what servers can access

### Configuration

1. **Document required setup** - Team members need to know what tokens to obtain
2. **Test locally** - Verify servers connect before relying on them
3. **Version control** - Commit `.mcp.json` (without secrets) for team consistency

### Usage

1. **Prefer MCP for workflows** - Use structured access over CLI parsing
2. **Combine with CLI** - CLI is fine for simple commands
3. **Check tool availability** - Not all APIs have MCP servers yet

## Troubleshooting

### Server Won't Start

```bash
# Test server manually
mcp-server-name --help

# Check if command exists
which mcp-server-name

# For Docker servers, verify image
docker run --rm ghcr.io/example/mcp-server --help
```

### Authentication Errors

1. Verify environment variables are set: `echo $VAR_NAME`
2. Check token permissions/scopes
3. Verify token hasn't expired

### Server Times Out

- Check network connectivity to the service
- Verify firewall/proxy settings
- Try increasing timeout in server config

## See Also

- [MCP Servers](servers.md) - Recommended server catalog
- [MCP Workflows](workflows.md) - End-to-end examples
- [Environment & Secrets](../env-secrets.md) - Managing credentials
- [MCP Specification](https://spec.modelcontextprotocol.io)
