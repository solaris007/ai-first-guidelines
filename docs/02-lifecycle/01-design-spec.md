# Phase 1: Design & Spec

## Purpose

The Design & Spec phase establishes **what** you're building and **why**, before any code is written. This phase leverages AI's strength in exploring problem spaces, evaluating alternatives, and refining requirements through dialogue.

## Why Spec-Driven?

### Problems with Code-First

- **Unclear requirements** lead to rework
- **Missing edge cases** discovered late in implementation
- **No documented rationale** for design decisions
- **Difficult reviews** without context on intent

### Benefits of Spec-First

- **Clarified thinking** before committing to implementation
- **Shared understanding** with AI about goals and constraints
- **Built-in documentation** as natural byproduct
- **Meaningful reviews** against stated intentions

## Workflow

### 1. Create the Spec Document

Start with the [spec template](../03-templates/spec-proposal.md):

```bash
# Copy template to specs directory
cp docs/03-templates/spec-proposal.md docs/specs/my-feature.md
```

Fill in the header with:
- **Title**: Clear, descriptive name
- **Status**: `Draft`
- **Author**: Your name
- **Date**: Creation date

### 2. Define the Problem

This is the most important section. Be specific about:

**Current State**
- What exists today?
- What's working and what isn't?

**Desired State**
- What should exist after implementation?
- How will users/systems benefit?

**Gap Analysis**
- What's preventing us from reaching desired state?
- What specific problems need solving?

**Example**:
```markdown
## Problem Statement

### Current State
Users must manually check three different dashboards to understand
deployment status: GitHub Actions, AWS CloudWatch, and Datadog.
Average time to assess deployment health: 15 minutes.

### Desired State
Single unified view showing deployment pipeline status, with
automated health assessment and clear next-action guidance.

### Gap
No integration exists between these systems. Each dashboard requires
separate authentication and mental context-switching.
```

### 3. Iterate with AI

Use AI to refine your spec through dialogue:

**Clarifying Questions**
> "What edge cases am I missing in this authentication flow?"
> "What happens if the external API is unavailable?"
> "Are there security implications I haven't considered?"

**Alternatives Exploration**
> "What are the tradeoffs between approaches A and B?"
> "How would this design scale to 10x current load?"
> "What would a simpler version of this look like?"

**Technical Validation**
> "Does this API design follow REST conventions?"
> "Are there existing patterns in the codebase I should follow?"
> "What testing strategy would cover these requirements?"

### 4. Document Alternatives

Always include alternatives analysis:

```markdown
## Alternatives Considered

| Approach | Pros | Cons | Verdict |
|----------|------|------|---------|
| Polling API | Simple, reliable | Higher latency, more API calls | Rejected |
| WebSocket | Real-time, efficient | Complex error handling | Rejected |
| Server-Sent Events | Real-time, simpler than WS | One-way only | **Selected** |

### Decision Rationale
SSE provides real-time updates with significantly simpler implementation
than WebSockets. The one-way limitation is acceptable because clients
only need to receive updates, not send them.
```

### 5. Define Success Criteria

Specify how you'll know the implementation is complete:

```markdown
## Success Criteria

### Functional
- [ ] Dashboard displays all three data sources
- [ ] Health status updates within 30 seconds of state change
- [ ] Clear error states when data source unavailable

### Non-Functional
- [ ] Page load time < 2 seconds
- [ ] Handles 100 concurrent users
- [ ] Works in all supported browsers

### Validation
- [ ] Unit tests cover core logic
- [ ] Integration tests verify data source connections
- [ ] Manual QA sign-off on UX
```

### 6. Review with Team

Before marking `Decided`:

1. **Share the spec** via PR or doc link
2. **Request specific feedback** on areas of uncertainty
3. **Address comments** with spec updates
4. **Get explicit approval** from stakeholders

### 7. Mark Status Decided

Once approved, update the spec:

```markdown
---
Status: Decided
Decided: 2024-01-15
Approvers: @alice, @bob
---
```

## Common Spec Types

### Feature Spec

New functionality for end users. Focus on:
- User stories and workflows
- UI/UX considerations
- Integration with existing features

### Technical Spec

Internal improvements or infrastructure. Focus on:
- System architecture
- Performance requirements
- Migration strategy

### Migration Spec

Moving from one system/approach to another. Focus on:
- Current vs. target state
- Migration steps and rollback plan
- Risk mitigation

See [Migration Template](../03-templates/migration.md)

### Decision Record

Architectural decisions with long-term impact. Focus on:
- Context and problem
- Decision and rationale
- Consequences

See [Decision Record Template](../03-templates/decision-record.md)

## AI Collaboration Tips

### Do

- **Ask open questions**: "What am I missing?" not "Is this good?"
- **Request critique**: "What could go wrong with this approach?"
- **Explore alternatives**: "What would you do differently?"
- **Validate assumptions**: "Is it safe to assume X?"

### Don't

- **Rush to implementation**: Resist the urge to start coding
- **Skip alternatives**: Always document what you considered
- **Ignore edge cases**: AI is great at finding these
- **Assume shared context**: Explain your constraints explicitly

## Checklist

Before moving to Planning:

- [ ] Spec document created from template
- [ ] Problem statement is specific and measurable
- [ ] Alternatives are documented with rationale
- [ ] Success criteria are testable
- [ ] Open questions are resolved
- [ ] Team review is complete
- [ ] Status is `Decided`

## See Also

- [Spec Template](../03-templates/spec-proposal.md)
- [Migration Template](../03-templates/migration.md)
- [Decision Record Template](../03-templates/decision-record.md)
- [Planning Phase](02-planning.md)
