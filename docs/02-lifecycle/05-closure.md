# Phase 5: Closure

## Purpose

The Closure phase completes the work by updating all artifacts, closing tickets, and merging code. This phase ensures nothing is forgotten and the implementation is properly documented.

## Closure Activities

### 1. Update Documentation

Documentation updates are **mandatory**, not optional.

**README.md**

If behavior changed for users:
```markdown
## Dashboard (New!)

Access the unified dashboard at `/dashboard` to see:
- GitHub Actions status
- AWS CloudWatch metrics
- Datadog alerts

Configuration options in `config/dashboard.yaml`.
```

**Spec Status**

Update the spec document:
```markdown
---
Status: Implemented
Implemented: 2024-01-20
PR: https://github.com/org/repo/pull/123
---
```

**CLAUDE.md**

If new patterns were established:
```markdown
## Dashboard Module

The dashboard feature uses the aggregation pattern:
- Services in `src/services/` aggregate from external APIs
- Caching layer in `src/cache/` with 30-second TTL
- Frontend components in `src/components/Dashboard/`
```

### 2. Close Jira Tickets (if applicable)

**Update Ticket Status**:
```
Status: Done
Resolution: Fixed
```

**Add PR Link**:
Link the PR to the Jira ticket for traceability.

**Add Implementation Notes** (optional):
Brief summary of what was implemented and any caveats.

### 3. Merge Pull Request

**Pre-Merge Checklist**:
- [ ] All CI checks pass
- [ ] All required reviews approved
- [ ] No unresolved comments
- [ ] Branch is up-to-date with main

**Merge Strategy**:

| Strategy | When to Use |
|----------|-------------|
| Squash merge | Feature branches with messy history |
| Merge commit | Clean history, want to preserve commits |
| Rebase | Linear history preference |

```bash
# Using GitHub CLI
gh pr merge --squash --delete-branch

# Or via GitHub UI
```

### 4. Clean Up

**Delete Feature Branch**:
```bash
# If not auto-deleted
git push origin --delete feature/PROJ-123-dashboard
git branch -d feature/PROJ-123-dashboard
```

**Remove Temporary Files**:
- Test fixtures created during development
- Mock configurations
- Debug logging

**Close Related Issues**:
If multiple issues were addressed, ensure all are closed.

### 5. Notify Stakeholders (if appropriate)

For significant changes:
- Post in team Slack channel
- Update project status dashboard
- Notify dependent teams

## Documentation Checklist

### Always Update

- [ ] README.md (if user-facing behavior changed)
- [ ] Spec status (mark as `Implemented`)
- [ ] Inline code comments (for complex logic)

### Update If Relevant

- [ ] CLAUDE.md (new patterns or conventions)
- [ ] API documentation (new/changed endpoints)
- [ ] Configuration docs (new options)
- [ ] Architecture diagrams (structural changes)
- [ ] Runbooks (operational procedures)

### Consider Creating

- [ ] Migration guide (breaking changes)
- [ ] Troubleshooting section (known issues)
- [ ] Decision record (significant choices made during implementation)

## Jira Workflow (Optional)

Jira integration is optional. You can use TODO.md as the primary task tracker.

### If Using Jira

**Minimum Updates**:
1. Change status to Done
2. Add PR link
3. Verify fix version (if applicable)

**Enhanced Updates**:
```markdown
## Implementation Summary
- Added dashboard API at /api/dashboard
- Created Dashboard component with 30s auto-refresh
- Added CloudWatch integration for metrics

## Test Coverage
- Unit tests: 85% coverage
- Integration tests: Key flows covered
- Manual testing: Completed on staging

## Deployment Notes
- Feature flag: ENABLE_DASHBOARD
- Rollback: Toggle flag off
```

### If Using TODO.md

```markdown
# Implementation: Dashboard Feature

## Completed ✅
- [x] Create GET /api/dashboard endpoint
- [x] Add caching layer
- [x] Create Dashboard component
- [x] Add navigation link
- [x] Write tests
- [x] Deploy to staging
- [x] Merge PR

## Notes
- PR: https://github.com/org/repo/pull/123
- Deployed: 2024-01-20
- Feature flag: ENABLE_DASHBOARD
```

## Post-Merge Verification

### Verify Production Deploy

If auto-deployed to production:
```bash
# Check deployment status
kubectl get deployments -n production

# Verify service health
curl https://api.example.com/health

# Check logs for errors
kubectl logs -n production -l app=api --tail=100
```

### Monitor for Issues

First 24-48 hours after deploy:
- Watch error rates in monitoring
- Check for user-reported issues
- Monitor performance metrics
- Review logs for unexpected patterns

### Rollback if Needed

If issues arise:
```bash
# Revert the PR
gh pr create --title "Revert: Add dashboard feature" \
  --body "Reverting due to [issue description]"

# Or use feature flag
ENABLE_DASHBOARD=false

# Or rollback deployment
kubectl rollout undo deployment/api -n production
```

## Closure Checklist

Before considering work complete:

### Documentation
- [ ] README.md updated (if applicable)
- [ ] Spec status changed to `Implemented`
- [ ] CLAUDE.md updated (if new patterns)
- [ ] API docs updated (if applicable)

### Git/GitHub
- [ ] PR merged
- [ ] Feature branch deleted
- [ ] All related issues closed

### Jira (if applicable)
- [ ] Ticket status updated to Done
- [ ] PR linked to ticket
- [ ] Fix version set

### Verification
- [ ] Production deploy verified (if auto-deploy)
- [ ] No errors in production logs
- [ ] Monitoring shows healthy metrics

## See Also

- [Lifecycle Overview](overview.md) - Return to phase overview
- [Spec Template](../03-templates/spec-proposal.md) - Updating spec status
- [TODO Template](../03-templates/TODO.md) - Completing TODO items
