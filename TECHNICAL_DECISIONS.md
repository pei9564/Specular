# Technical Decisions: Bootstrap Admin Account Feature
## Specular-AI - FastAPI Greenfield Project

**Date**: February 2026
**Feature**: Bootstrap admin account on first startup
**Project Type**: Multi-user agent management platform (AI agents, LLM providers, MCP servers)
**Framework**: FastAPI with async/await patterns

---

## 1. Database: PostgreSQL vs SQLite

### Decision: **PostgreSQL 15**

### Rationale
PostgreSQL is the required choice for a multi-user agent management platform requiring concurrent user access, complex relationships (users, agents, LLM providers, MCP servers), and audit logging. The project's tech stack already specifies PostgreSQL 15 for relational data with AsyncPG/SQLAlchemy clients, ensuring scalability beyond single-instance development.

### Alternatives Considered
- **SQLite**: Suitable only for single-user or non-concurrent scenarios; lacks robust locking mechanisms, proper JSON operators, and array types needed for agent configurations; VACUUM operations cause writer stalls; no native async support; cannot handle multiple concurrent connections reliably in production.
- **MySQL**: Viable but PostgreSQL's superior JSON support, window functions, and advisory locks are more valuable for complex agent/provider relationships and audit trails.

### Implementation Notes
- Use AsyncPG for async driver (already in tech stack)
- Leverage PostgreSQL's JSONB for flexible agent configurations
- Use advisory locks or SERIALIZABLE transactions for idempotent bootstrap
- Connection pooling via `sqlalchemy.pool.NullPool` or `sqlalchemy.pool.AsyncAdaptedQueuePool`

---

## 2. ORM: SQLAlchemy 2.0 Async Patterns with FastAPI

### Decision: **SQLAlchemy 2.0 with async_sessionmaker and select() API**

### Rationale
SQLAlchemy 2.0's fully async support, modern select() API, and explicit session management align perfectly with FastAPI's async/await model. Type hints are first-class citizens, integration with Pydantic is seamless, and the deprecation of legacy ORM patterns forces cleaner code. This combination eliminates the query/session coupling issues of SQLAlchemy 1.x.

### Alternatives Considered
- **SQLAlchemy 1.x with asyncio**: Legacy column-style queries lack type safety; hybrid async/sync patterns cause confusion; no longer recommended for greenfield projects.
- **Tortoise ORM**: Lighter weight but less mature; smaller ecosystem; harder to integrate with complex migrations.
- **SQLModel**: Convenient Pydantic integration but built on SQLAlchemy 2.0 anyway; adds abstraction layer with marginal benefit for this use case.

### Implementation Pattern
```python
# Use async_sessionmaker
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker

engine = create_async_engine(DATABASE_URL, echo=False)
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

# Dependency injection in FastAPI
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session() as session:
        yield session

# Usage: Use select() API with type hints
from sqlalchemy import select
async def get_user(session: AsyncSession, email: str) -> User | None:
    result = await session.execute(select(User).where(User.email == email))
    return result.scalar_one_or_none()
```

### Key Patterns
- **Lazy loaded relationships**: Must use `selectinload()` or `joinedload()` explicitly in async context
- **Session scope**: Always use async context manager (`async with async_session() as session:`)
- **Type hints**: Return `User | None` instead of bare `User`; leverage Pydantic for API schemas

---

## 3. Password Hashing: bcrypt vs argon2 vs passlib

### Decision: **argon2-cffi via passlib (Argon2id)**

### Rationale
Argon2id (winner of Password Hashing Competition 2015) provides superior resistance against GPU/ASIC attacks through memory-hard hashing and time parameterization. Passlib's `CryptContext` allows seamless algorithm upgrades without re-hashing passwords, enabling migration from bcrypt if needed. For security-critical admin bootstrap, Argon2id's configurable work factors make it future-proof against hardware improvements.

### Alternatives Considered
- **bcrypt**: De facto standard; slower intentionally but less resistant to GPU attacks than Argon2; smaller parameter tuning space; perfectly adequate but less defense-in-depth.
- **scrypt**: Works but lacks industry-wide adoption and validation that Argon2 has; deprecated in favor of Argon2 in OWASP guidelines.
- **Plain passlib with PBKDF2**: Legacy; insufficient against modern GPU attacks; only acceptable for non-critical applications.

### Implementation Pattern
```python
from passlib.context import CryptContext
from passlib.exc import InvalidTokenError

pwd_context = CryptContext(
    schemes=["argon2"],
    deprecated="auto",
    argon2__memory_cost=65536,  # 64 MB
    argon2__time_cost=3,         # 3 iterations
    argon2__parallelism=4,       # 4 threads
)

def hash_password(password: str) -> str:
    """Hash password with Argon2id."""
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password using passlib (auto-detects algorithm)."""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Hashed password suitable for storage."""
    return pwd_context.hash(password)
```

### Dependencies
```
argon2-cffi>=23.1.0  # Argon2 implementation
passlib>=1.7.4       # Password context management
```

### Security Notes
- Never log plaintext passwords (use redaction in logs)
- Default admin password must be marked as `requires_password_change: true`
- Cost parameters tuned for 100-200ms hashing time (balance security/UX)

---

## 4. Migration Tool: Alembic Async Setup

### Decision: **Alembic with async support (manual revision execution)**

### Rationale
Alembic is the de facto standard for SQLAlchemy migrations. While Alembic's CLI is synchronous, async migrations can be executed via manual revision scripts using `AsyncConnection`. This approach maintains compatibility with SQLAlchemy 2.0's async engine while preserving Alembic's version control and rollback semantics.

### Alternatives Considered
- **Tortoise ORM migrations**: Coupled to Tortoise; reinventing the wheel when Alembic works.
- **Raw SQL migrations**: Zero abstraction; painful for multi-database support; error-prone.
- **SQLModel migrations**: Just calls Alembic under the hood.

### Implementation Pattern
```bash
# Initialize Alembic (one-time)
alembic init alembic
```

**alembic/env.py** (configured for async):
```python
import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from alembic.config import Config
from alembic.script import ScriptDirectory
from alembic.runtime.migration import MigrationContext
from alembic.operations import Operations

async def run_migrations_online():
    config = context.config
    engine = create_async_engine(config.get_section(config.config_ini_section).get("sqlalchemy.url"))

    async with engine.begin() as connection:
        await connection.run_sync(do_run_migrations)

    await engine.dispose()

def do_run_migrations(connection):
    context = MigrationContext.configure(connection)
    with Operations.context(context):
        context.run_migrations()

if context.is_offline_mode():
    run_migrations_offline()
else:
    asyncio.run(run_migrations_online())
```

**Async-safe migration revision** (alembic/versions/xxx_bootstrap.py):
```python
from sqlalchemy import Column, String, Boolean, DateTime, text
from sqlalchemy.ext.asyncio import AsyncConnection
from alembic import op

async def upgrade(connection: AsyncConnection) -> None:
    await connection.run_sync(
        lambda sync_conn: op.create_table(
            'users',
            Column('id', UUID, primary_key=True),
            Column('email', String, unique=True, nullable=False),
            Column('hashed_password', String, nullable=False),
            Column('requires_password_change', Boolean, default=True),
            Column('created_at', DateTime, server_default=text('now()')),
        )
    )

async def downgrade(connection: AsyncConnection) -> None:
    await connection.run_sync(lambda sync_conn: op.drop_table('users'))
```

### Integration with Bootstrap
- Run migrations before bootstrap check in startup hook
- Use Alembic's `alembic.command` API to trigger migrations programmatically if needed

---

## 5. Startup Hook Pattern: FastAPI Lifespan Events

### Decision: **FastAPI 0.93+ lifespan context manager**

### Rationale
FastAPI's lifespan context manager (via `@app.lifespan` or `contextlib.asynccontextmanager`) provides clean, single-responsibility startup/shutdown logic. This replaces deprecated `on_event()` hooks and integrates naturally with async patterns. The context manager pattern ensures proper resource cleanup and transaction handling for the bootstrap operation.

### Alternatives Considered
- **`@app.on_event("startup")`**: Deprecated in FastAPI 0.93+; multiple startup events hard to order; no built-in cleanup.
- **Separate startup scripts**: Decoupling startup from app lifecycle risks synchronization issues and missed state.
- **Middleware**: Overkill; startup happens once, middleware on every request.

### Implementation Pattern
```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from sqlalchemy.ext.asyncio import AsyncSession

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup logic
    print("Application starting...")

    # Run migrations
    await run_migrations()

    # Bootstrap admin account
    async with async_session() as session:
        await bootstrap_admin_account(session)

    print("Application ready")
    yield  # App runs here

    # Shutdown logic
    print("Application shutting down...")
    await cleanup_resources()

app = FastAPI(lifespan=lifespan)
```

### Bootstrap Service Integration
```python
async def bootstrap_admin_account(session: AsyncSession) -> None:
    """
    Idempotent bootstrap of initial admin account.

    Rules:
    - Skip if any users exist
    - Validate email and password strength
    - Create audit log entry
    - Force password change for default credentials
    - Never log plaintext passwords
    """
    # Implementation detail in Section 6 onwards
    pass
```

### Error Handling
```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        await bootstrap_admin_account(...)
        yield
    except BootstrapValidationError as e:
        logger.critical(f"Bootstrap validation failed: {e.message}")
        raise SystemExit(1) from e
    except Exception as e:
        logger.critical(f"Unexpected bootstrap error: {e}")
        raise SystemExit(1) from e
    finally:
        await cleanup()
```

---

## 6. Environment Variable Management: pydantic-settings

### Decision: **pydantic-settings with nested validators**

### Rationale
Pydantic v2's `pydantic-settings` provides type-safe, validated environment variable parsing with clear separation of concerns. Field validators catch configuration errors at startup (fail-fast principle), preventing silent misconfigurations. Nested models organize admin bootstrap config separately from database config.

### Alternatives Considered
- **python-dotenv + manual parsing**: Tedious; no validation; type coercion manual.
- **OmegaConf**: Overkill for this use case; adds YAML complexity.
- **os.environ + type casting**: Error-prone; no validation; scattered across codebase.

### Implementation Pattern
```python
from pydantic_settings import BaseSettings
from pydantic import Field, EmailStr, field_validator
from typing import Optional

class AdminBootstrapSettings(BaseSettings):
    """Validated bootstrap admin configuration."""

    email: EmailStr = Field(
        default="admin@pegatron.com",
        description="Admin account email address"
    )
    password: Optional[str] = Field(
        default=None,
        description="Custom admin password (leave empty for secure generation)"
    )
    full_name: str = Field(
        default="System Administrator",
        description="Admin account full name"
    )

    @field_validator('password')
    @classmethod
    def validate_password_strength(cls, v: str) -> str:
        """Enforce minimum password requirements."""
        if v is None:
            return v

        if len(v) < 12:
            raise ValueError("Password must be at least 12 characters")

        has_upper = any(c.isupper() for c in v)
        has_lower = any(c.islower() for c in v)
        has_digit = any(c.isdigit() for c in v)
        has_special = any(c in "!@#$%^&*()-_=+[]{}|;:,.<>?" for c in v)

        if not all([has_upper, has_lower, has_digit, has_special]):
            raise ValueError(
                "Password must contain uppercase, lowercase, digit, and special character"
            )

        return v

    model_config = {
        "env_prefix": "ADMIN_",
        "case_sensitive": False,
    }

class DatabaseSettings(BaseSettings):
    """Database configuration."""

    url: str = Field(
        default="postgresql+asyncpg://user:password@localhost/specular_ai",
        description="Async SQLAlchemy database URL"
    )

    model_config = {
        "env_prefix": "DATABASE_",
        "case_sensitive": False,
    }

class Settings(BaseSettings):
    """Root settings combining all configurations."""

    database: DatabaseSettings = DatabaseSettings()
    admin_bootstrap: AdminBootstrapSettings = AdminBootstrapSettings()
    log_level: str = Field(default="INFO")

    model_config = {
        "env_file": ".env",
        "case_sensitive": False,
    }

# Global settings instance
settings = Settings()
```

**.env** (example):
```bash
# Database
DATABASE_URL=postgresql+asyncpg://postgres:password@localhost/specular_ai

# Bootstrap Admin (optional; uses defaults if not set)
ADMIN_EMAIL=custom@company.com
ADMIN_PASSWORD=SecureP@ssw0rd123!
ADMIN_FULL_NAME=Company Administrator
```

### Validation Behavior
- **Invalid email format**: Fails at startup with clear error message
- **Weak password**: Fails at startup with requirements listed
- **Missing database URL**: Fails with helpful error message
- All validation happens before any app logic runs

### Logging Sensitive Values
```python
def get_displayable_settings(settings: Settings) -> dict:
    """Return settings dict with sensitive values redacted."""
    return {
        "database": "***REDACTED***",
        "admin_bootstrap": {
            "email": settings.admin_bootstrap.email,
            "password": "***REDACTED***",
            "full_name": settings.admin_bootstrap.full_name,
        },
        "log_level": settings.log_level,
    }

# In startup logging:
logger.info(f"Configuration loaded: {get_displayable_settings(settings)}")
```

---

## 7. Audit Logging Pattern: Structured Logging for Security Events

### Decision: **structlog with JSON output + PostgreSQL audit_logs table**

### Rationale
Structlog separates structured data from log messages, enabling JSON-formatted security logs for parsing and alerting. A dedicated `audit_logs` table provides queryable access to bootstrap events, user actions, and compliance requirements. This dual-layer approach satisfies both operational logging (application.log) and security/compliance logging (audit_logs table).

### Alternatives Considered
- **Python logging module alone**: Unstructured text; hard to parse; no queryable history.
- **Splunk/ELK**: Overkill for greenfield; adds operational complexity; not available in all deployments.
- **Database-only audit**: Harder to debug real-time issues; audit table not suitable for streaming.

### Implementation Pattern

**Configure structlog** (in app startup):
```python
import structlog
import logging

structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer(),  # JSON for security logs
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    cache_logger_on_first_use=True,
)

# Standard Python logging integration
logging.config.dictConfig({
    "version": 1,
    "formatters": {
        "json": {"()": structlog.stdlib.ProcessorFormatter},
        "plain": {"format": "%(message)s"},
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "json",
        },
        "file": {
            "class": "logging.handlers.RotatingFileHandler",
            "filename": "logs/application.log",
            "formatter": "json",
            "maxBytes": 104857600,  # 100MB
            "backupCount": 10,
        },
    },
    "loggers": {
        "": {
            "handlers": ["console", "file"],
            "level": "INFO",
        },
    },
})
```

**Audit logging helper**:
```python
import structlog
from enum import Enum
from typing import Any, Optional

log = structlog.get_logger()

class AuditAction(str, Enum):
    """Audit action types."""
    BOOTSTRAP_ADMIN = "system.bootstrap.admin"
    BOOTSTRAP_SKIP = "system.bootstrap.skip"
    BOOTSTRAP_INVALID_EMAIL = "system.bootstrap.invalid_email"
    BOOTSTRAP_INVALID_PASSWORD = "system.bootstrap.invalid_password"

async def log_audit_event(
    action: AuditAction,
    actor_id: str = "system",
    target_type: str = "user",
    target_id: Optional[str] = None,
    details: Optional[dict] = None,
    status: str = "success",
) -> None:
    """
    Log a security-relevant audit event.

    Args:
        action: Audit action type
        actor_id: User or system performing action
        target_type: Type of affected resource
        target_id: ID of affected resource (optional)
        details: Additional structured data (no passwords!)
        status: "success", "failure", "attempt"
    """
    log.info(
        "audit_event",
        action=action.value,
        actor_id=actor_id,
        target_type=target_type,
        target_id=target_id,
        details=details or {},
        status=status,
    )

    # Also persist to audit_logs table
    # (see AuditLog ORM model below)
```

**Database audit table** (SQLAlchemy ORM):
```python
from sqlalchemy import Column, String, DateTime, JSON, Integer, text
from sqlalchemy.orm import declarative_base
from datetime import datetime
from uuid import uuid4

Base = declarative_base()

class AuditLog(Base):
    """Immutable audit log for security events."""

    __tablename__ = "audit_logs"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid4()))
    action = Column(String(100), nullable=False, index=True)
    actor_id = Column(String(100), nullable=False)
    target_type = Column(String(50), nullable=False)
    target_id = Column(String(100))
    status = Column(String(20), nullable=False)  # success, failure, attempt
    details = Column(JSON)  # Additional context (never passwords)
    created_at = Column(DateTime, nullable=False, server_default=text('now()'))

    def __repr__(self):
        return f"<AuditLog {self.action} by {self.actor_id}>"
```

**Bootstrap audit logging**:
```python
async def bootstrap_admin_account(session: AsyncSession) -> None:
    """Bootstrap initial admin account with full audit trail."""

    # Check if users exist
    result = await session.execute(select(func.count(User.id)))
    user_count = result.scalar()

    if user_count > 0:
        await log_audit_event(
            action=AuditAction.BOOTSTRAP_SKIP,
            details={"reason": "users_exist", "user_count": user_count},
        )
        log.info("bootstrap_skipped", user_count=user_count)
        return

    try:
        # Validate bootstrap config
        email = settings.admin_bootstrap.email

        if not is_valid_email(email):  # Using EmailStr from pydantic
            await log_audit_event(
                action=AuditAction.BOOTSTRAP_INVALID_EMAIL,
                status="failure",
                details={"invalid_email": email[:10] + "..."},  # Redact
            )
            raise BootstrapValidationError(f"Invalid admin email: {email}")

        password = settings.admin_bootstrap.password
        if password and not is_strong_password(password):
            await log_audit_event(
                action=AuditAction.BOOTSTRAP_INVALID_PASSWORD,
                status="failure",
                details={"reason": "weak_password"},
            )
            raise BootstrapValidationError("Admin password does not meet strength requirements")

        # Create admin user
        hashed_password = hash_password(password or generate_secure_password())
        requires_change = password is None  # Default password requires change

        admin_user = User(
            id=uuid4(),
            email=email,
            full_name=settings.admin_bootstrap.full_name,
            hashed_password=hashed_password,
            role="admin",
            is_active=True,
            requires_password_change=requires_change,
        )

        session.add(admin_user)
        await session.commit()

        # Log successful bootstrap
        await log_audit_event(
            action=AuditAction.BOOTSTRAP_ADMIN,
            target_id=str(admin_user.id),
            details={
                "email": email,
                "requires_password_change": requires_change,
                "uses_default_credentials": password is None,
            },
        )

        log.info(
            "bootstrap_admin_created",
            email=email,
            requires_password_change=requires_change,
        )

        if requires_change:
            log.warning(
                "bootstrap_default_password_warning",
                message="Admin account created with auto-generated password; change required on first login",
            )

    except Exception as e:
        await log_audit_event(
            action=AuditAction.BOOTSTRAP_ADMIN,
            status="failure",
            details={"error": str(e)[:100]},  # Truncate
        )
        raise
```

**Never log passwords - redaction helper**:
```python
import re
from typing import Any

SENSITIVE_KEYS = {"password", "secret", "token", "key", "credential"}

def redact_sensitive_fields(data: dict) -> dict:
    """Recursively redact sensitive fields from log data."""
    if not isinstance(data, dict):
        return data

    result = {}
    for key, value in data.items():
        if any(sensitive in key.lower() for sensitive in SENSITIVE_KEYS):
            result[key] = "***REDACTED***"
        elif isinstance(value, dict):
            result[key] = redact_sensitive_fields(value)
        elif isinstance(value, list) and value and isinstance(value[0], dict):
            result[key] = [redact_sensitive_fields(v) for v in value]
        else:
            result[key] = value

    return result

# Use in bootstrap:
await log_audit_event(
    action=AuditAction.BOOTSTRAP_ADMIN,
    details=redact_sensitive_fields({
        "email": email,
        "password_hash": hashed_password,  # Still redact
        "requires_password_change": True,
    }),
)
```

### Query Audit Logs
```python
# Example: Find all bootstrap events
async def get_bootstrap_events(session: AsyncSession):
    result = await session.execute(
        select(AuditLog).where(
            AuditLog.action.startswith("system.bootstrap")
        ).order_by(AuditLog.created_at.desc())
    )
    return result.scalars().all()

# Example: Monitor for failed bootstrap attempts
async def monitor_bootstrap_failures(session: AsyncSession):
    result = await session.execute(
        select(AuditLog).where(
            AuditLog.action == AuditAction.BOOTSTRAP_ADMIN.value,
            AuditLog.status == "failure",
        )
    )
    return result.scalars().all()
```

---

## Integration Summary: Complete Bootstrap Service

### Data Flow
```
FastAPI lifespan startup
    ↓
    ├─→ Run Alembic migrations (creates tables)
    ↓
    ├─→ Load Settings from .env (pydantic-settings)
    ├─→ Validate email & password strength
    ↓
    ├─→ Check user count (SQLAlchemy 2.0 async select)
    ├─→ If count > 0: Skip bootstrap, audit log
    ├─→ If count == 0: Create admin user
    │   ├─→ Hash password (argon2-cffi via passlib)
    │   ├─→ Create User ORM object
    │   ├─→ Create AuditLog entry
    │   └─→ Commit transaction
    ↓
    └─→ Application ready (yield)
```

### Error Scenarios & Responses
| Scenario | Response | Audit Log |
|----------|----------|-----------|
| Invalid email format | SystemExit(1), log error | `BOOTSTRAP_INVALID_EMAIL` |
| Weak password | SystemExit(1), log error | `BOOTSTRAP_INVALID_PASSWORD` |
| Database unreachable | SystemExit(1), log error | (no entry - DB unavailable) |
| Users already exist | Skip gracefully, log skip | `BOOTSTRAP_SKIP` |
| Successful bootstrap | Log success, warn about default pwd | `BOOTSTRAP_ADMIN` |

### Security Checklist
- [x] Passwords never logged in plaintext
- [x] Argon2id with tuned parameters (65MB, 3 iterations, 4 threads)
- [x] Default password marked as `requires_password_change: true`
- [x] Email validated via Pydantic `EmailStr`
- [x] Password strength enforced (12+ chars, mixed case, digits, special chars)
- [x] Audit log immutable (INSERT-only table)
- [x] Idempotent operation (safe to restart app multiple times)
- [x] Configuration validation at startup (fail-fast)
- [x] Structured JSON logging for SIEM integration

---

## Dependencies to Add

```
# Core FastAPI async stack
fastapi>=0.109.0
uvicorn[standard]>=0.27.0
sqlalchemy[asyncio]>=2.0.24
asyncpg>=0.29.0
alembic>=1.13.0

# Pydantic v2
pydantic>=2.0.0
pydantic-settings>=2.0.0
email-validator>=2.1.0

# Password hashing
argon2-cffi>=23.1.0
passlib>=1.7.4

# Structured logging
structlog>=24.1.0

# Utilities
python-dotenv>=1.0.0
uuid>=1.30.0
```

---

## Rationale Summary

| Area | Choice | Why |
|------|--------|-----|
| **Database** | PostgreSQL | Multi-user, complex relationships, concurrent access, audit logging |
| **ORM** | SQLAlchemy 2.0 async | Type-safe, async-first, modern API, seamless Pydantic integration |
| **Passwords** | Argon2id (passlib) | Future-proof, GPU-resistant, tunable parameters, auto-upgrade path |
| **Migrations** | Alembic async | Industry standard, version control, rollback support, SQLAlchemy 2.0 native |
| **Startup** | FastAPI lifespan | Single responsibility, clean async patterns, resource cleanup guarantees |
| **Config** | pydantic-settings | Type-safe, validated at startup, nested models, fail-fast |
| **Audit Log** | structlog + DB | Structured JSON parsing, queryable history, SIEM integration, immutable records |

---

## Next Steps

1. **Create database schema** with User, AuditLog, and LLMProvider/MCPServer tables
2. **Initialize Alembic** with async-compatible env.py
3. **Implement BootstrapService** class with idempotency and error handling
4. **Write integration tests** using pytest-asyncio and async session fixtures
5. **Set up structured logging** with rotation and JSON formatting
6. **Document bootstrap procedure** for operators (when to use custom credentials)

