# Quickstart: 建立初始管理員帳號

## Prerequisites

- Python 3.11+
- PostgreSQL 15 running (or Docker)
- pip / poetry

## Setup

```bash
# 1. Install backend dependencies
cd backend
pip install fastapi uvicorn "sqlalchemy[asyncio]" asyncpg alembic \
    pydantic-settings "passlib[bcrypt]" structlog email-validator

# 2. Set up PostgreSQL (via Docker)
docker run -d --name specular-db \
  -e POSTGRES_USER=specular \
  -e POSTGRES_PASSWORD=specular \
  -e POSTGRES_DB=specular \
  -p 5432:5432 \
  postgres:15

# 3. Configure environment
cp .env.example .env
# Edit .env:
#   DATABASE_URL=postgresql+asyncpg://specular:specular@localhost:5432/specular
#   ADMIN__EMAIL=admin@pegatron.com       (optional, this is the default)
#   ADMIN__PASSWORD=                       (optional, auto-generated if empty)

# 4. Run migrations
alembic upgrade head

# 5. Start the application (bootstrap runs automatically)
uvicorn app.main:app --reload
```

## Verify Bootstrap

Check the application logs for:
```json
{"event": "bootstrap_admin_created", "email": "admin@pegatron.com", "uses_default_password": true}
```

Or query the database:
```sql
SELECT email, role, is_active, must_change_password FROM users;
SELECT action, actor_id, details FROM audit_logs WHERE action = 'system.bootstrap.admin';
```

## Custom Admin Credentials

Set environment variables before first startup:
```bash
export ADMIN__EMAIL="custom@company.com"
export ADMIN__PASSWORD="MyStr0ng!P@ssword"
```

## Running Tests

```bash
pytest tests/steps/test_bootstrap.py -v
```
