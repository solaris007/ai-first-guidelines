# Phase 3: Implementation

## Purpose

The Implementation phase executes the plan created in Phase 2. This phase focuses on writing code efficiently with AI assistance while following established patterns and maintaining code quality.

## Workflow

### 1. Create Feature Branch

```bash
# Start from up-to-date main
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/PROJ-123-dashboard
```

**Branch Naming Convention**:
- `feature/JIRA-123-brief-description` - New features
- `fix/JIRA-456-brief-description` - Bug fixes
- `chore/JIRA-789-brief-description` - Maintenance tasks

### 2. Follow the Plan

Work through the implementation plan systematically:

```markdown
### Phase 1: Backend API ✅
- [x] Create service class
- [x] Add API endpoint
- [x] Write unit tests

### Phase 2: Frontend ⏳
- [x] Add API client method
- [ ] Create Dashboard component  ← Currently working
- [ ] Add routing

### Phase 3: Infrastructure
- [ ] CloudWatch dashboard
- [ ] Alerts
```

### 3. Commit Incrementally

Make small, focused commits:

```bash
# Good: Small, focused commits
git commit -m "Add dashboard service with data aggregation"
git commit -m "Add GET /api/dashboard endpoint"
git commit -m "Add unit tests for dashboard endpoint"

# Bad: Large, unfocused commits
git commit -m "Add dashboard feature"  # Too broad
```

**Commit Message Format** (Conventional Commits):
```
type(scope): brief description

[optional body with more detail]

[optional footer with ticket reference]
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

### 4. Push Regularly

Push to remote frequently to:
- Trigger CI/CD pipeline
- Create backup of work
- Enable collaboration

```bash
git push origin feature/PROJ-123-dashboard
```

### 5. Create Pull Request

When ready for review:

```bash
# Using GitHub CLI
gh pr create --title "feat: Add unified dashboard" \
  --body "## Summary
- Adds dashboard API endpoint
- Creates Dashboard component
- Integrates with monitoring

## Test Plan
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing on staging

Closes PROJ-123"
```

## AI-Assisted Implementation

### Effective Prompting

**Provide Context**:
```
Following the plan, I'm implementing Phase 1: Backend API.
Create the dashboard service class following the existing pattern
in src/services/user_service.py.
```

**Be Specific About Requirements**:
```
The endpoint should:
- Return aggregated data from GitHub, AWS, and Datadog
- Cache results for 30 seconds
- Handle partial failures gracefully (return available data)
```

**Request Review**:
```
Review this implementation against the spec. Am I missing any
edge cases or requirements?
```

### Code Quality with AI

**Consistent Style**:
- AI follows patterns in your CLAUDE.md
- Reference existing code for style guidance
- Ask AI to match existing patterns

**Avoiding Over-Engineering**:
- Ask AI to implement the simplest solution first
- Only add complexity when justified by requirements
- Question any AI suggestion that seems elaborate

**Security Considerations**:
- Ask AI to review for security issues
- Never commit secrets (see [Environment & Secrets](../04-configuration/env-secrets.md))
- Validate AI-generated code that handles user input

## Cross-Repo Implementation

When implementing across multiple repositories:

### Coordinate Branches

All repos should use matching branch names:
```
backend/    → feature/PROJ-123-dashboard
frontend/   → feature/PROJ-123-dashboard
infra/      → feature/PROJ-123-dashboard
```

### Implement in Dependency Order

1. **Infrastructure first** (if needed)
   - Database migrations
   - New AWS resources
   - Configuration changes

2. **Backend second**
   - API endpoints
   - Service logic
   - Backend tests

3. **Frontend last**
   - UI components
   - API integration
   - Frontend tests

### Handle Inter-Dependencies

If frontend needs backend changes not yet merged:

**Option A**: Point to branch
```typescript
// Temporary: Using feature branch backend
const API_BASE = process.env.FEATURE_API_URL;
```

**Option B**: Mock the API
```typescript
// Mock until backend is ready
const mockDashboardData = { ... };
```

**Option C**: Coordinate merge timing
- Merge backend first
- Wait for deploy
- Then merge frontend

## Handling Blockers

### Technical Blockers

When implementation reveals issues:

1. **Document the blocker** in PR or spec
2. **Assess impact** on plan
3. **Options**:
   - Adjust plan to work around
   - Return to planning phase
   - Escalate to spec revision

### External Dependencies

When waiting on others:

1. **Implement what you can** independently
2. **Create clear interface** at dependency boundary
3. **Document assumption** about expected behavior
4. **Mark status** in TODO.md or PR

## Best Practices

### Do

- **Follow the plan** - The plan exists for a reason
- **Commit often** - Small commits are easier to review/revert
- **Test locally** before pushing
- **Update plan** when scope changes
- **Ask AI questions** when uncertain

### Don't

- **Don't skip tests** - "I'll add them later" often means never
- **Don't gold-plate** - Stick to spec requirements
- **Don't force push** - Make new commits instead
- **Don't ignore CI** - Fix failures before continuing
- **Don't commit secrets** - Ever

## Checklist

Before moving to Validation:

- [ ] All planned changes implemented
- [ ] Code follows existing patterns
- [ ] Unit tests written and passing locally
- [ ] No linting errors
- [ ] No secrets in code
- [ ] Commits are clean and descriptive
- [ ] Pushed to remote branch
- [ ] CI pipeline triggered
- [ ] PR created (or ready to create)

## See Also

- [Validation Phase](04-validation.md)
- [MUST Rules](../05-guardrails/must-rules.md) - Critical rules for implementation
- [Anti-Patterns](../05-guardrails/anti-patterns.md) - Common mistakes to avoid
