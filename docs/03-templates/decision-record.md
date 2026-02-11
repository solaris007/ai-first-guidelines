# Decision Record Template (ADR)

## Usage

Use this template to document Architecture Decision Records (ADRs) - significant decisions that affect the structure, non-functional characteristics, or direction of a project.

```bash
cp docs/03-templates/decision-record.md docs/decisions/001-use-postgres.md
```

Number sequentially (001, 002, 003...). Remove usage instructions when done.

---

# ADR-[NNN]: [Short Title]

| Field | Value |
|-------|-------|
| **Status** | Proposed / Accepted / Deprecated / Superseded (see note) |
| **Date** | [YYYY-MM-DD] |
| **Author** | [Your Name] |
| **Deciders** | [Names of people involved in decision] |
| **Supersedes** | [ADR-NNN or N/A] |
| **Superseded by** | [ADR-NNN or N/A] |

> **Status values**: ADRs follow the widely-adopted [Michael Nygard ADR format](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) which uses `Proposed / Accepted / Deprecated / Superseded` rather than the repository's general status values.

## Context

[Describe the context and problem statement. What is the issue that we're seeing that motivates this decision?]

### Technical Context

[Technical details relevant to understanding the decision]

### Business Context

[Business drivers or constraints relevant to the decision]

### Constraints

- [Constraint 1: e.g., Must integrate with existing auth system]
- [Constraint 2: e.g., Budget limit of $X/month]
- [Constraint 3: e.g., Team has no Go experience]

## Decision

[State the decision clearly and concisely]

**We will use [DECISION]** because [PRIMARY REASON].

## Rationale

[Explain the reasoning behind the decision]

### Options Considered

**Option A: [Name]**
- Description: [What this option entails]
- Pros:
  - [Pro 1]
  - [Pro 2]
- Cons:
  - [Con 1]
  - [Con 2]

**Option B: [Name]**
- Description: [What this option entails]
- Pros:
  - [Pro 1]
  - [Pro 2]
- Cons:
  - [Con 1]
  - [Con 2]

**Option C: [Name]**
- Description: [What this option entails]
- Pros:
  - [Pro 1]
  - [Pro 2]
- Cons:
  - [Con 1]
  - [Con 2]

### Why Option [X] Was Chosen

[Explain why the selected option was preferred over alternatives]

### Why Alternatives Were Rejected

- **Option A rejected because**: [Reason]
- **Option B rejected because**: [Reason]

## Consequences

### Positive

- [Positive consequence 1]
- [Positive consequence 2]

### Negative

- [Negative consequence 1 and how we'll manage it]
- [Negative consequence 2 and how we'll manage it]

### Neutral

- [Neutral consequence - neither good nor bad, just different]

## Implementation

### Next Steps

1. [Immediate action 1]
2. [Immediate action 2]

### Migration Path (if applicable)

[How to migrate from current state to decided state]

### Timeline

- [Date]: [Milestone 1]
- [Date]: [Milestone 2]

## Validation

[How will we know if this decision was correct?]

### Success Metrics

- [Metric 1: What we'll measure]
- [Metric 2: What we'll measure]

### Review Date

[When should this decision be reviewed? e.g., 6 months, 1 year]

## Related Decisions

- [ADR-NNN: Related decision 1]
- [ADR-NNN: Related decision 2]

## References

- [Link to relevant documentation]
- [Link to research or analysis]
- [Link to related discussions]

---

## Notes

[Any additional context, discussion notes, or clarifications that don't fit above]

---

## Example: Completed ADR

Below is an example of a completed ADR for reference.

---

# ADR-001: Use PostgreSQL for Primary Database

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2024-01-15 |
| **Author** | Jane Smith |
| **Deciders** | Jane Smith, Bob Johnson, Alice Chen |
| **Supersedes** | N/A |
| **Superseded by** | N/A |

## Context

We need to select a primary database for our new application. The application will handle transactional data for approximately 10,000 users with expected growth to 100,000 users over 3 years. We require ACID compliance, good JSON support, and the ability to run complex analytical queries.

### Technical Context

- Current infrastructure is on AWS
- Team has experience with both MySQL and PostgreSQL
- Application uses Django ORM

### Business Context

- 3-year runway before potential database migration would be considered
- No dedicated DBA; operations handled by development team

### Constraints

- Must be a managed service (no self-hosting)
- Budget: approximately $500/month for database costs
- Must have good Django ORM support

## Decision

**We will use PostgreSQL on AWS RDS** because it provides the best combination of JSON support, analytical query performance, and team familiarity.

## Rationale

### Options Considered

**Option A: PostgreSQL on RDS**
- Description: Managed PostgreSQL on AWS RDS
- Pros:
  - Excellent JSON support with JSONB
  - Better analytical query performance than MySQL
  - Team has production experience
  - Strong Django support
- Cons:
  - Slightly higher cost than MySQL
  - Replication setup more complex

**Option B: MySQL on RDS**
- Description: Managed MySQL on AWS RDS
- Pros:
  - Lower cost
  - Simpler replication
  - Widely used
- Cons:
  - JSON support inferior to PostgreSQL
  - Weaker analytical query performance
  - Team prefers PostgreSQL

**Option C: MongoDB Atlas**
- Description: Managed MongoDB on Atlas
- Pros:
  - Native JSON document store
  - Flexible schema
- Cons:
  - Multi-document ACID transactions only since 4.0 (2018), less mature than PostgreSQL
  - Team has no MongoDB experience
  - Django ORM support requires third-party library

### Why PostgreSQL Was Chosen

PostgreSQL offers the best fit for our requirements: strong ACID compliance, excellent JSON support for flexible data structures, and superior analytical query capabilities. The team has production experience, reducing ramp-up time.

### Why Alternatives Were Rejected

- **MySQL rejected because**: JSON support is significantly weaker, and analytical query performance doesn't meet our needs.
- **MongoDB rejected because**: Team lacks experience, and ACID compliance concerns don't align with our transactional requirements.

## Consequences

### Positive

- Excellent developer experience with Django
- Future-proof JSON capabilities
- Good performance for both transactional and analytical workloads

### Negative

- Slightly higher infrastructure cost (~$50/month more than MySQL)
- Will need to invest in learning PostgreSQL-specific features

### Neutral

- Standard SQL; if we ever need to migrate, it's feasible

## Implementation

### Next Steps

1. Provision RDS PostgreSQL instance in staging
2. Set up automated backups and monitoring
3. Create database schemas per application spec

### Timeline

- 2024-01-20: Staging instance provisioned
- 2024-01-25: Production instance provisioned
- 2024-02-01: Application connected and tested

## Validation

### Success Metrics

- Query latency p95 < 100ms for transactional queries
- Analytical queries complete within 5 seconds
- Zero unplanned downtime in first 6 months

### Review Date

2024-07-15 (6 months after implementation)

## References

- [PostgreSQL vs MySQL comparison](internal-wiki-link)
- [AWS RDS pricing calculator](aws-link)
