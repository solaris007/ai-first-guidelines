# Migration Plan Template

## Usage

Copy this template when planning a migration between systems, databases, or architectures:

```bash
cp docs/03-templates/migration.md docs/specs/migration-to-postgres.md
```

Fill in all sections. Remove the usage instructions when done.

---

# Migration: [Source] to [Target]

| Field | Value |
|-------|-------|
| **Status** | Draft / Review / Decided / In Progress / Completed / Aborted (see note) |
| **Author** | [Your Name] |
| **Created** | [YYYY-MM-DD] |
| **Migration Start** | [YYYY-MM-DD or TBD] |
| **Migration Complete** | [YYYY-MM-DD or TBD] |
| **Jira Epic** | [PROJ-123 or N/A] |

> **Status values**: Migration plans use extended status values beyond the standard `Draft / Review / Decided / Implemented / Superseded` because migrations have distinct execution phases. `In Progress` = actively migrating, `Completed` = migration finished, `Aborted` = migration cancelled.

## Summary

[2-3 sentence summary. What is being migrated, from where to where, and why?]

## Current State

### System Overview

[Describe the current system being migrated away from]

- **Technology**: [e.g., MySQL 5.7]
- **Location**: [e.g., AWS RDS us-east-1]
- **Data Volume**: [e.g., 500GB, 10M records]
- **Traffic**: [e.g., 1000 QPS peak]

### Pain Points

- [Why is migration necessary?]
- [What problems does the current system have?]

### Dependencies

[What systems/services depend on the current system?]

- [Service A]: [Read/Write, frequency]
- [Service B]: [Read/Write, frequency]

## Target State

### System Overview

[Describe the target system]

- **Technology**: [e.g., PostgreSQL 15]
- **Location**: [e.g., AWS RDS us-west-2]
- **Capacity**: [Planned capacity]

### Benefits

- [Benefit 1 of target system]
- [Benefit 2 of target system]

### Changes Required

[What needs to change in dependent systems?]

- [Service A]: [Required changes]
- [Service B]: [Required changes]

## Migration Strategy

### Approach

[Choose and describe the migration approach]

**Options**:
- **Big Bang**: Migrate everything at once during downtime window
- **Parallel Run**: Run both systems, compare results, cut over
- **Gradual Migration**: Migrate incrementally (by table, by customer, etc.)
- **Strangler Fig**: New traffic to new system, old data migrated over time

**Selected Approach**: [Which approach and why]

### Data Migration

[How will data be moved?]

1. **Initial Sync**: [How initial data will be migrated]
2. **Incremental Sync**: [How changes during migration will be handled]
3. **Validation**: [How data integrity will be verified]

### Traffic Migration

[How will traffic be shifted?]

1. **Read Traffic**: [Strategy for migrating reads]
2. **Write Traffic**: [Strategy for migrating writes]
3. **Cut-over**: [Final switchover plan]

## Migration Phases

### Phase 0: Preparation

- [ ] Provision target infrastructure
- [ ] Set up monitoring and alerting
- [ ] Create runbooks for migration and rollback
- [ ] Train team on new system

**Completion Criteria**: [How to know this phase is done]

### Phase 1: Initial Data Migration

- [ ] Migrate schema
- [ ] Migrate historical data
- [ ] Validate data integrity

**Completion Criteria**: [How to know this phase is done]

### Phase 2: Incremental Sync

- [ ] Enable change data capture
- [ ] Start continuous replication
- [ ] Monitor replication lag

**Completion Criteria**: [How to know this phase is done]

### Phase 3: Read Traffic Migration

- [ ] Point read traffic to new system
- [ ] Monitor performance and errors
- [ ] Compare results with old system (if parallel)

**Completion Criteria**: [How to know this phase is done]

### Phase 4: Write Traffic Migration

- [ ] Point write traffic to new system
- [ ] Stop replication from old system
- [ ] Verify all traffic on new system

**Completion Criteria**: [How to know this phase is done]

### Phase 5: Decommission

- [ ] Remove references to old system
- [ ] Archive old system data
- [ ] Decommission old infrastructure

**Completion Criteria**: [How to know this phase is done]

## Rollback Plan

### Triggers

[When should rollback be initiated?]

- [Trigger 1: e.g., Error rate > 1%]
- [Trigger 2: e.g., Latency p99 > 500ms]
- [Trigger 3: e.g., Data corruption detected]

### Rollback Procedure

[Step-by-step rollback instructions]

**Phase 1-2 Rollback** (Before traffic migration):
1. [Step 1]
2. [Step 2]

**Phase 3 Rollback** (Read traffic migrated):
1. [Step 1]
2. [Step 2]

**Phase 4 Rollback** (Write traffic migrated):
1. [Step 1]
2. [Step 2]

### Point of No Return

[At what point is rollback no longer feasible?]

[Describe the point of no return and what safeguards exist]

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Data loss during migration | Low | Critical | Backup before each phase, validate checksums |
| Performance degradation | Medium | High | Load test target system, gradual traffic shift |
| Extended downtime | Low | High | Detailed runbook, practice runs |
| Application incompatibility | Medium | Medium | Thorough testing in staging |

## Success Criteria

### Migration Success

- [ ] All data migrated with 100% integrity
- [ ] All traffic flowing to new system
- [ ] No rollback required
- [ ] Old system decommissioned

### Performance Criteria

- [ ] Latency <= [target, e.g., current latency]
- [ ] Throughput >= [target, e.g., current throughput]
- [ ] Error rate <= [target, e.g., 0.1%]

### Business Criteria

- [ ] No customer-facing downtime (or within window)
- [ ] No data loss
- [ ] All dependent systems functioning

## Communication Plan

### Stakeholders

| Stakeholder | Communication | Timing |
|-------------|---------------|--------|
| [Team/Person] | [Email/Slack/Meeting] | [When] |
| [Customers] | [Status page/Email] | [When] |

### Migration Updates

[How will progress be communicated during migration?]

## Timeline

| Milestone | Target Date | Actual Date |
|-----------|-------------|-------------|
| Phase 0 Complete | [Date] | |
| Phase 1 Complete | [Date] | |
| Phase 2 Complete | [Date] | |
| Phase 3 Complete | [Date] | |
| Phase 4 Complete | [Date] | |
| Phase 5 Complete | [Date] | |

## Open Questions

- [ ] [Question 1 that needs resolution]
- [ ] [Question 2 that needs resolution]

---

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| [YYYY-MM-DD] | [Name] | Initial draft |

---

# Example: DynamoDB to PostgreSQL Migration

| Field | Value |
|-------|-------|
| **Status** | Completed |
| **Author** | John Doe |
| **Created** | 2025-01-15 |
| **Migration Start** | 2025-02-01 |
| **Migration Complete** | 2025-03-12 |
| **Jira Epic** | SITES-3950 |

## Executive Summary

Migrate the site metadata store from DynamoDB to PostgreSQL (Aurora) to support complex queries, reduce costs, and simplify the data model. DynamoDB's single-table design has become a bottleneck for reporting and cross-entity queries.

## Current State

- 12 entity types packed into a single DynamoDB table using composite keys
- Cross-entity queries require full table scans or secondary indexes
- Monthly DynamoDB cost: ~$2,400 (growing with read capacity)
- No support for ad-hoc SQL queries from analytics team

## Target State

- Normalized PostgreSQL schema with proper foreign keys
- Complex queries via standard SQL
- Estimated monthly cost: ~$800 (Aurora Serverless v2)
- Direct SQL access for analytics via read replica

## Migration Strategy

**Approach**: Parallel Run - both systems active during transition

**Why**: Zero-downtime requirement. DynamoDB remains the source of truth until PostgreSQL is verified. Application reads from both, writes to both, with PostgreSQL promoted after validation.

## Phases

**Phase 0: Preparation** (1 week)
- Schema design and review
- Migration scripts for historical data
- Dual-write adapter layer

**Phase 1: Shadow Write** (2 weeks)
- Deploy dual-write: DynamoDB (primary) + PostgreSQL (shadow)
- Backfill historical data (2.3M records)
- Verify data consistency nightly

**Phase 2: Shadow Read** (1 week)
- Read from both, compare results
- Log discrepancies without affecting users
- Fix any consistency issues found

**Phase 3: Cutover** (1 day)
- Switch primary reads to PostgreSQL
- DynamoDB becomes shadow (fallback)
- Monitor error rates and latency

**Phase 4: Cleanup** (1 week)
- Remove dual-write code
- Decommission DynamoDB table
- Update documentation and runbooks

## Rollback Plan

- **Phase 0-2**: Remove dual-write code, PostgreSQL tables are disposable
- **Phase 3**: Switch reads back to DynamoDB (< 5 min via feature flag)
- **Phase 4**: Point of no return - DynamoDB data no longer current

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Data loss during backfill | Low | High | Checksums on every batch, retry with idempotency |
| Latency regression from PostgreSQL | Medium | Medium | Load test with production traffic patterns |
| Schema design misses edge cases | Medium | High | Run shadow reads for 1 week minimum before cutover |

## Outcome

Migration completed on schedule. PostgreSQL latency was 15% faster than DynamoDB for common queries. Monthly cost reduced from $2,400 to $780. Analytics team now runs queries directly against read replica.
