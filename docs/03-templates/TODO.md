# TODO.md Template

## Usage

Use this template as an alternative to Jira for task tracking within a project. Copy to your project root or docs folder.

TODO.md provides:
- Git-versioned task tracking
- AI-readable task context
- Lightweight alternative to external tools
- Clear ownership and status

---

# TODO: [Project/Feature Name]

**Last Updated**: [YYYY-MM-DD]
**Owner**: [Primary owner]

## Quick Status

| Category | Total | Done | In Progress | Blocked |
|----------|-------|------|-------------|---------|
| Backend | 0 | 0 | 0 | 0 |
| Frontend | 0 | 0 | 0 | 0 |
| Infrastructure | 0 | 0 | 0 | 0 |
| Documentation | 0 | 0 | 0 | 0 |

## Current Focus

[What's being actively worked on right now?]

- IN PROGRESS: [Task currently in progress]
- IN PROGRESS: [Task currently in progress]

## Tasks

### Backend

#### API Endpoints

- [ ] `GET /api/resource` - Fetch resource list
  - Accepts: `limit`, `offset` query params
  - Returns: Paginated list
- [ ] `POST /api/resource` - Create new resource
  - Requires: `name`, `type` fields
  - Returns: Created resource with ID
- [ ] `PUT /api/resource/:id` - Update resource
- [ ] `DELETE /api/resource/:id` - Delete resource

#### Services

- [ ] Create ResourceService class
  - [ ] Implement CRUD methods
  - [ ] Add caching layer
  - [ ] Add validation logic

#### Database

- [ ] Create migration for `resources` table
- [ ] Add indexes for common queries
- [ ] Seed test data

### Frontend

#### Components

- [ ] ResourceList component
  - [ ] Table view with sorting
  - [ ] Pagination controls
  - [ ] Loading states
- [ ] ResourceForm component
  - [ ] Create mode
  - [ ] Edit mode
  - [ ] Validation feedback
- [ ] ResourceDetail component

#### State Management

- [ ] Add resource slice to store
- [ ] Implement async thunks for API calls
- [ ] Add selectors for derived data

#### Routing

- [ ] Add `/resources` route
- [ ] Add `/resources/:id` route
- [ ] Add `/resources/new` route

### Infrastructure

- [ ] Provision staging database
- [ ] Configure CI/CD pipeline
- [ ] Set up monitoring alerts

### Testing

- [ ] Unit tests for ResourceService
- [ ] Integration tests for API endpoints
- [ ] Component tests for ResourceList
- [ ] E2E tests for resource CRUD flow

### Documentation

- [ ] Update API documentation
- [ ] Add README section for resources
- [ ] Create runbook for common operations

## Blocked

[Tasks that can't proceed without external input]

- [ ] BLOCKED: [Blocked task] - **Blocker**: [What's blocking and who can unblock]

## Completed

[Move completed tasks here for reference]

### Week of [YYYY-MM-DD]

- [x] Initial project setup
- [x] Database schema design
- [x] API contract definition

### Week of [YYYY-MM-DD]

- [x] [Completed task]
- [x] [Completed task]

## Notes

### Decisions Made

- [YYYY-MM-DD]: Decided to use [X] because [reason]
- [YYYY-MM-DD]: Changed approach from [A] to [B] due to [reason]

### Open Questions

- [ ] [Question that needs resolution]
- [ ] [Question that needs resolution]

### Dependencies

- **External API**: [Service name] - [Status: Available/Pending]
- **Team**: [Team name] - Need [thing] by [date]

## Links

- Spec: [Link to spec document]
- PR: [Link to main PR]
- Staging: [Link to staging environment]
- Jira: [Link to Jira ticket, if applicable]

---

## Usage Tips

### Status Markers

Use these markers for quick scanning:

- `[ ]` - Not started
- `[x]` - Completed
- `IN PROGRESS` - In progress (add to Current Focus section)
- `BLOCKED` - Blocked (move to Blocked section)

### Task Granularity

Good task size:
- Completable in 1-4 hours
- Single clear outcome
- Testable/verifiable

Too big:
- "Build the API" → Break into endpoints
- "Add frontend" → Break into components

Too small:
- "Add semicolon" → Part of a larger task
- "Import module" → Part of a larger task

### Keeping It Current

Update TODO.md:
- When starting work (move to Current Focus)
- When completing work (move to Completed)
- When blocked (move to Blocked with blocker info)
- At end of each day/week (status summary)

### AI Integration

AI can read TODO.md to:
- Understand project scope
- Pick up next task
- Track what's been done
- Identify blockers

Ask AI:
- "What's the next task in TODO.md?"
- "Update TODO.md to mark X as complete"
- "What tasks are blocked?"

---

## Example: Filled-In TODO.md

```markdown
# TODO: User Notification System

**Last Updated**: 2025-03-15
**Owner**: Jane Smith

## Quick Status

| Category | Total | Done | In Progress | Blocked |
|----------|-------|------|-------------|---------|
| Backend | 6 | 3 | 2 | 0 |
| Frontend | 4 | 1 | 1 | 0 |
| Infrastructure | 2 | 2 | 0 | 0 |

## Current Focus

- IN PROGRESS: Email notification service integration
- IN PROGRESS: Notification preferences UI

## Tasks

### Backend

- [x] Create notifications database table and migration
- [x] Implement NotificationService with send/list/markRead
- [x] Add WebSocket support for real-time delivery
- [ ] Integrate SendGrid for email notifications
  - [ ] Template rendering with Handlebars
  - [ ] Rate limiting (max 10/hour per user)
- [ ] Add notification preferences API endpoints
- [ ] Batch digest for daily summary emails

### Frontend

- [x] NotificationBell component with unread count
- [ ] NotificationPanel dropdown with mark-as-read
  - [ ] Infinite scroll for history
  - [ ] Optimistic UI updates
- [ ] NotificationPreferences settings page
- [ ] Toast notifications for real-time events

### Infrastructure

- [x] Provision SQS queue for async notification dispatch
- [x] Configure SendGrid API key in Vault

## Blocked

(none)

## Completed

### Week of 2025-03-10

- [x] Initial project setup and database schema
- [x] NotificationService CRUD operations
- [x] WebSocket real-time delivery
- [x] SQS queue provisioning
- [x] NotificationBell component

## Notes

### Decisions Made

- 2025-03-11: Using SQS over direct sends to decouple notification dispatch from request cycle
- 2025-03-13: WebSocket for real-time, with polling fallback for older browsers
```
