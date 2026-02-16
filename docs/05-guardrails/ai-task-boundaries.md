# AI Task Boundaries

## Overview

AI-first development accelerates delivery, but not every task is equally suited to AI delegation. Some tasks benefit from AI speed and consistency. Others carry enough risk that a human must own the decision-making, even if AI assists with the mechanics.

This document provides a framework for classifying tasks. It is not exhaustive - teams should adapt it based on their codebase, risk profile, and regulatory environment.

## AI-Suitable Tasks

These tasks are good candidates for AI ownership or heavy AI assistance. They tend to be mechanical, pattern-driven, or low-blast-radius. Most map to the [Fluid Substrate](../01-foundations/substrate-model.md) - the layer where speed matters more than ceremony.

### Test Generation and Coverage Improvement

- **SHOULD** use AI to generate unit tests for existing code
- **SHOULD** use AI to expand edge-case coverage from existing test suites
- **SHOULD** use AI to generate test data and fixtures

> Tests are validated by running them. A bad AI-generated test fails the suite - it does not silently corrupt production.

### UI and Component Scaffolding

- **SHOULD** use AI to scaffold components that follow established patterns
- **SHOULD** use AI to generate boilerplate for forms, tables, and standard layouts
- **SHOULD** review AI-generated components for accessibility before shipping

> Pattern-following work is where AI is most reliable. The key constraint is that the pattern must already exist and be well-defined.

### Mechanical Refactors

- **SHOULD** use AI for renames, import updates, and file reorganization
- **SHOULD** use AI for migration scripts (framework version bumps, API changes)
- **SHOULD** use AI for dead code removal when coverage tools confirm unreachability

> These changes are high-volume and low-judgment. AI handles them faster and more consistently than humans. Verify with tests and CI.

### State Management and Data Wiring

- **SHOULD** use AI to wire up data fetching, caching, and state management boilerplate
- **SHOULD** use AI to generate API client code from OpenAPI specs or similar contracts

> Boilerplate from a well-defined contract is deterministic. AI excels here.

### Documentation Drafts

- **SHOULD** use AI to draft architecture docs, onboarding guides, and API documentation
- **SHOULD** have a human review AI-generated docs for accuracy and completeness

> AI produces serviceable first drafts quickly. Human review catches hallucinated details and missing context.

### Dev Tooling and Utilities

- **SHOULD** use AI to generate utility functions, scripts, and dev tooling
- **SHOULD** use AI to create linting rules, git hooks, and local automation

> Internal tooling has a contained blast radius. If a dev script breaks, a developer notices immediately.

## Human-Required Tasks

These tasks require human ownership of the decision-making process. AI can assist with mechanics (generating code, suggesting approaches), but a human must understand and approve every line. Most map to the [Durable Substrate](../01-foundations/substrate-model.md) - the layer where failure cascades across the system.

### Business-Critical Logic

- **MUST** have human review and approval for entitlement checks, authorization rules, and data filtering logic
- **MUST** have human review and approval for billing, payment, and financial calculations
- **MUST** have human review and approval for compliance-related code (data residency, consent management)

> A bug in entitlement logic gives unauthorized access. A bug in billing logic costs real money. These are not recoverable with a rollback.

### Security and Privacy Code Paths

- **MUST** have human ownership of authentication flows and session management
- **MUST** have human ownership of token handling, encryption, and key management
- **MUST** have human ownership of PII handling, data masking, and anonymization

> Security code requires threat modeling, not just functional correctness. AI does not reason about adversarial actors the way a security-trained engineer does.

### Dependency and Build Configuration

- **MUST** have human review for changes to package manifests (package.json, pom.xml, requirements.txt)
- **MUST** have human review for build tool configuration (webpack, vite, tsconfig, babel)
- **SHOULD** have human review for lockfile changes that update transitive dependencies

> Dependency changes affect the entire project. A bad dependency introduces supply-chain risk. A misconfigured build produces subtly wrong output.

### Large Cross-Cutting Refactors

- **MUST NOT** delegate multi-feature refactors to AI as a single change
- **SHOULD** break cross-cutting changes into small, reviewable increments
- **SHOULD** have AI handle individual increments under human coordination

> AI works well on bounded tasks. A refactor that touches authentication, data access, and the UI simultaneously exceeds what any single review can validate.

### CI/CD Pipeline Configuration

- **MUST** have human review for CI/CD pipeline changes
- **MUST** have human review for deployment configuration, environment variables, and infrastructure-as-code
- **MUST NOT** let AI autonomously modify production deployment pipelines

> CI/CD pipelines are the gate between code and production. A misconfiguration here bypasses every other safeguard.

## Mapping to the Substrate Model

The boundary between AI-suitable and human-required tasks aligns with the [Durable vs Fluid Substrate](../01-foundations/substrate-model.md) model:

| Substrate Layer | AI Role | Human Role |
|-----------------|---------|------------|
| **Fluid** (features, integrations, experiments) | Primary producer - AI generates, iterates, and ships with light review | Reviewer, direction-setter, quality gate |
| **Durable** (auth, data, infrastructure, security) | Assistant - AI generates suggestions and drafts | Owner - human understands, validates, and approves every change |

The fluid layer is designed to tolerate controlled failure. AI-generated code that breaks a feature experiment is caught by monitoring and rolled back. The durable layer is not designed for controlled failure. AI-generated code that breaks authentication takes down the platform.

**The practical test:** If a bug in this code would wake someone up at 2 AM, a human must own it. If a bug would show up in a sprint review and get fixed next iteration, AI can drive.

## Customizing for Your Team

This framework is a starting point. To adapt it:

1. **Audit your codebase** - Identify which modules are durable (high blast radius, infrequent change) and which are fluid (high velocity, contained failure)
2. **Label explicitly** - Add comments or CLAUDE.md rules marking sensitive paths: `# DURABLE: Human review required for changes`
3. **Automate enforcement** - Use CODEOWNERS to require specific reviewers for durable paths
4. **Review quarterly** - As AI capabilities improve and your platform matures, boundaries will shift

---

*This framework is adapted from the ASO UI team's AI-first task classification (Abhinav Saraswat, OneAdobe/experience-success-studio-ui).*

## See Also

- [Durable vs Fluid Substrate](../01-foundations/substrate-model.md) - The architectural model behind these boundaries
- [MUST Rules](must-rules.md) - Non-negotiable requirements for all work
- [SHOULD Rules](should-rules.md) - Strong recommendations with valid exceptions
- [Anti-Patterns](anti-patterns.md) - Common mistakes in AI-first development
