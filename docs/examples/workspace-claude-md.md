# Example: Workspace CLAUDE.md

This is an example of a workspace-level CLAUDE.md that provides shared context and rules across multiple projects.

---

# Acme Platform Workspace

This workspace contains the Acme Platform - a full-stack e-commerce application with microservices architecture.

## Projects

| Project | Description | Tech Stack |
|---------|-------------|------------|
| `api-gateway/` | API Gateway service | Node.js, Express, TypeScript |
| `user-service/` | User management microservice | Python, FastAPI, PostgreSQL |
| `product-service/` | Product catalog service | Go, gRPC, MongoDB |
| `order-service/` | Order processing service | Python, FastAPI, PostgreSQL |
| `web-app/` | Customer-facing web application | React, TypeScript, Vite |
| `admin-app/` | Internal admin dashboard | React, TypeScript, Vite |
| `infrastructure/` | Terraform and Kubernetes configs | Terraform, Helm |
| `docs/` | Specifications and documentation | Markdown |

## Workspace Rules

### MUST

- **MUST NOT** commit secrets to any repository
- **MUST** run tests before committing
- **MUST** create PRs for all changes (no direct commits to main)
- **MUST** wait for CI to pass before merging
- **MUST** update API documentation when endpoints change
- **MUST** update specs when implementation diverges

### SHOULD

- **SHOULD** follow conventional commits format
- **SHOULD** keep PRs under 400 lines changed
- **SHOULD** include ticket reference in branch name
- **SHOULD** respond to PR reviews within 1 business day

## Cross-Project Coordination

### API Changes

When modifying APIs:
1. Update the spec in `docs/specs/api/`
2. Modify the producing service
3. Update the API Gateway if needed
4. Update all consuming services
5. Update client SDKs if applicable

### Database Migrations

All database changes:
1. Create migration in the owning service
2. Test migration on staging database
3. Have DBA review production migrations
4. Schedule deployment during low-traffic window

### Shared Types

TypeScript types shared between services:
- Location: `packages/shared-types/`
- Update version when making changes
- All services must update to same version

## Environment Setup

### Prerequisites

- Node.js 20+
- Python 3.11+
- Go 1.21+
- Docker and Docker Compose
- Terraform 1.6+
- kubectl configured for staging cluster

### Local Development

```bash
# Start all services locally
docker-compose up -d

# Or start specific services
docker-compose up -d postgres redis
cd user-service && make run
cd web-app && pnpm dev
```

### Environment Variables

Required variables (set in shell profile):
- `ACME_ENV` - Environment (local/staging/production)
- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection string
- `AWS_PROFILE` - AWS profile for local development

## Working Context

### Defaults

Tell AI your typical working context so it doesn't ask every time.

| System | Default | Override with |
|--------|---------|---------------|
| Jira | ACME project | "in PLATFORM" |
| GitHub | acme/platform | "-R acme/infrastructure" |
| AWS | staging account | "in prod" |
| Database | staging environment | "query prod" |
| Slack | #platform-dev channel | "in #platform-alerts" |

### Quick Reference

| Task | Command |
|------|---------|
| Run all tests | `make test-all` |
| Run service tests | `cd <service> && pytest` or `npm test` or `go test ./...` |
| Start local env | `docker-compose up -d` |
| Deploy to staging | `cd infrastructure && make deploy-staging` |
| Run migrations | `cd <service> && alembic upgrade head` |
| Create migration | `cd <service> && alembic revision --autogenerate -m "desc"` |

### Active Work

Current focus areas (update as priorities shift).

- Epic: ACME-500 (Payment system overhaul)
- Focus area: order-service refactoring
- Environment: staging for integration testing
- Branch: feature/payment-v2

## External Dependencies

### Third-Party Services

- **Auth0** - Authentication (config in each service)
- **Stripe** - Payments (user-service, order-service)
- **SendGrid** - Transactional emails
- **Datadog** - Monitoring and logging
- **AWS** - Infrastructure (S3, SQS, RDS, ECS)

### Internal Services

- **Acme Identity** - SSO for admin users
- **Acme Metrics** - Business intelligence data

## Monitoring

### Dashboards

- [Production Dashboard](https://datadog.example.com/prod)
- [Staging Dashboard](https://datadog.example.com/staging)
- [CI/CD Pipeline](https://github.example.com/acme/platform/actions)

### Alerts

Critical alerts go to #platform-alerts Slack channel.
- P1: Page on-call immediately
- P2: Respond within 1 hour
- P3: Address next business day

## Team Contacts

- **Platform Lead**: @alice
- **Backend Team**: @backend-team
- **Frontend Team**: @frontend-team
- **DevOps**: @devops-team
- **On-Call Schedule**: [PagerDuty](https://pagerduty.example.com)

## Documentation

- [Architecture Overview](docs/architecture/overview.md)
- [API Reference](docs/api/README.md)
- [Runbooks](docs/runbooks/README.md)
- [ADRs](docs/decisions/README.md)

---

*This CLAUDE.md lives at the workspace root. Each project has its own CLAUDE.md for project-specific rules.*
