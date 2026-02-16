# Component Contract Template

## Usage

Copy this template to define a precise contract for a component, module, or feature - detailed enough for an AI (or a teammate) to implement without ambiguity:

```bash
cp docs/03-templates/contract.md docs/specs/auth-middleware-contract.md
```

**When to use this vs. a spec proposal:** Specs are project-level ("what to build and why"). Contracts are component-level ("what this component does, precisely"). Write a spec first to decide what to build, then write contracts for the pieces.

Fill in all sections. Remove the usage instructions when done.

---

# Contract: [Component/Module Name]

| Field | Value |
|-------|-------|
| **Status** | Draft / Review / Decided / Implemented / Superseded |
| **Author** | [Your Name] |
| **Created** | [YYYY-MM-DD] |
| **Updated** | [YYYY-MM-DD] |
| **Parent Spec** | [Link to spec or N/A] |
| **Jira** | [PROJ-123 or N/A] |

## Intent

[1-3 sentences describing what this component does and why it exists. This is the "elevator pitch" for the component.]

## Inputs

[Define every input the component accepts. Be explicit about types, formats, and constraints.]

| Input | Type | Required | Description | Constraints |
|-------|------|----------|-------------|-------------|
| [name] | [type] | Yes/No | [What it is] | [Validation rules, ranges, formats] |
| [name] | [type] | Yes/No | [What it is] | [Validation rules, ranges, formats] |

## Outputs

[Define every output the component produces - return values, events emitted, side effects.]

| Output | Type | Description | When |
|--------|------|-------------|------|
| [name] | [type] | [What it contains] | [Under what conditions] |
| [name] | [type] | [What it contains] | [Under what conditions] |

### Side Effects

[List any side effects - database writes, API calls, file system changes, cache mutations, events emitted.]

- [Side effect 1]: [When it happens and what it does]
- [Side effect 2]: [When it happens and what it does]
- None (if the component is pure)

## Pre-conditions

[What must be true before this component is called? If any pre-condition is violated, the component should fail fast rather than produce incorrect results.]

- [ ] [Pre-condition 1: e.g., User must be authenticated]
- [ ] [Pre-condition 2: e.g., Database connection must be available]
- [ ] [Pre-condition 3: e.g., Input X must have been validated by caller]

## Post-conditions

[What is guaranteed to be true after successful execution? These are the promises this component makes to its callers.]

- [ ] [Post-condition 1: e.g., Record exists in database with status "active"]
- [ ] [Post-condition 2: e.g., Return value contains a valid ID]
- [ ] [Post-condition 3: e.g., Audit event has been emitted]

## Invariants

[Conditions that must remain true throughout the component's lifetime - not just before/after, but always.]

- [Invariant 1: e.g., Total of all line items always equals the order total]
- [Invariant 2: e.g., Deleted records are never returned in query results]
- None (if no invariants apply)

## Error Handling

[How does this component handle failures? Be specific about error types and recovery behavior.]

| Error Condition | Behavior | Caller Receives |
|----------------|----------|-----------------|
| [Condition 1: e.g., Record not found] | [What happens] | [Error type/code/message] |
| [Condition 2: e.g., Upstream service timeout] | [What happens] | [Error type/code/message] |
| [Condition 3: e.g., Invalid input after validation] | [What happens] | [Error type/code/message] |

### Retry Behavior

[Is this component safe to retry? Under what conditions?]

- **Idempotent**: Yes / No / Conditional (explain)
- **Safe to retry**: Yes / No / Only for [specific errors]

## Non-goals

[What this component explicitly does NOT do. This prevents scope creep during implementation.]

- [Non-goal 1: e.g., Does not handle authentication - caller must authenticate first]
- [Non-goal 2: e.g., Does not send notifications - a separate component handles that]
- [Non-goal 3: e.g., Does not support batch operations in v1]

## Dependencies and Assumptions

[External systems, services, or state this component depends on.]

| Dependency | Type | Assumption |
|------------|------|------------|
| [System/service] | Runtime / Build / Optional | [What we assume about it: availability, version, behavior] |
| [System/service] | Runtime / Build / Optional | [What we assume about it] |

### Environmental Assumptions

- [Assumption 1: e.g., Running in Node.js 20+]
- [Assumption 2: e.g., DATABASE_URL environment variable is set]
- [Assumption 3: e.g., Network access to internal API gateway]

## Test Scenarios

[Key scenarios that should be covered by tests. Write these as behavior descriptions, not test implementation details.]

### Happy Path

- [ ] [Scenario 1: e.g., Valid input produces expected output]
- [ ] [Scenario 2: e.g., All side effects execute in correct order]

### Edge Cases

- [ ] [Scenario 1: e.g., Empty input collection]
- [ ] [Scenario 2: e.g., Maximum allowed input size]
- [ ] [Scenario 3: e.g., Concurrent calls with same input]

### Error Cases

- [ ] [Scenario 1: e.g., Upstream service unavailable]
- [ ] [Scenario 2: e.g., Pre-condition violated]
- [ ] [Scenario 3: e.g., Partial failure during side effects]

## Contract Lifecycle

This contract describes the intended behavior at time of writing. After implementation:

- **Keep in sync**: If the implementation diverges from this contract, update the contract or fix the implementation - do not let them drift apart.
- **Supersede, don't delete**: If this component is replaced, set status to `Superseded` and link to the replacement. This preserves the decision history.
- **Tests are the living contract**: Once implemented, the test suite becomes the authoritative contract. This document remains useful for onboarding and design review.

---

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| [YYYY-MM-DD] | [Name] | Initial draft |
| [YYYY-MM-DD] | [Name] | [Description of changes] |

---

*Inspired by the Tests-First Development + Design by Contract workflow in OneAdobe/experience-success-studio-ui (Abhinav Saraswat).*

---

# Example: Rate Limiter Middleware

# Contract: Rate Limiter Middleware

| Field | Value |
|-------|-------|
| **Status** | Decided |
| **Author** | Alex Chen |
| **Created** | 2025-04-01 |
| **Updated** | 2025-04-08 |
| **Parent Spec** | docs/specs/api-gateway-v2.md |
| **Jira** | SITES-5102 |

## Intent

Middleware that enforces per-client request rate limits on API endpoints. Protects backend services from traffic spikes and ensures fair usage across clients. Sits between the router and route handlers.

## Inputs

| Input | Type | Required | Description | Constraints |
|-------|------|----------|-------------|-------------|
| request | HTTP Request | Yes | Incoming HTTP request object | Must include headers and client IP |
| config.maxRequests | number | Yes | Maximum requests allowed in the window | Positive integer, minimum 1 |
| config.windowMs | number | Yes | Time window in milliseconds | Positive integer, minimum 1000 |
| config.keyFn | function | No | Custom function to extract client identifier | Defaults to client IP extraction |

## Outputs

| Output | Type | Description | When |
|--------|------|-------------|------|
| next() | void | Passes control to next middleware | Request is within rate limit |
| 429 Response | HTTP Response | Too Many Requests with Retry-After header | Rate limit exceeded |

### Side Effects

- **Counter increment**: Increments the request count for the client key in the backing store (Redis or in-memory Map)
- **Header injection**: Adds `X-RateLimit-Limit`, `X-RateLimit-Remaining`, and `X-RateLimit-Reset` headers to every response

## Pre-conditions

- [ ] Backing store (Redis or in-memory Map) is initialized and accessible
- [ ] Configuration has been validated at startup (not per-request)
- [ ] Request object has been parsed by the HTTP framework (headers available)

## Post-conditions

- [ ] Rate limit headers are present on the response
- [ ] If allowed: request count for client key is incremented by 1
- [ ] If blocked: response status is 429 with a `Retry-After` header containing seconds until window reset
- [ ] No partial state - counter is either incremented or it is not

## Invariants

- Request count for any client key never exceeds `maxRequests` within a single window
- Window expiration is monotonic - a window never extends beyond its original end time

## Error Handling

| Error Condition | Behavior | Caller Receives |
|----------------|----------|-----------------|
| Backing store unavailable | Fail open - allow request, log warning | Request proceeds normally |
| Invalid client key extraction | Use fallback key "unknown" | Request is rate-limited under shared "unknown" bucket |
| Counter overflow (> Number.MAX_SAFE_INTEGER) | Reset counter to 1, log warning | Request proceeds normally |

### Retry Behavior

- **Idempotent**: No - each call increments the counter
- **Safe to retry**: Not applicable - middleware is called once per request by the framework

## Non-goals

- Does not handle authentication or authorization - those are separate middleware
- Does not implement distributed rate limiting with strict global consistency (uses per-instance counters with Redis for approximate coordination)
- Does not support dynamic rate limit changes per-request (configuration is set at startup)
- Does not queue or delay requests - either allows or rejects immediately

## Dependencies and Assumptions

| Dependency | Type | Assumption |
|------------|------|------------|
| Redis | Optional (runtime) | If configured, must be Redis 6+ with MULTI/EXEC support. Falls back to in-memory Map if unavailable. |
| HTTP framework | Runtime | Provides parsed request/response objects with header access |

### Environmental Assumptions

- Running in Node.js 20+
- Single-process or clustered - in-memory store is per-process, Redis store is shared
- System clock is reasonably accurate (NTP synchronized)

## Test Scenarios

### Happy Path

- [x] Request within limit returns 200 and decrements remaining count
- [x] Rate limit headers are present on every response
- [x] Counter resets after window expires

### Edge Cases

- [x] Exactly at limit (request N of N) - allowed, remaining shows 0
- [x] First request after window reset - counter starts fresh
- [x] Multiple clients are tracked independently
- [x] Custom keyFn extracts API key from header instead of IP

### Error Cases

- [x] Redis connection lost mid-request - fails open, logs warning
- [x] Request missing IP and no custom keyFn - falls back to "unknown" key
- [x] Configuration with windowMs below 1000 - rejected at startup with clear error message
