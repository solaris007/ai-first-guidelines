# OpenAI Codex CLI Configuration

## Overview

Codex is OpenAI's terminal-based CLI agent for software engineering tasks. Like Claude Code, it operates directly in your terminal, understanding your codebase and executing tasks through natural language.

Codex reads `AGENTS.md` from your repository root for project context - the same file used by Cursor, Gemini CLI, and other tools following the cross-tool standard. It also supports `.agents/skills/` for skill discovery.

## Configuration

| File | Purpose |
|------|---------|
| `AGENTS.md` | Project context and conventions (primary, shared across tools) |
| `.codex/config.toml` | MCP server configuration |
| `.agents/skills/` | Skill discovery |

## AGENTS.md

Codex reads `AGENTS.md` from the repo root automatically. This is the shared instructions file - the same content works for Cursor, Gemini CLI, and other agents that follow the cross-tool standard.

Write your project rules, conventions, and context in `AGENTS.md` once, and all supporting tools pick it up. See [Cross-Tool Setup](../cross-tool-setup.md) for the full pattern.

## MCP Configuration

Codex uses TOML format for MCP server configuration, stored in `.codex/config.toml`. This differs from Claude Code's JSON-based `.mcp.json`.

### Example

```toml
[mcp_servers.mcp-atlassian]
command = "uvx"
args = ["--python=3.12", "mcp-atlassian"]

[mcp_servers.mcp-atlassian.env]
JIRA_URL = "https://jira.example.com"
JIRA_PERSONAL_TOKEN = "${JIRA_PERSONAL_TOKEN}"
```

Each MCP server is a `[mcp_servers.<name>]` section with `command`, `args`, and optional `env` sub-table. Environment variable references use `${VAR_NAME}` syntax.

### Multiple Servers

```toml
[mcp_servers.mcp-atlassian]
command = "uvx"
args = ["--python=3.12", "mcp-atlassian"]

[mcp_servers.mcp-atlassian.env]
JIRA_URL = "https://jira.example.com"
JIRA_PERSONAL_TOKEN = "${JIRA_PERSONAL_TOKEN}"

[mcp_servers.slack]
command = "npx"
args = ["-y", "slack-mcp-server@latest", "--transport", "stdio"]

[mcp_servers.slack.env]
SLACK_MCP_XOXP_TOKEN = "${SLACK_MCP_XOXP_TOKEN}"
SLACK_TEAM_ID = "T12345678"
```

## Key Differences from Claude Code

| Aspect | Codex | Claude Code |
|--------|-------|-------------|
| Instructions file | AGENTS.md | CLAUDE.md |
| MCP config format | TOML (`.codex/config.toml`) | JSON (`.mcp.json`) |
| Skill paths | `.agents/skills/` | `.claude/skills/` + `.agents/skills/` |
| Hooks | Not yet supported | PostToolUse, PreToolUse |
| Commands | Not yet supported | `.claude/commands/` |

## Best Practices

1. **Keep AGENTS.md as the primary instructions file** - Write project rules there so all tools benefit
2. **Mirror MCP servers** from `.mcp.json` to `.codex/config.toml` - Same servers, different format
3. **Use `.agents/skills/`** for skills that should work across both Codex and Claude Code
4. **Keep tool-specific config minimal** - Only MCP server definitions belong in `.codex/config.toml`; project rules belong in `AGENTS.md`
5. **See [Cross-Tool Setup](../cross-tool-setup.md)** for keeping configs in sync across tools

## See Also

- [Claude Code Configuration](claude-code.md)
- [Cursor Configuration](cursor.md)
- [Copilot Configuration](copilot.md)
- [Cross-Tool Setup](../cross-tool-setup.md)
