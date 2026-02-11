# GitHub Copilot Configuration

## Overview

GitHub Copilot provides AI-assisted coding within VS Code and JetBrains IDEs. While it has fewer configuration options than Claude Code or Cursor, there are ways to guide its behavior effectively.

## Configuration Options

### VS Code Settings

Configure Copilot in VS Code settings (`.vscode/settings.json`):

```json
{
  // Enable/disable Copilot
  "github.copilot.enable": {
    "*": true,
    "plaintext": false,
    "markdown": true,
    "yaml": true
  },

  // Copilot Chat settings
  "github.copilot.chat.localeOverride": "en",

  // Inline suggestions
  "editor.inlineSuggest.enabled": true,
  "github.copilot.inlineSuggest.enable": true
}
```

### Language-Specific Settings

Enable or disable Copilot for specific languages:

```json
{
  "github.copilot.enable": {
    "*": true,
    "markdown": true,
    "javascript": true,
    "typescript": true,
    "python": true,
    "yaml": false,
    "json": false
  }
}
```

### File-Level Control

Disable Copilot for sensitive files using `.gitignore`-style patterns:

```json
{
  "github.copilot.advanced": {
    "excludeFiles": [
      "**/.env*",
      "**/secrets/**",
      "**/credentials/**"
    ]
  }
}
```

## Project Instructions

Copilot supports project-level instructions via `.github/copilot-instructions.md`. This is the Copilot equivalent of CLAUDE.md or `.cursorrules`:

```markdown
# Project Instructions for Copilot

## Tech Stack
- Backend: Node.js, Express, TypeScript
- Database: PostgreSQL with Prisma ORM
- Testing: Vitest

## Code Style
- Use functional components with hooks
- Prefer named exports
- Use async/await, not .then() chains

## Conventions
- API responses: { success: boolean, data?: T, error?: string }
- Error handling: Use custom AppError class
- File naming: kebab-case
```

Place this file at `.github/copilot-instructions.md` in your repository. Copilot Chat and inline suggestions will use these instructions as context.

## Guiding Copilot Behavior

Beyond project instructions, guide Copilot through code patterns:

### 1. Code Comments

Copilot reads comments to understand intent:

```typescript
// Use React Query for data fetching
// Return { data, isLoading, error } from hooks
// Always handle loading and error states

export function useProducts() {
  // Copilot will follow the pattern described above
}
```

### 2. Type Definitions

Strong types guide Copilot's suggestions:

```typescript
// Define the expected shape
interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

// Copilot will follow this pattern in implementations
async function fetchProducts(): Promise<ApiResponse<Product[]>> {
  // Copilot knows to return the correct shape
}
```

### 3. Existing Patterns

Copilot learns from your codebase. Establish patterns early:

```typescript
// If your first service looks like this...
class UserService {
  async findById(id: string): Promise<User | null> {
    return this.db.users.findUnique({ where: { id } });
  }

  async create(data: CreateUserInput): Promise<User> {
    return this.db.users.create({ data });
  }
}

// Copilot will suggest similar patterns for new services
class ProductService {
  // Copilot suggests: async findById(id: string): Promise<Product | null>
}
```

### 4. JSDoc Comments

Detailed JSDoc helps Copilot understand function purpose:

```typescript
/**
 * Calculates the total price including tax and discounts.
 *
 * @param items - Array of cart items with price and quantity
 * @param taxRate - Tax rate as decimal (e.g., 0.08 for 8%)
 * @param discountCode - Optional discount code for percentage off
 * @returns Total price after tax and discounts
 * @throws Error if items array is empty
 *
 * @example
 * calculateTotal([{ price: 10, quantity: 2 }], 0.08, 'SAVE10')
 * // Returns: 19.44 (20 - 10% discount + 8% tax)
 */
function calculateTotal(
  items: CartItem[],
  taxRate: number,
  discountCode?: string
): number {
  // Copilot has full context for implementation
}
```

## Copilot Chat

Copilot Chat provides conversational AI assistance:

### Effective Prompts

**Context Setting**:
```
/explain this codebase uses Express with TypeScript and Prisma ORM
```

**Specific Requests**:
```
Add error handling to this function following the pattern in error-handler.ts
```

**Style Guidance**:
```
Refactor to use async/await instead of .then() chains
```

### Chat Commands

| Command | Purpose |
|---------|---------|
| `/explain` | Explain selected code |
| `/fix` | Suggest fixes for problems |
| `/tests` | Generate tests for code |
| `/docs` | Generate documentation |
| `@workspace` | Query across workspace |

### Workspace Context

Use `@workspace` to help Copilot understand project structure:

```
@workspace What patterns are used for API error handling?
```

```
@workspace Show me examples of form validation in this project
```

## Best Practices

### Maximize Pattern Recognition

1. **Consistent file structure** - Copilot learns from patterns
2. **Type everything** - Types are strong hints
3. **Comment complex logic** - Explain the "why"
4. **Use descriptive names** - `calculateDiscountedPrice` not `calc`

### Guide Suggestions

When Copilot suggests something wrong:
1. **Reject and comment** - Add a comment explaining what you want
2. **Start typing** - Give Copilot a stronger hint
3. **Show the pattern** - Write one example, let Copilot repeat

### Security Considerations

- **Exclude sensitive files** - Use `excludeFiles` setting
- **Review suggestions** - Don't blindly accept security-sensitive code
- **Don't include secrets in comments** - Copilot might repeat them

### Team Configuration

Share settings via `.vscode/settings.json` committed to repo:

```json
{
  "github.copilot.enable": {
    "*": true,
    "plaintext": false
  },
  "github.copilot.advanced": {
    "excludeFiles": [
      "**/.env*",
      "**/secrets/**"
    ]
  }
}
```

## Comparison with Other Tools

| Feature | Copilot | Claude Code | Cursor |
|---------|---------|-------------|--------|
| Inline suggestions | Strong | CLI-based (not inline) | Strong |
| Chat interface | Yes | Primary | Yes |
| Configuration file | `.github/copilot-instructions.md` | CLAUDE.md | .cursorrules |
| External tools (MCP) | Yes (VS Code) | Yes | Yes |
| IDE integration | VS Code, JetBrains | CLI only | Cursor IDE |
| Multi-file context | Limited | Full | Full |

## When to Use Copilot

**Copilot excels at**:
- Inline code completion
- Repetitive patterns
- Boilerplate generation
- Quick function implementations

**Consider other tools for**:
- Complex multi-file changes
- Codebase exploration
- External tool integration
- Detailed project rules

## See Also

- [Claude Code Configuration](claude-code.md)
- [Cursor Configuration](cursor.md)
- [Environment & Secrets](../env-secrets.md)
