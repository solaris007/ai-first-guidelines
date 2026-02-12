# Cursor Rules Setup

A practical example showing how to set up a project with both Cursor rules (`.mdc` format) and Claude Code configuration for consistent AI behavior across tools.

## Recommended Project Structure

```
my-project/
├── .cursor/
│   ├── rules/
│   │   ├── security-global/          # From adobe-cursor-rules
│   │   │   ├── security-global-base.mdc
│   │   │   ├── security-global-api.mdc
│   │   │   ├── security-global-auth.mdc
│   │   │   └── ...
│   │   ├── security-lang/            # Language-specific (pick your stack)
│   │   │   └── security-lang-node.mdc
│   │   └── project/                  # Your project-specific rules
│   │       ├── architecture.mdc
│   │       └── conventions.mdc
│   ├── mcp.json                      # MCP servers for Cursor
│   └── settings.json                 # Cursor project settings
├── .cursorignore                     # Exclude from AI context
├── .cursorindexingignore             # Exclude from code indexing
├── CLAUDE.md                         # Claude Code configuration
├── .mcp.json                         # MCP servers for Claude Code
├── .github/
│   └── copilot-instructions.md       # GitHub Copilot instructions
└── src/
    └── ...
```

## Step-by-Step Bootstrap

### 1. Add Adobe Security Rules

Start by copying the baseline security rules from [adobe-cursor-rules](https://github.com/OneAdobe/adobe-cursor-rules):

```bash
# Clone the template repo
git clone https://github.com/OneAdobe/adobe-cursor-rules.git /tmp/adobe-cursor-rules

# Create the rules directory in your project
mkdir -p .cursor/rules

# Copy the security baseline (recommended for all projects)
cp -r /tmp/adobe-cursor-rules/.cursor/rules/security-global/ .cursor/rules/

# Copy language-specific rules for your stack (example: Node.js)
cp -r /tmp/adobe-cursor-rules/.cursor/rules/security-lang/security-lang-node.mdc \
      .cursor/rules/security-lang/

# Clean up
rm -rf /tmp/adobe-cursor-rules
```

### 2. Add Project-Specific Rules

Create `.mdc` files for your project's conventions under `.cursor/rules/project/`:

```yaml
---
description: Project architecture and conventions
globs:
alwaysApply: true
---

# My Service - Architecture

## Tech Stack
- Runtime: Node.js 20, TypeScript 5
- Framework: Express
- Database: PostgreSQL with Prisma ORM
- Testing: Vitest, Supertest

## Project Structure
- `src/routes/` - Express route handlers
- `src/services/` - Business logic
- `src/models/` - Prisma model extensions
- `src/middleware/` - Express middleware

## Conventions
- Use functional patterns, avoid classes
- All async handlers must use error middleware (no try/catch in routes)
- Database access only through service layer, never in routes
- Environment config via `src/config.ts`, not raw process.env
```

### 3. Add File-Scoped Rules

For rules that only apply to certain file types, use `globs`:

```yaml
---
description: Test file conventions
globs: "**/*.test.ts,**/*.spec.ts"
alwaysApply: false
---

# Testing Conventions

- Use `describe` blocks grouped by function/method
- Use AAA pattern: Arrange, Act, Assert
- Mock external dependencies, never hit real APIs
- Name tests as: "should [expected behavior] when [condition]"
- Prefer `toStrictEqual` over `toEqual` for object comparisons
```

### 4. Configure Ignore Files

**`.cursorignore`** - Exclude files from AI context (Cursor won't read these):

```
# Dependencies
node_modules/

# Build output
dist/
build/
.next/

# Secrets and environment
.env
.env.*

# Large generated files
package-lock.json
pnpm-lock.yaml

# Test fixtures and snapshots
**/__snapshots__/
**/fixtures/large-*.json
```

**`.cursorindexingignore`** - Exclude from Cursor's code index (won't appear in search):

```
# Same as .cursorignore, plus:
docs/
*.md
*.mdx
coverage/
.git/
```

### 5. Set Up Claude Code Equivalent

Your `CLAUDE.md` should cover the same security and convention rules. The content overlaps with your `.mdc` rules but uses plain markdown:

```markdown
# My Service

## MUST Rules
- MUST NOT commit secrets to version control
- MUST validate all user input
- MUST use parameterized queries (Prisma handles this)
- MUST run tests before pushing

## Conventions
- Functional patterns, no classes
- Database access through service layer only
- Error middleware handles async errors in routes

## Tech Stack
- Node.js 20, TypeScript 5, Express, Prisma, PostgreSQL
- Tests: Vitest, Supertest
```

### 6. Add Copilot Instructions (Optional)

If your team also uses GitHub Copilot, add `.github/copilot-instructions.md`:

```markdown
# Copilot Instructions

## Security
- Always use parameterized queries
- Validate and sanitize user input
- Never log sensitive data

## Conventions
- Use TypeScript strict mode
- Functional patterns, no classes
- All routes use error middleware
```

## Multi-Tool Rule Strategy

The same security principles need different packaging for each tool:

| Concern | Cursor `.mdc` | CLAUDE.md | Copilot Instructions |
|---------|---------------|-----------|---------------------|
| Format | YAML frontmatter + markdown | Plain markdown | Plain markdown |
| Scoping | `globs`, rule modes | Directory hierarchy | Single file |
| Security rules | `security-global/*.mdc` | MUST rules section | Security section |
| Project context | `project/*.mdc` | Overview + conventions | Instructions section |
| Enforcement | Automatic (Always Apply) | Always loaded | Always loaded |

The key approach: maintain canonical rules in one place (e.g., a shared doc or the `security-global` rules), then adapt the expression for each tool. A generation script can help:

```bash
#!/bin/bash
# generate-ai-rules.sh - Extract shared rules into tool-specific formats
# This is a starting point; adapt to your project's needs

RULES_SOURCE=".cursor/rules/project/architecture.mdc"

echo "Generating CLAUDE.md rules from ${RULES_SOURCE}..."
# Strip YAML frontmatter and output as CLAUDE.md section
sed '1,/^---$/d; 1,/^---$/d' "${RULES_SOURCE}" >> CLAUDE.md
```

## See Also

- [Cursor Configuration](../04-configuration/ai-tools/cursor.md) - Full Cursor setup guide
- [Adobe Cursor Rules](../04-configuration/plugins/adobe-cursor-rules.md) - Complete rule catalog
- [Claude Code Configuration](../04-configuration/ai-tools/claude-code.md) - CLAUDE.md patterns
- [Copilot Configuration](../04-configuration/ai-tools/copilot.md) - Copilot setup
