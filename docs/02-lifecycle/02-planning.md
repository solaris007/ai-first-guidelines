# Phase 2: Planning

## Purpose

The Planning phase transforms a spec into a concrete implementation plan. This phase uses AI plan mode to identify all changes needed, determine the right sequence, and document dependencies.

## Why Plan Before Coding?

### Problems with Dive-In Approach

- **Incomplete understanding** of scope leads to forgotten changes
- **Wrong sequence** causes conflicts and rework
- **Hidden dependencies** surface mid-implementation
- **Context switching** between exploration and execution

### Benefits of Planning First

- **Complete picture** of all files and changes needed
- **Optimal sequence** considering dependencies
- **Early detection** of blockers or complexity
- **Focused execution** with clear next steps

## AI Plan Mode

### What is Plan Mode?

Claude Code and similar tools offer a "plan mode" where the AI:
- Explores the codebase to understand current state
- Proposes an implementation plan based on your spec
- Identifies files to create/modify/delete
- Suggests implementation sequence
- Highlights potential risks or dependencies

### Entering Plan Mode

In Claude Code, press `shift+tab` to toggle plan mode, or simply ask:
```
Let's plan the implementation for [spec name].
```

The AI will:
1. Ask clarifying questions about the spec
2. Explore relevant parts of the codebase
3. Propose a structured plan
4. Iterate based on your feedback

### Plan Structure

A good plan includes:

```markdown
## Implementation Plan: [Feature Name]

### Overview
Brief summary of what will be implemented.

### Prerequisites
- [ ] Dependencies to install
- [ ] Environment setup needed
- [ ] Access or permissions required

### Phase 1: [Component A]
Files:
- `src/api/endpoint.py` - Create new endpoint
- `src/api/routes.py` - Add route registration

Steps:
1. Create endpoint handler with input validation
2. Add route to main router
3. Write unit tests

### Phase 2: [Component B]
Files:
- `src/frontend/Dashboard.tsx` - New component
- `src/frontend/api.ts` - Add API client method

Steps:
1. Create API client method
2. Build Dashboard component
3. Add to routing

### Phase 3: [Integration]
Files:
- `src/config.py` - Add feature flag
- `tests/integration/` - Integration tests

Steps:
1. Add feature configuration
2. Write integration tests
3. Enable feature

### Dependencies
- Phase 2 depends on Phase 1 (API must exist first)
- Phase 3 depends on both Phase 1 and 2

### Risks
- API rate limits may require caching strategy
- Frontend bundle size increase needs monitoring

### Open Questions
- Should we add metrics for this feature?
- What's the rollback strategy if issues arise?
```

## Multi-Repo Planning

When changes span multiple repositories:

### Identify All Repos

```markdown
### Repository Changes

**backend/** (Python API)
- New endpoint for dashboard data
- Database migration for new table

**frontend/** (React app)
- Dashboard component
- API client updates

**infrastructure/** (Terraform)
- CloudWatch alarms for new endpoint
- IAM permissions for new service
```

### Determine Sequence

Typical order:
1. **Database/Infrastructure** - Foundation must exist first
2. **API/Backend** - Services built on foundation
3. **Frontend** - Consumes backend services
4. **Integration** - Cross-repo verification

### Plan Branching Strategy

```markdown
### Branch Strategy

All repos: Branch from main with name `feature/PROJ-123-dashboard`

Merge order:
1. infrastructure (terraform apply after merge)
2. backend (wait for infra)
3. frontend (wait for backend)
```

## TODO.md Alternative

For simpler tracking, use a TODO.md file:

```markdown
# Implementation: Dashboard Feature

## Backend
- [ ] Create `GET /api/dashboard` endpoint
- [ ] Add caching layer for aggregated data
- [ ] Write unit tests for endpoint
- [ ] Write integration tests

## Frontend
- [ ] Create Dashboard component
- [ ] Add API client method
- [ ] Add to main navigation
- [ ] Write component tests

## Infrastructure
- [ ] Add CloudWatch dashboard
- [ ] Configure alerts

## Integration
- [ ] End-to-end test
- [ ] Performance testing
- [ ] Documentation update
```

See [TODO Template](../03-templates/TODO.md)

## Planning Best Practices

### Be Specific About Files

Instead of:
> "Update the API"

Say:
> "Modify `src/api/routes.py` to add `/dashboard` route"
> "Create `src/api/handlers/dashboard.py` for endpoint logic"

### Include Test Strategy

Every implementation plan should specify:
- What unit tests to write
- What integration tests to add
- How to verify the change works

### Consider Rollback

For significant changes:
- How do we roll back if something goes wrong?
- Are there database migrations that need down scripts?
- Is there a feature flag for gradual rollout?

### Time-Box Planning

Planning has diminishing returns. Guidelines:
- Simple features: 10-15 minutes
- Medium features: 30-60 minutes
- Complex features: 1-2 hours max

If planning takes longer, the spec might need more work.

## Checklist

Before moving to Implementation:

- [ ] All files to modify are identified
- [ ] Implementation sequence is clear
- [ ] Dependencies between changes are mapped
- [ ] Test strategy is defined
- [ ] Risks are identified with mitigations
- [ ] Rollback approach is considered (if applicable)
- [ ] Plan is documented (AI session or TODO.md)

## Example Planning Session

```
User: Let's plan the implementation for the dashboard feature spec.

AI: I'll analyze the codebase and create a plan. Let me start by
understanding the current API structure and frontend patterns.

[AI explores codebase]

Based on my analysis, here's the proposed plan:

## Implementation Plan: Unified Dashboard

### Phase 1: Backend API (backend repo)
Files to modify:
- `src/api/routes/__init__.py` - Add dashboard route
- `src/services/dashboard.py` - New service (create)
- `tests/api/test_dashboard.py` - New tests (create)

The existing pattern uses service classes, so I'll follow that.

### Phase 2: Frontend Component (frontend repo)
Files to modify:
- `src/components/Dashboard/` - New component directory
- `src/api/endpoints.ts` - Add dashboard endpoint
- `src/App.tsx` - Add route

### Phase 3: Infrastructure (infrastructure repo)
Files to modify:
- `terraform/modules/monitoring/dashboards.tf` - CloudWatch dashboard

Does this plan align with your expectations? Any adjustments needed?

User: Looks good. What about the database changes mentioned in the spec?

AI: Good catch. Let me add Phase 0 for database changes:

### Phase 0: Database Migration (backend repo)
Files to create:
- `migrations/versions/20240115_add_dashboard_cache.py`

This should run before Phase 1 since the API will query this table.

Updated dependency order: Phase 0 → Phase 1 → Phase 2 → Phase 3

Ready to start implementation?
```

## See Also

- [Implementation Phase](03-implementation.md)
- [TODO Template](../03-templates/TODO.md)
- [MUST Rules](../05-guardrails/must-rules.md) - Critical rules that apply during planning
