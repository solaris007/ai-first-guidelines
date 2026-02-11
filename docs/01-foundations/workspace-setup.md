# Workspace Setup

## Overview

AI-first development works best with a well-organized workspace. This guide covers directory structure, multi-repo layouts, and configuration file placement.

## Directory Structure

### The Workspace Concept

A **workspace** is a parent directory containing one or more related repositories. AI assistants can read configuration from the workspace level, providing shared context across all contained projects.

```
~/projects/my-workspace/          # Workspace root
├── CLAUDE.md                     # Workspace-level AI configuration
├── .mcp.json                     # MCP server configuration
├── .cursorrules                  # Cursor rules (if using Cursor)
│
├── frontend/                     # Repository 1
│   ├── CLAUDE.md                 # Project-specific overrides
│   ├── package.json
│   └── src/
│
├── backend/                      # Repository 2
│   ├── CLAUDE.md                 # Project-specific overrides
│   ├── pyproject.toml
│   └── src/
│
├── infrastructure/               # Repository 3
│   ├── CLAUDE.md                 # Project-specific overrides
│   └── terraform/
│
└── docs/                         # Documentation repository
    ├── specs/                    # Design specifications
    ├── decisions/                # Architecture Decision Records
    └── runbooks/                 # Operational procedures
```

### Why This Structure?

1. **Shared configuration** - Workspace CLAUDE.md applies to all projects
2. **Cross-repo awareness** - AI can reference other repos when helpful
3. **Centralized docs** - Specs and decisions in one searchable location
4. **Clear boundaries** - Each repo remains independently deployable

## Configuration Hierarchy

AI configuration follows a hierarchy with inheritance:

```
~/.claude/CLAUDE.md           # Global (user-level) defaults
    ↓
workspace/CLAUDE.md           # Workspace-wide rules
    ↓
workspace/project/CLAUDE.md   # Project-specific overrides
```

Lower levels can:
- **Add** new rules and context
- **Override** specific settings from parent levels
- **Reference** other projects in the workspace

## Multi-Repo Coordination

When working across multiple repositories:

### Workspace CLAUDE.md Pattern

```markdown
# My Workspace

## Projects

- **frontend/** - React application (Node 20, pnpm)
- **backend/** - Python API (3.11, FastAPI)
- **infrastructure/** - Terraform (AWS)

## Cross-Project Rules

- API changes require updating both frontend and backend
- Infrastructure changes require approval before apply
- All PRs need passing CI before merge

## Shared Conventions

- Branch naming: `feature/JIRA-123-description`
- Commit messages: Conventional Commits format
- PR titles: `[PROJECT] Brief description`
```

### Working Across Repos

When AI needs to coordinate changes across repositories:

1. **Plan first** - Use plan mode to outline changes in each repo
2. **Order matters** - Typically: API contract → Backend → Frontend → Infra
3. **Link PRs** - Reference related PRs in each PR description
4. **Test integration** - Verify components work together before merge

## Docs Repository

A dedicated docs repository provides:

### Structure

```
docs/
├── specs/                    # Design documents
│   ├── TEMPLATE.md          # Spec template
│   ├── auth-redesign.md     # Example spec
│   └── api-v2.md            # Example spec
│
├── decisions/               # ADRs
│   ├── TEMPLATE.md          # ADR template
│   ├── 001-use-postgres.md  # Example ADR
│   └── 002-auth-strategy.md # Example ADR
│
├── runbooks/                # Operational docs
│   ├── deploy-production.md
│   └── incident-response.md
│
└── README.md                # Index and search tips
```

### Benefits

- **Version controlled** - Full history of design evolution
- **AI-searchable** - AI can reference specs during implementation
- **Review-friendly** - Specs can be reviewed like code
- **Cross-project** - Single source of truth for multi-repo efforts

## Initial Setup Checklist

### 1. Create Workspace Directory

```bash
mkdir -p ~/projects/my-workspace
cd ~/projects/my-workspace
```

### 2. Clone Repositories

```bash
git clone git@github.com:org/frontend.git
git clone git@github.com:org/backend.git
git clone git@github.com:org/infrastructure.git
```

### 3. Create Workspace Configuration

```bash
# Create workspace CLAUDE.md
cat > CLAUDE.md << 'EOF'
# My Workspace

## Projects
- frontend/ - React application
- backend/ - Python API
- infrastructure/ - Terraform

## Rules
- Never commit secrets
- Always run tests before committing
EOF
```

### 4. Create MCP Configuration (if using MCP servers)

```bash
# Create .mcp.json for external tool access
cat > .mcp.json << 'EOF'
{
  "mcpServers": {
    "mcp-atlassian": {
      "command": "uvx",
      "args": ["--python=3.12", "mcp-atlassian"],
      "env": {
        "JIRA_URL": "https://jira.example.com",
        "JIRA_PERSONAL_TOKEN": "${JIRA_PERSONAL_TOKEN}"
      }
    }
  }
}
EOF
```

### 5. Initialize Docs Repository (optional)

```bash
mkdir -p docs/{specs,decisions,runbooks}
# Add templates from 03-templates/
```

## Workspace Maintenance

### Regular Tasks

- **Update CLAUDE.md** when conventions change
- **Archive old specs** by moving to `specs/archive/`
- **Review decisions** periodically for relevance
- **Sync configurations** when adding new projects

### Adding a New Project

1. Clone into workspace directory
2. Create project-level CLAUDE.md if needed
3. Update workspace CLAUDE.md project list
4. Verify AI can access and understand the new project

## See Also

- [Tools Checklist](tools-checklist.md) - Required CLI tools and authentication
- [Claude Code Configuration](../04-configuration/ai-tools/claude-code.md) - Detailed CLAUDE.md patterns
- [MCP Overview](../04-configuration/mcp/overview.md) - MCP server configuration
- [Example Workspace CLAUDE.md](../examples/workspace-claude-md.md) - Complete example
