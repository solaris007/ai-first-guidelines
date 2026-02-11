# Superpowers Plugin for Claude Code

## Overview

[Superpowers](https://github.com/obra/superpowers) is a complete software development workflow for Claude Code, built on composable "skills" that automate best practices into the agent's behavior.

Instead of immediately writing code, superpowers guides Claude through:
1. **Design** - Ask clarifying questions, refine specifications
2. **Planning** - Create detailed implementation plans with bite-sized tasks
3. **Execution** - Work through tasks with automated code reviews
4. **Quality** - Enforce TDD, systematic debugging, verification

## Installation

Install by cloning the repository and running the install script:

```bash
git clone https://github.com/obra/superpowers.git
cd superpowers
./install.sh
```

After installation, restart Claude Code. Skills will activate automatically when your requests match their triggers.

## Core Skills

### Collaboration Skills

| Skill | Trigger | Purpose |
|-------|---------|---------|
| `brainstorming` | Before any creative work | Explore intent, requirements, design before coding |
| `writing-plans` | When you have specs/requirements | Create detailed implementation plans |
| `executing-plans` | When you have a plan ready | Execute plans with review checkpoints |
| `requesting-code-review` | After completing features | Verify work meets requirements |

### Quality Skills

| Skill | Trigger | Purpose |
|-------|---------|---------|
| `test-driven-development` | Before implementing features | RED-GREEN-REFACTOR cycles |
| `systematic-debugging` | When encountering bugs | Evidence-based debugging |
| `verification-before-completion` | Before claiming work is done | Prove it works before committing |

### Meta Skills

| Skill | Trigger | Purpose |
|-------|---------|---------|
| `using-superpowers` | Automatically on start | How to find and use skills |
| `writing-skills` | When creating new skills | Guide for authoring skills |

## How Skills Work

### Automatic Invocation

Superpowers intercepts your requests and checks if a skill applies:

```
You: "Add user authentication to the app"

Claude: Using brainstorming skill to explore requirements...

        Before we start coding, let me understand what you need:

        1. What authentication method?
           - [ ] Username/password
           - [ ] OAuth (Google, GitHub)
           - [ ] SSO/SAML
           - [ ] Other
```

### Skill Priority

When multiple skills could apply:

1. **Process skills first** (brainstorming, debugging)
2. **Implementation skills second** (domain-specific)

Example: "Let's build a REST API" → brainstorming first, then implementation.

### Skill Types

**Rigid skills** (follow exactly):
- `test-driven-development` - Must follow RED-GREEN-REFACTOR
- `systematic-debugging` - Must gather evidence before fixing
- `verification-before-completion` - Must prove success

**Flexible skills** (adapt to context):
- `brainstorming` - Adapt questions to the domain
- `writing-plans` - Plan detail varies by complexity

## Workflow Example

### Feature Development with Superpowers

```
1. Request: "Add password reset functionality"

2. Brainstorming skill activates:
   - Clarifies: Email or SMS? Token expiry? Rate limiting?
   - Presents 2-3 approaches with trade-offs
   - Gets approval on design

3. Writing-plans skill activates:
   - Creates detailed plan with file paths
   - Breaks into 2-5 minute tasks
   - Includes verification steps

4. TDD skill activates for each task:
   - Write failing test (RED)
   - Implement minimum code (GREEN)
   - Refactor if needed

5. Verification skill before completion:
   - Runs all tests
   - Confirms requirements met
   - Ready for commit
```

## Integration with MCP

Superpowers skills compose with MCP tools for end-to-end workflows:

### Example: Jira → Implementation → PR

```
Skills used:
- brainstorming (requirements from Jira ticket)
- writing-plans (implementation plan)
- test-driven-development (quality)
- verification-before-completion (final check)

MCP tools used:
- jira_get_issue (read ticket details)
- create_branch (start work)
- create_pull_request (submit code)
- jira_transition_issue (move to review)
```

### Example: Bug Report → Fix → Deploy

```
Skills used:
- systematic-debugging (investigate)
- test-driven-development (regression test)
- verification-before-completion (confirm fix)

MCP tools used:
- search_splunk (find error logs)
- query (check data state via postgres MCP)
- create_pull_request (submit fix)
- conversations_add_message (notify team via Slack)
```

## Creating Custom Skills

Use the `writing-skills` skill to create new skills:

```
You: "I want to create a skill for database migrations"

Claude: Using writing-skills to help create your skill...

        Let me understand what this skill should do:
        1. When should it trigger?
        2. What steps should it enforce?
        3. What verification is needed?
```

### Skill File Structure

Skills are markdown files with frontmatter:

```markdown
---
name: my-custom-skill
description: When to use this skill
---

## Overview

What this skill does and why.

## The Process

Steps the AI should follow.

## Checklist

- [ ] Step 1 completed
- [ ] Step 2 completed
- [ ] Verification passed
```

## Best Practices

### Let Skills Guide You

Don't skip steps even when they seem unnecessary:
- Brainstorming catches requirements gaps early
- Planning prevents rabbit holes
- TDD catches bugs before they compound

### Trust the Process

Skills enforce discipline that saves time:
- 5 minutes brainstorming saves hours of rework
- Writing tests first clarifies what "done" means
- Verification before completion prevents "it works on my machine"

### Combine with MCP

Skills handle the "how", MCP handles the "what":
- Skills: How to develop, debug, verify
- MCP: What data to fetch, where to post updates

## Troubleshooting

### Skill Not Activating

Check if:
1. Plugin is installed: Look for skill files in `~/.claude/plugins/cache/`
2. Skill triggers match your request: Review the skill's trigger description
3. Try invoking explicitly: Use `/skill-name` (e.g., `/brainstorming`)

### Skill Too Rigid

Some skills (TDD, debugging) are intentionally rigid. If a skill doesn't fit:
1. Explicitly tell Claude to skip it with justification
2. The skill may not be appropriate for the task

### Conflicts with MCP

Skills and MCP should complement, not conflict:
- Skills guide the process
- MCP provides the tools
- If both try to do the same thing, prefer the skill's guidance

## See Also

- [Claude Code Configuration](../ai-tools/claude-code.md)
- [MCP Overview](../mcp/overview.md)
- [MCP Workflows](../mcp/workflows.md) - Skills + MCP in action
- [Superpowers GitHub](https://github.com/obra/superpowers)
