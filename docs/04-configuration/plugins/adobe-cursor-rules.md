# Adobe Cursor Rules

## Overview

[Adobe Cursor Rules](https://github.com/OneAdobe/adobe-cursor-rules) is a curated collection of 45+ `.mdc` rule files maintained by Adobe's PASS AIDE team. The rules guide Cursor's AI to generate secure, standards-compliant code by default - no manual prompting required.

Early internal testing shows a **50%+ reduction in vulnerabilities** in AI-generated code when these rules are active.

## What's Included

The rules are organized into five domains:

| Domain | Rules | Focus |
|--------|-------|-------|
| **security-global** | 17 | Universal security principles - API security, auth, injection prevention, input validation, SSRF, XSS, path traversal, and more |
| **security-lang** | 8 | Language-specific secure coding for C, C++, Java, Node.js, PHP, Python, Ruby, Rust |
| **security-cloud** | 10 | Cloud infrastructure security for AWS, Azure, GCP, Kubernetes, Terraform, CI/CD |
| **react-spectrum** | 4 | Adobe React Spectrum UI library - S2 components, style macros, v3-to-S2 migration |
| **stock-codegen** | 6 | Adobe Stock testing patterns - monorepo development, test coverage, test isolation |

## Rule Modes

The rules use Cursor's four-mode system to control when they activate:

| Mode | Usage | Example Rules |
|------|-------|---------------|
| **Always Apply** | Active in every context | Core security principles (`security-global-base.mdc`) |
| **Apply Intelligently** | Agent decides based on context | Most security rules - API, auth, data protection, injection prevention |
| **Apply to Specific Files** | Scoped via `globs` frontmatter | Language-specific rules (e.g., Node.js rules for `*.js`, `*.ts`) |
| **Apply Manually** | On-demand for targeted checks | MCP usage guidance, XXE prevention |

## Getting Started

### Option 1: Use the GitHub Template

Create a new repo from the template, then copy the `.cursor/rules/` directory into your project:

```
https://github.com/new?owner=OneAdobe&template_name=adobe-cursor-rules
```

### Option 2: Copy Rules Directly

1. Clone or download from [OneAdobe/adobe-cursor-rules](https://github.com/OneAdobe/adobe-cursor-rules)
2. Copy the domains you need into your project's `.cursor/rules/` directory
3. Optionally copy `.cursorignore` and `.cursorindexingignore`

```bash
# Example: copy security rules into your project
cp -r adobe-cursor-rules/.cursor/rules/security-global/ \
      your-project/.cursor/rules/security-global/
cp -r adobe-cursor-rules/.cursor/rules/security-lang/ \
      your-project/.cursor/rules/security-lang/
```

### Cherry-Picking Domains

Not every project needs all 45 rules. Pick what matters:

- **All projects**: `security-global` (the universal baseline)
- **Language-specific**: Add rules from `security-lang` for your stack
- **Cloud/infra work**: Add `security-cloud` for your provider
- **React Spectrum apps**: Add `react-spectrum` for UI work
- **Adobe Stock**: Add `stock-codegen` for testing patterns

## Domain Catalog

### security-global (17 rules)

Universal rules that apply regardless of language or framework.

| Rule File | Description |
|-----------|-------------|
| `security-global-base.mdc` | Core security principles (Always Apply) |
| `security-global-api.mdc` | API security - authentication, rate limiting, input validation |
| `security-global-auth.mdc` | Authentication and authorization patterns |
| `security-global-data-protection.mdc` | Data classification, encryption, PII handling |
| `security-global-dependency-mgmt.mdc` | Dependency scanning, version pinning |
| `security-global-error-handling.mdc` | Secure error messages, no stack trace leaks |
| `security-global-injection-prevention.mdc` | SQL injection, command injection, template injection |
| `security-global-input-validation.mdc` | Input sanitization, allowlists, type checking |
| `security-global-output-encoding.mdc` | XSS prevention, context-aware encoding |
| `security-global-pathtraversal-prevention.mdc` | Path traversal attacks, file access controls |
| `security-global-secure-configuration.mdc` | Secure defaults, hardening |
| `security-global-sql-usage.mdc` | Parameterized queries, ORM safety |
| `security-global-ssrf-prevention.mdc` | Server-side request forgery prevention |
| `security-global-xxe-prevention.mdc` | XML external entity prevention (Manual mode) |
| `security-global-dangerous-flows.mdc` | High-risk code patterns and mitigations |
| `security-global-mcp-usage.mdc` | Safe MCP server usage patterns (Manual mode) |
| `security-global-snyk.mdc` | Snyk integration for vulnerability scanning |

### security-lang (8 rules)

Language-specific secure coding patterns. These use `globs` frontmatter to activate only for matching file types.

| Rule File | Languages/Files |
|-----------|-----------------|
| `security-lang-c.mdc` | C (`*.c`, `*.h`) |
| `security-lang-cpp.mdc` | C++ (`*.cpp`, `*.hpp`, `*.cc`) |
| `security-lang-java.mdc` | Java (`*.java`) |
| `security-lang-node.mdc` | Node.js (`*.js`, `*.ts`, `*.mjs`) |
| `security-lang-php.mdc` | PHP (`*.php`) |
| `security-lang-python.mdc` | Python (`*.py`) |
| `security-lang-ruby.mdc` | Ruby (`*.rb`) |
| `security-lang-rust.mdc` | Rust (`*.rs`) |

### security-cloud (10 rules)

Cloud infrastructure and deployment security.

| Rule File | Scope |
|-----------|-------|
| `security-cloud-aws.mdc` | AWS general - IAM, VPC, encryption |
| `security-cloud-aws-compute.mdc` | EC2, ECS, EKS security |
| `security-cloud-aws-databases.mdc` | RDS, DynamoDB, ElastiCache |
| `security-cloud-aws-lambda.mdc` | Lambda function security |
| `security-cloud-aws-s3.mdc` | S3 bucket policies, encryption |
| `security-cloud-azure.mdc` | Azure resource security |
| `security-cloud-gcp.mdc` | GCP resource security |
| `security-cloud-kubernetes.mdc` | Pod security, RBAC, network policies |
| `security-cloud-terraform.mdc` | Terraform state, modules, providers |
| `security-cloud-cicd-security.mdc` | Pipeline security, secret handling |

### react-spectrum (4 rules)

Adobe React Spectrum UI library patterns.

| Rule File | Scope |
|-----------|-------|
| `react-spectrum-s2.mdc` | Spectrum 2 component patterns |
| `react-spectrum-style-macro-s2.mdc` | S2 style macro usage |
| `react-spectrum-v3-to-s2-migration.mdc` | Migration guide from v3 to S2 |
| `react-spectrum-v3.mdc` | React Spectrum v3 patterns |

### stock-codegen (6 rules)

Adobe Stock development and testing patterns.

| Rule File | Scope |
|-----------|-------|
| `stock-codegen-monorepo-development-patterns.mdc` | Monorepo conventions |
| `stock-codegen-test-coverage-best-practices.mdc` | Coverage requirements |
| `stock-codegen-test-coverage-workflow.mdc` | Coverage workflow |
| `stock-codegen-test-isolation-and-globals.mdc` | Test isolation patterns |
| `stock-codegen-testing-best-practices.mdc` | General testing patterns |
| `stock-codegen-unit-tests.mdc` | Unit test conventions |

## Contributing

Contributions are welcome. The repo uses a domain-based structure:

1. Add `.mdc` rule files under `.cursor/rules/<domain>/`
2. Register your domain in `domains.json`
3. Open a PR with a description of what the rules enforce

Community channels:

- `#ai-secure-coding` - Feedback and security rule discussions
- `#ai-coding-assistant-users` - General AI coding community

## Roadmap

The PASS AIDE team has announced these upcoming additions:

- **MCP server for security guidance** - Adobe-specific security recommendations delivered through Model Context Protocol
- **Cursor extension for auto-updates** - Keep rules current without manual copying
- **DevHome/Flex integration** - Default rule onboarding for Adobe developers

## Relationship to Adobe AI Skills

The security domains in this collection (global, lang, cloud) have counterparts in [Adobe AI Skills](https://github.com/Adobe-AIFoundations/adobe-skills) packaged as SKILL.md files for Claude Code. See the [Adobe Skills](adobe-skills.md#adobe-ai-skills-adobe-aifoundations) page for details on using both together.

## See Also

- [Cursor Configuration](../ai-tools/cursor.md) - Cursor setup including `.mdc` rule format
- [Cursor Rules Setup Example](../../examples/cursor-rules-setup.md) - Bootstrap example with both Cursor and Claude Code
- [Adobe Skills](adobe-skills.md) - AI agent skills including security skills for Claude Code
- [MUST Rules](../../05-guardrails/must-rules.md) - Non-negotiable security and quality rules
- [Cursor Rules documentation](https://docs.cursor.com/context/rules) - Official Cursor docs
