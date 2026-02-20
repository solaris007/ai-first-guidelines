# Plugins

Plugins extend AI coding assistants with additional capabilities, workflows, and specialized behaviors.

## What Are Plugins?

Plugins add functionality on top of base AI tools:
- **Structured workflows** - Enforce development practices like TDD
- **Skills** - Reusable patterns for common tasks
- **Integrations** - Connect to additional services

## Available Plugins

### Claude Code

| Plugin | Description | Documentation |
|--------|-------------|---------------|
| [Superpowers](superpowers.md) | Complete development workflow with brainstorming, planning, TDD, debugging | [Details](superpowers.md) |
| [Adobe Skills](adobe-skills.md) | AI agent skills for AEM Edge Delivery Services - block development, content modeling, migration, discovery | [Details](adobe-skills.md) |

### Cursor

Cursor uses extensions from the VS Code marketplace. It includes built-in AI features; additional extensions are generally not needed for AI-assisted workflows.

### GitHub Copilot

Copilot's functionality is primarily built-in:
- **Copilot Chat** - Conversational interface (built-in)
- **MCP support** - External tool integration via VS Code

## Plugin vs MCP

| Aspect | Plugins | MCP Servers |
|--------|---------|-------------|
| Purpose | Enhance AI behavior/workflows | Connect to external tools |
| Scope | AI assistant capabilities | Data and actions |
| Examples | TDD enforcement, planning | Jira, Slack, databases |
| Configuration | Tool-specific | Host-specific (`.mcp.json`, `.cursor/mcp.json`, or `~/.codex/config.toml`) |

**Use plugins for**: Workflows, patterns, AI behavior modification

**Use MCP for**: External service access (issue trackers, databases, etc.)

## Adding Plugin Documentation

When documenting a new plugin:

1. Create a file: `plugins/<tool>-<plugin-name>.md`
2. Include:
   - What it does
   - Installation steps
   - Key features/skills
   - Usage examples
   - Integration with MCP (if applicable)

## See Also

- [MCP Overview](../mcp/overview.md) - External tool integration
- [Claude Code](../ai-tools/claude-code.md) - Base tool configuration
- [Cursor](../ai-tools/cursor.md) - Cursor configuration
