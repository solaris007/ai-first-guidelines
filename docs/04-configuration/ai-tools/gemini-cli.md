# Gemini CLI Configuration

## Overview

Gemini CLI is Google's open-source terminal-based agent for software development. It reads `AGENTS.md` and `GEMINI.md` for project context and supports `.agents/skills/` for skill discovery via the agentskills.io standard.

## Configuration

| File | Purpose |
|------|---------|
| `AGENTS.md` | Project context and conventions (primary, shared across tools) |
| `GEMINI.md` | Gemini-specific overrides |
| `.agents/skills/` | Skill discovery |

## AGENTS.md

Gemini CLI reads `AGENTS.md` from the repo root, just like Codex, Cursor, and other tools following the cross-tool standard. Write your project rules, conventions, and context here once, and all supporting tools pick it up.

See [Cross-Tool Setup](../cross-tool-setup.md) for the full pattern.

## GEMINI.md

`GEMINI.md` is the Gemini-specific instructions file, analogous to `CLAUDE.md` for Claude Code. Use it for overrides or behavioral adjustments that only apply to Gemini CLI.

### Redirecting to AGENTS.md

If your project rules live entirely in `AGENTS.md`, keep `GEMINI.md` minimal:

```markdown
# Gemini Instructions

Read AGENTS.md for project context and conventions.
```

### Adding Gemini-Specific Overrides

Use `GEMINI.md` when Gemini CLI needs different tool mappings or behavioral rules:

```markdown
# Gemini Instructions

Read AGENTS.md for project context and conventions.

## Gemini-Specific

- Use activate_skill to load skills from .agents/skills/
- Prefer search_code tool over manual grep for codebase exploration
```

## Skill Discovery

Gemini CLI reads skills from `.agents/skills/` following the agentskills.io standard. Each skill directory contains a `SKILL.md` file describing its purpose and usage.

```
.agents/
└── skills/
    ├── pr-review/
    │   └── SKILL.md
    ├── jira-ticket/
    │   └── SKILL.md
    └── deploy-check/
        └── SKILL.md
```

Skills activate via the `activate_skill` tool. The same `SKILL.md` format works across Gemini CLI, Claude Code, and other agents that support the agentskills.io standard.

## Key Differences from Claude Code

| Aspect | Gemini CLI | Claude Code |
|--------|------------|-------------|
| Instructions file | AGENTS.md + GEMINI.md | CLAUDE.md |
| MCP config | Built-in / settings | JSON (`.mcp.json`) |
| Skill paths | `.agents/skills/` | `.claude/skills/` + `.agents/skills/` |
| Skill activation | `activate_skill` tool | Skill tool |

## Best Practices

1. **Use AGENTS.md as the shared instructions file** - Write project rules there so all tools benefit
2. **Use GEMINI.md only for Gemini-specific overrides** - Keep it minimal; a redirect to AGENTS.md is often sufficient
3. **Place skills in `.agents/skills/`** for cross-tool portability - Skills in this directory work across Gemini CLI, Claude Code, Codex, and other agents
4. **Follow the SKILL.md format** from agentskills.io for maximum compatibility

## See Also

- [Claude Code Configuration](claude-code.md)
- [Cursor Configuration](cursor.md)
- [Copilot Configuration](copilot.md)
- [Codex Configuration](codex.md)
- [Cross-Tool Setup](../cross-tool-setup.md)
