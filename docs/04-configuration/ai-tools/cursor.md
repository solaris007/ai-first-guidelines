# Cursor Configuration

## Overview

Cursor uses `.cursorrules` files to provide context and instructions for AI assistance. This is similar to Claude Code's CLAUDE.md but with Cursor-specific syntax and capabilities.

## .cursorrules

### Location

Place `.cursorrules` in your project or workspace root:

```
my-workspace/
├── .cursorrules           # Workspace-level rules
├── frontend/
│   └── .cursorrules       # Frontend-specific rules (optional)
└── backend/
    └── .cursorrules       # Backend-specific rules (optional)
```

### Basic Structure

```
# Project: My Application

## Overview
Brief description of the project and its purpose.

## Tech Stack
- Frontend: React 18, TypeScript, Tailwind CSS
- Backend: Node.js, Express, PostgreSQL
- Infrastructure: AWS, Terraform

## Code Style
- Use functional components with hooks
- Prefer named exports over default exports
- Use TypeScript strict mode

## Conventions
- File naming: kebab-case for files, PascalCase for components
- Test files: *.test.ts or *.spec.ts alongside source files
- API responses: Always return { data, error, meta } shape

## Important Patterns
[Describe key patterns the AI should follow]

## Things to Avoid
- Don't use any type in TypeScript
- Don't use class components
- Don't commit .env files
```

### Effective Rules

**Project Context**:
```
## Architecture

This is a monorepo with:
- /apps/web - Next.js frontend
- /apps/api - Express backend
- /packages/shared - Shared TypeScript types

All packages use pnpm workspaces.
```

**Technology Specifics**:
```
## Database

Using Prisma ORM with PostgreSQL.
- Schema: prisma/schema.prisma
- Migrations: prisma/migrations/
- Always use transactions for multi-table operations
```

**Behavioral Rules**:
```
## AI Behavior

When writing code:
- Always add JSDoc comments to exported functions
- Include error handling for all async operations
- Write tests for new functionality

When reviewing code:
- Check for security issues (SQL injection, XSS)
- Verify error handling is comprehensive
- Ensure types are specific (no any)
```

### Example: Full .cursorrules

```
# E-Commerce Platform

## Overview
Full-stack e-commerce application with React frontend and Node.js backend.

## Tech Stack
- Frontend: React 18, TypeScript 5, Vite, Tailwind CSS
- Backend: Node.js 20, Express, Prisma, PostgreSQL
- Testing: Vitest, React Testing Library, Supertest
- Infrastructure: Docker, AWS ECS, RDS

## Project Structure
/src
  /components    - React components (PascalCase folders)
  /hooks         - Custom React hooks (use*.ts)
  /services      - API client and business logic
  /types         - TypeScript type definitions
  /utils         - Utility functions
/server
  /routes        - Express route handlers
  /services      - Backend business logic
  /middleware    - Express middleware
  /models        - Prisma model extensions

## Code Standards

### TypeScript
- Strict mode enabled
- No `any` type - use `unknown` if type is truly unknown
- Prefer interfaces over types for object shapes
- Use const assertions for literal types

### React
- Functional components only
- Use React Query for server state
- Use Zustand for client state
- Prefer composition over prop drilling

### API Design
- RESTful endpoints under /api/v1/
- Request validation with Zod
- Response shape: { success: boolean, data?: T, error?: string }
- Always return appropriate HTTP status codes

### Error Handling
- Backend: Use custom AppError class
- Frontend: Show user-friendly messages, log details
- Never expose internal errors to users

## Testing Requirements
- Unit tests for all utility functions
- Integration tests for API endpoints
- Component tests for complex UI logic
- E2E tests for critical user flows

## Security Rules
- Sanitize all user input
- Use parameterized queries (Prisma handles this)
- Validate file uploads (type, size)
- Rate limit authentication endpoints

## Common Commands
- `pnpm dev` - Start development servers
- `pnpm test` - Run all tests
- `pnpm build` - Production build
- `pnpm db:migrate` - Run database migrations

## Things to Avoid
- Don't use `console.log` in production code (use logger)
- Don't store sensitive data in localStorage
- Don't use string concatenation for SQL
- Don't skip TypeScript errors with @ts-ignore
```

## Cursor Rules (.mdc Format)

Cursor's newer `.cursor/rules/*.mdc` format replaces the single `.cursorrules` file with a directory of scoped, frontmatter-driven rule files. Use this format for projects that need structured, domain-organized rules.

### Directory Structure

```
my-project/
├── .cursor/
│   └── rules/
│       ├── security-global/        # Security baseline
│       │   ├── security-global-base.mdc
│       │   └── security-global-api.mdc
│       ├── security-lang/          # Language-specific
│       │   └── security-lang-node.mdc
│       └── project/                # Project-specific
│           ├── architecture.mdc
│           └── conventions.mdc
├── .cursorrules                    # Legacy (optional, still supported)
└── ...
```

### .mdc File Format

Each `.mdc` file is markdown with a YAML frontmatter block that controls when the rule activates:

```yaml
---
description: Prevent SQL injection in database queries
globs: "src/db/**/*.ts,src/models/**/*.ts"
alwaysApply: false
---

# SQL Safety

- Always use parameterized queries
- Never concatenate user input into SQL strings
- Use the ORM's built-in escaping for dynamic queries
```

### Rule Modes

The frontmatter fields determine how and when a rule activates:

| Mode | Frontmatter | Behavior |
|------|-------------|----------|
| **Always Apply** | `alwaysApply: true` | Active in every context, no conditions |
| **Apply Intelligently** | `alwaysApply: false`, `description` set, no `globs` | Agent decides based on context and the description |
| **Apply to Specific Files** | `globs` set | Only active when working with files matching the glob pattern |
| **Apply Manually** | `alwaysApply: false`, no `description`, no `globs` | Only applied when explicitly referenced by name |

**Guidelines for choosing a mode:**

- Use **Always Apply** sparingly - for critical security baselines only
- Use **Apply Intelligently** for domain rules the agent should pick up from context
- Use **Apply to Specific Files** for language-specific or directory-scoped rules
- Use **Apply Manually** for reference material used on demand (e.g., migration guides)

### When to Use .cursorrules vs .mdc

| Scenario | Recommended Format |
|----------|--------------------|
| Small project, few rules | `.cursorrules` (simple, single file) |
| Team-shared security rules | `.mdc` (scoped, domain-organized) |
| Multi-language project | `.mdc` (file-glob scoping per language) |
| Adopting adobe-cursor-rules | `.mdc` (required format) |
| Quick personal project | `.cursorrules` (fastest to set up) |

Both formats can coexist. Cursor loads `.cursorrules` as an "always apply" rule alongside any `.mdc` files.

## Cursor Ignore Files

Cursor provides two ignore files to control what the AI can see and index:

### .cursorignore

Excludes files from AI context. Cursor will not read these files when generating responses.

```
# Dependencies
node_modules/

# Build output
dist/
build/

# Secrets
.env
.env.*

# Large generated files
package-lock.json
pnpm-lock.yaml
```

### .cursorindexingignore

Excludes files from Cursor's code index. These files won't appear in codebase search results.

```
# Same exclusions as .cursorignore, plus:
docs/
coverage/
**/__snapshots__/
.git/
```

Place both files in your project root. They use `.gitignore` syntax.

## Cursor Settings

### Project-Level Settings

Create `.cursor/settings.json` for project-specific Cursor settings:

```json
{
  "cursor.general.aiModel": "claude-sonnet-4-5",
  "cursor.chat.defaultContext": [
    ".cursorrules",
    "README.md",
    "package.json"
  ]
}
```

### Workspace Settings

Cursor respects VS Code workspace settings in `.vscode/settings.json`:

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "typescript.preferences.importModuleSpecifier": "relative",
  "cursor.autocomplete.enabled": true
}
```

## MCP Support

Cursor supports MCP servers for external tool integration. See [MCP Overview](../mcp/overview.md) for details on what MCP is, and the [MCP Servers Catalog](../mcp/servers.md) for recommended servers and their setup.

Configuration location: `.cursor/mcp.json` or workspace `.mcp.json`

> The following Cursor MCP guidance covers integrating MCP servers with Cursor using macOS Keychain for secret management.

### Cursor's Limited MCP Environment

Cursor provides MCP servers with a **very limited environment** - global environment variables from your shell profile are not available to MCP processes. This means the typical approach of exporting secrets as environment variables (e.g., in `.zshrc`) will not work.

To work around this, use a **wrapper script** that retrieves secrets at launch time and exports them before starting the actual MCP server.

### Secrets via macOS Keychain

Instead of 1Password (see [Secrets Management with 1Password](../mcp/servers.md#secrets-management-with-1password)), you can use the built-in macOS Keychain via the `security` CLI. This requires no additional software.

**Storing a secret:**

```bash
ACCOUNT=myuser@example.com
SERVICE=jira.example.com
security add-generic-password -a ${ACCOUNT} -s ${SERVICE} -w
# Prompts for the secret interactively (safer than passing on command line)
```

**Retrieving a secret:**

```bash
security find-generic-password -a ${ACCOUNT} -s ${SERVICE} -w
```

### Wrapper Script for Secret Injection

Create a `wrapper.sh` script that accepts `-e` parameters to map Keychain entries to environment variables before launching the MCP server.

Each `-e` argument uses the format `NAME:USER:SERVICE`:

| Field | Description |
|-------|-------------|
| `NAME` | Environment variable to set |
| `USER` | Keychain account name (`-a`) |
| `SERVICE` | Keychain service name (`-s`) |

This translates to:

```bash
export NAME=$(security find-generic-password -a USER -s SERVICE -w)
```

**Example `wrapper.sh`:**

```bash
#!/bin/bash
# Wrapper to inject macOS Keychain secrets into MCP server environment.
# Usage: wrapper.sh [-e NAME:USER:SERVICE]... <command> [args...]

while getopts "e:" opt; do
  case ${opt} in
    e)
      IFS=':' read -r VAR_NAME KS_USER KS_SERVICE <<< "${OPTARG}"
      export "${VAR_NAME}"=$(security find-generic-password -a "${KS_USER}" -s "${KS_SERVICE}" -w)
      ;;
  esac
done
shift $((OPTIND - 1))

exec "$@"
```

Make it executable and place it on your PATH (e.g., `~/bin/wrapper.sh`).

### Example: Atlassian MCP with Keychain Wrapper

Store your Jira and Confluence personal access tokens in the Keychain:

```bash
security add-generic-password -a myuser@example.com -s jira.example.com -w
security add-generic-password -a myuser@example.com -s wiki.example.com -w
```

Then configure `.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "mcp-atlassian": {
      "command": "wrapper.sh",
      "args": [
        "-eJIRA_PERSONAL_TOKEN:myuser@example.com:jira.example.com",
        "-eCONFLUENCE_PERSONAL_TOKEN:myuser@example.com:wiki.example.com",
        "uvx",
        "--python=3.12",
        "mcp-atlassian"
      ],
      "env": {
        "JIRA_URL": "https://jira.example.com",
        "CONFLUENCE_URL": "https://wiki.example.com"
      }
    }
  }
}
```

**Note**: Personal access tokens are created from your Jira/Confluence user profile under "Personal Access Tokens". These tokens expire - when they do, update the Keychain entry and restart Cursor.

### Example: Slack MCP with Keychain Wrapper

Store your Slack `xoxp-...` token (not `xoxb-...`) in the Keychain:

```bash
security add-generic-password -a myuser@example.com -s slack.com -w
```

Recommended OAuth scopes (read-only):

| Scope | Purpose |
|-------|---------|
| `channels:history` | View messages in public channels |
| `channels:read` | View basic info about public channels |
| `groups:history` | View messages in private channels |
| `groups:read` | View basic info about private channels |
| `im:history` | View direct messages |
| `im:read` | View basic info about direct messages |
| `mpim:history` | View group direct messages |
| `mpim:read` | View basic info about group direct messages |
| `users:read` | View people in a workspace |
| `search:read` | Search workspace content |

Write scopes are omitted intentionally - add them only when needed.

Configure `.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "slack": {
      "command": "wrapper.sh",
      "args": [
        "-eSLACK_MCP_XOXP_TOKEN:myuser@example.com:slack.com",
        "npx",
        "-y",
        "slack-mcp-server@latest",
        "--transport",
        "stdio"
      ],
      "env": {
        "SLACK_TEAM_ID": "T12345678"
      }
    }
  }
}
```

### Keychain vs 1Password

| Aspect | macOS Keychain | 1Password CLI |
|--------|---------------|---------------|
| Setup | Built-in, no install | Requires `op` CLI |
| Auth | macOS login (automatic) | Periodic `op signin` |
| Sharing | Local only | Syncs across devices/team |
| Audit | None | Full audit trail |
| Rotation | Manual `security` update | Update in 1Password |

Both approaches achieve the same goal: keeping secrets out of config files. Choose based on your team's tooling.

## Best Practices

### Keep Rules Focused

**Good**: Specific, actionable rules
```
Use React Query's useQuery for all GET requests.
Mutations should use useMutation with optimistic updates.
```

**Avoid**: Vague guidance
```
Use best practices for data fetching.
```

### Update Regularly

- Update `.cursorrules` when patterns change
- Remove outdated rules
- Add rules when you find yourself repeating corrections

See [Configuration Evolution](../../02-lifecycle/06-config-evolution.md) for detailed guidance on maintaining AI configuration over time.

### Working Context

Add a Working Context section to declare defaults and frequently-used commands. This eliminates repetitive questions like "which project?" or "which environment?"

```
## Working Context

### Defaults
- Jira: MYPROJ project (override with "in OTHERPROJ")
- GitHub: myorg/main-repo
- Environment: staging (override with "in prod")

### Quick Reference
- Run tests: pnpm test
- Deploy: make deploy-staging

### Active Work
- Epic: MYPROJ-100 (Q1 migration)
- Focus: API refactoring
```

### Team Alignment

- Commit `.cursorrules` to version control
- Review rules changes in PRs
- Document why rules exist (not just what they are)

### Multi-Tool Rule Strategy

If your team uses multiple AI tools, the same security and convention rules need different packaging for each:

| Aspect | Cursor `.mdc` | CLAUDE.md | `.github/copilot-instructions.md` |
|--------|---------------|-----------|-----------------------------------|
| Format | YAML frontmatter + markdown | Plain markdown | Plain markdown |
| Scoping | `globs`, rule modes | Directory hierarchy | Single file |
| Loading | Automatic by mode | Always loaded | Always loaded |
| Strengths | Fine-grained file targeting | Inheritance across directories | GitHub integration |

**Recommended approach:**

1. Maintain canonical rules in one authoritative source (e.g., your `security-global` `.mdc` rules or a shared doc)
2. Express rules in each tool's native format
3. Consider a script to generate tool-specific files from the canonical source

```bash
# Example: Generate both from a shared source
./scripts/generate-ai-rules.sh --format cursorrules > .cursorrules
./scripts/generate-ai-rules.sh --format claude > CLAUDE.md
./scripts/generate-ai-rules.sh --format copilot > .github/copilot-instructions.md
```

See the [Cursor Rules Setup](../../examples/cursor-rules-setup.md) example for a complete multi-tool project scaffold.

## Comparison with CLAUDE.md

| Aspect | .cursorrules | CLAUDE.md |
|--------|--------------|-----------|
| Format | Plain text (`.cursorrules`) or YAML frontmatter + markdown (`.mdc`) | Markdown |
| Location | Project root | Project root or workspace |
| Hierarchy | Single file | Can inherit from parent dirs |
| MCP Support | Via .cursor/mcp.json | Via .mcp.json |
| IDE | Cursor only | Claude Code CLI |

## See Also

- [Adobe Cursor Rules](../plugins/adobe-cursor-rules.md) - 45+ curated `.mdc` rules for security and development
- [Cursor Rules Setup Example](../../examples/cursor-rules-setup.md) - Bootstrap a project with Cursor rules + Claude Code
- [Claude Code Configuration](claude-code.md)
- [Copilot Configuration](copilot.md)
- [MCP Overview](../mcp/overview.md)
- [MUST Rules](../../05-guardrails/must-rules.md)
