# Example: Project CLAUDE.md

This is an example of a project-level CLAUDE.md that provides context specific to one service within a larger workspace.

---

# User Service

Microservice responsible for user management, authentication flows, and profile management.

## Overview

- **Language**: Python 3.11
- **Framework**: FastAPI
- **Database**: PostgreSQL 15
- **Cache**: Redis
- **ORM**: SQLAlchemy 2.0 with Alembic migrations

## Project Structure

```
user-service/
├── src/
│   ├── api/                 # FastAPI routes
│   │   ├── v1/             # API version 1
│   │   │   ├── users.py    # User CRUD endpoints
│   │   │   ├── auth.py     # Authentication endpoints
│   │   │   └── profiles.py # Profile endpoints
│   │   └── deps.py         # Dependency injection
│   ├── core/               # Core configuration
│   │   ├── config.py       # Settings management
│   │   ├── security.py     # JWT, password hashing
│   │   └── exceptions.py   # Custom exceptions
│   ├── models/             # SQLAlchemy models
│   ├── schemas/            # Pydantic schemas
│   ├── services/           # Business logic
│   └── repositories/       # Data access layer
├── tests/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
├── alembic/                # Database migrations
├── Dockerfile
├── pyproject.toml
└── Makefile
```

## Project Rules

### Inherits From

This project inherits all rules from workspace CLAUDE.md. The following are additions/overrides.

### Architecture

- **MUST** follow repository pattern for data access
- **MUST** use dependency injection via FastAPI's `Depends`
- **MUST** define Pydantic schemas for all API inputs/outputs
- **MUST NOT** access database directly from routes (use services)

### Naming Conventions

- **Files**: snake_case (`user_service.py`)
- **Classes**: PascalCase (`UserService`)
- **Functions**: snake_case (`get_user_by_id`)
- **Constants**: UPPER_SNAKE_CASE (`MAX_LOGIN_ATTEMPTS`)

### Testing

- **MUST** achieve 80%+ coverage for services layer
- **MUST** use pytest fixtures for database setup
- **MUST** mock external services (Auth0, SendGrid)
- **SHOULD** use factory_boy for test data

### Database

- **MUST** create Alembic migration for all schema changes
- **MUST** include down migration (rollback)
- **MUST NOT** use raw SQL in application code (use SQLAlchemy)
- **SHOULD** add indexes for columns used in WHERE clauses

## Common Commands

```bash
# Development server
make run
# or: uvicorn src.main:app --reload

# Run tests
make test
# or: pytest

# Run with coverage
make test-cov
# or: pytest --cov=src

# Create migration
make migration msg="description"
# or: alembic revision --autogenerate -m "description"

# Run migrations
make migrate
# or: alembic upgrade head

# Rollback migration
make rollback
# or: alembic downgrade -1

# Lint
make lint
# or: ruff check src tests

# Format
make format
# or: ruff format src tests

# Type check
make typecheck
# or: mypy src
```

## API Patterns

### Response Format

All endpoints return consistent response shape:

```python
# Success
{
    "success": True,
    "data": { ... },
    "meta": { "page": 1, "total": 100 }
}

# Error
{
    "success": False,
    "error": {
        "code": "USER_NOT_FOUND",
        "message": "User with ID 123 not found"
    }
}
```

### Endpoint Structure

```python
@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: UUID,
    user_service: UserService = Depends(get_user_service),
    current_user: User = Depends(get_current_user),
) -> UserResponse:
    """
    Get user by ID.

    - **user_id**: UUID of the user to retrieve
    """
    user = await user_service.get_by_id(user_id)
    if not user:
        raise UserNotFoundError(user_id)
    return UserResponse(success=True, data=user)
```

### Service Structure

```python
class UserService:
    def __init__(self, user_repo: UserRepository, cache: Redis):
        self.user_repo = user_repo
        self.cache = cache

    async def get_by_id(self, user_id: UUID) -> User | None:
        # Check cache first
        cached = await self.cache.get(f"user:{user_id}")
        if cached:
            return User.model_validate_json(cached)

        # Query database
        user = await self.user_repo.get_by_id(user_id)
        if user:
            await self.cache.set(
                f"user:{user_id}",
                user.model_dump_json(),
                ex=300  # 5 minute TTL
            )
        return user
```

## External Integrations

### Auth0

- Used for social login and MFA
- Configuration in `src/core/auth0.py`
- Test credentials in `tests/fixtures/auth0.py`

### SendGrid

- Transactional emails (welcome, password reset)
- Templates managed in SendGrid dashboard
- Service wrapper in `src/services/email.py`

## Environment Variables

Required (in addition to workspace variables):

```bash
# Database
USER_SERVICE_DATABASE_URL=postgresql://user:pass@localhost:5432/users

# Auth0
AUTH0_DOMAIN=tenant.auth0.com
AUTH0_CLIENT_ID=xxx
AUTH0_CLIENT_SECRET=xxx

# SendGrid
SENDGRID_API_KEY=xxx
SENDGRID_FROM_EMAIL=noreply@example.com

# Redis
REDIS_URL=redis://localhost:6379/0

# JWT
JWT_SECRET_KEY=xxx
JWT_ALGORITHM=HS256
JWT_EXPIRE_MINUTES=30
```

## Known Issues / Tech Debt

- [ ] TECH-123: Migrate from sync to async SQLAlchemy queries
- [ ] TECH-456: Add rate limiting to auth endpoints
- [ ] TECH-789: Improve password reset flow error handling

## Related Services

- **api-gateway**: Routes external traffic to this service
- **order-service**: Queries user data for order processing
- **admin-app**: Uses admin endpoints for user management

## Contact

- **Owner**: @alice
- **Slack**: #user-service
- **On-Call**: Follows platform rotation

---

*This CLAUDE.md is specific to user-service. See workspace CLAUDE.md for cross-project rules.*
