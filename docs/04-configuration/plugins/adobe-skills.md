# Adobe Skills for AI Coding Agents

## Overview

[Adobe Skills](https://github.com/adobe/skills) is a collection of reusable AI agent capabilities for AEM Edge Delivery Services development. It provides 17 specialized skills organized into three categories - core development, discovery, and migration - that enable AI coding agents to assist with content-driven workflows, block implementation, webpage imports, and project analysis.

## Installation

Adobe Skills supports multiple installation methods:

### Claude Code Plugins (Recommended)

```bash
/plugin marketplace add adobe/skills
/plugin install aem-edge-delivery-services@adobe-skills
```

After installation, restart Claude Code. Skills will activate automatically when your requests match their triggers.

### Vercel Skills (npx)

```bash
# Install all skills
npx skills add https://github.com/adobe/skills/tree/main/skills/aem/edge-delivery-services --all

# Install specific skills
npx skills add adobe/skills -s content-driven-development building-blocks testing-blocks

# List available skills
npx skills add adobe/skills --list
```

### GitHub CLI Extension

```bash
gh extension install trieloff/gh-upskill
gh upskill adobe/skills
```

## Skills

### Core Development

| Skill | Purpose |
|-------|---------|
| `content-driven-development` | Orchestrates the CDD workflow for all code changes |
| `analyze-and-plan` | Analyze requirements and define acceptance criteria |
| `building-blocks` | Implement blocks and core functionality |
| `testing-blocks` | Browser testing and validation |
| `content-modeling` | Design author-friendly content models |
| `code-review` | Self-review and PR review |

### Discovery

| Skill | Purpose |
|-------|---------|
| `block-inventory` | Survey available blocks in project and Block Collection |
| `block-collection-and-party` | Search reference implementations |
| `docs-search` | Search aem.live documentation |
| `find-test-content` | Find existing content for testing |

### Migration

| Skill | Purpose |
|-------|---------|
| `page-import` | Import webpages (orchestrator) |
| `scrape-webpage` | Scrape and analyze webpage content |
| `identify-page-structure` | Analyze page sections |
| `page-decomposition` | Analyze content sequences |
| `authoring-analysis` | Determine authoring approach |
| `generate-import-html` | Generate structured HTML |
| `preview-import` | Preview imported content |

## Workflow Example

### Block Development with Adobe Skills

```
1. Request: "Add a hero block with video background"

2. content-driven-development skill orchestrates:
   - Activates analyze-and-plan for requirements
   - Checks block-inventory for existing implementations
   - Searches block-collection-and-party for reference code

3. building-blocks skill activates:
   - Implements the block following EDS patterns
   - Creates content model for authoring

4. testing-blocks skill activates:
   - Validates block rendering
   - Tests with real content

5. code-review skill before completion:
   - Reviews against EDS best practices
   - Ready for PR
```

### Page Migration with Adobe Skills

```
1. Request: "Import the product page from example.com/products"

2. page-import skill orchestrates:
   - scrape-webpage captures the source
   - identify-page-structure analyzes sections
   - page-decomposition breaks down content sequences
   - authoring-analysis determines the approach
   - generate-import-html produces structured output
   - preview-import validates the result
```

## Integration with MCP

Adobe Skills compose with MCP tools for end-to-end workflows:

```
Skills used:
- content-driven-development (workflow orchestration)
- building-blocks (implementation)
- testing-blocks (validation)

MCP tools used:
- jira_get_issue (read requirements)
- create_branch (start work)
- create_pull_request (submit code)
- conversations_add_message (notify team via Slack)
```

## Adobe AI Skills (Adobe-AIFoundations)

[Adobe-AIFoundations/adobe-skills](https://github.com/Adobe-AIFoundations/adobe-skills) is a broader collection of AI agent skills maintained by Adobe's AI Foundations team. While the AEM EDS skills above focus on Edge Delivery Services development, Adobe AI Skills covers security, branding, documentation, and AEM Java tooling.

### Available Skills

| Category | Skills | Description |
|----------|--------|-------------|
| **Security** | `adobe-security-foundations`, `adobe-security-lang`, `adobe-security-cloud`, `adobe-security-services`, `adobe-security-audit` | Foundational security principles, language-specific patterns (Python, Java, Node.js, PHP, Ruby, Rust, C, C++), cloud infrastructure security (AWS, Azure, GCP, Kubernetes, Terraform), service-layer security, and audit workflows with Snyk |
| **Content & Docs** | `adobe-branding`, `adobe-whitepaper`, `ai-writing-detector` | Brand guidelines compliance, PDF whitepaper generation with Adobe Clean typography, and AI-generated writing pattern detection |
| **Agent Development** | `devkit-ai-agent` | LangGraph sample agent repo generation via `create-myapp` CLI |
| **AEM Java** | `aem-module-java17`, `osgi-scr-migrator` | Java 17 migration for AEM Maven projects, Felix SCR to OSGi R6/R7 annotation migration |

### Relationship to Adobe Cursor Rules

The security skills in this collection cover the same domains as [Adobe Cursor Rules](adobe-cursor-rules.md) (global, lang, cloud) but packaged as SKILL.md files for Claude Code rather than `.mdc` files for Cursor. Teams using both tools get consistent security coverage: Cursor rules activate automatically in the editor, while skills guide Claude Code during implementation.

### Referenced Skill Collections

The repo also links to additional skill collections from across Adobe:

- [OneAdobe/claude-workflow](https://github.com/OneAdobe/claude-workflow) - Agentic development workflow with specialized agents (Technical Analyst, Software Architect, TDD Engineer, QA Validator)
- [addyosmani/web-quality-skills](https://github.com/addyosmani/web-quality-skills) - Web quality audits for performance, accessibility, SEO, and Core Web Vitals
- [adobe/helix-website skills](https://github.com/adobe/helix-website/tree/main/.claude/skills) - AEM EDS skills (the upstream source for the skills documented above)

## See Also

- [Superpowers Plugin](superpowers.md) - General-purpose development workflow skills
- [Adobe Cursor Rules](adobe-cursor-rules.md) - Security and development rules for Cursor (.mdc format)
- [Claude Code Configuration](../ai-tools/claude-code.md) - Base tool configuration
- [MCP Overview](../mcp/overview.md) - External tool integration
- [Adobe Skills (AEM EDS) on GitHub](https://github.com/adobe/skills)
- [Adobe AI Skills on GitHub](https://github.com/Adobe-AIFoundations/adobe-skills)
