# Data Model: 建立初始管理員帳號

**Branch**: `001-bootstrap-admin` | **Date**: 2026-02-10

## Entity: `users`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | `UUID` | PK, default `uuid4` | Unique user identifier |
| `email` | `VARCHAR(255)` | UNIQUE, NOT NULL | Login email address |
| `password_hash` | `VARCHAR(255)` | NOT NULL | bcrypt-hashed password |
| `full_name` | `VARCHAR(100)` | NOT NULL | Display name |
| `role` | `VARCHAR(20)` | NOT NULL, default `'user'` | `admin` or `user` |
| `is_active` | `BOOLEAN` | NOT NULL, default `true` | Account active flag |
| `must_change_password` | `BOOLEAN` | NOT NULL, default `false` | Force password change on next login |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | NOT NULL, default `now()` | Creation timestamp |
| `updated_at` | `TIMESTAMP WITH TIME ZONE` | NOT NULL, default `now()` | Last update timestamp |

**Indexes**:
- `ix_users_email` — UNIQUE index on `email`
- `ix_users_role` — index on `role` (for admin lookups)

## Entity: `audit_logs`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | `UUID` | PK, default `uuid4` | Log entry identifier |
| `action` | `VARCHAR(100)` | NOT NULL | Action identifier (e.g., `system.bootstrap.admin`) |
| `actor_id` | `VARCHAR(100)` | NOT NULL | Who performed the action (`system` for bootstrap) |
| `target_type` | `VARCHAR(50)` | NOT NULL | Entity type affected (`user`) |
| `target_id` | `VARCHAR(100)` | NULL | ID of affected entity |
| `details` | `JSONB` | NULL | Additional context (no sensitive data) |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | NOT NULL, default `now()` | Event timestamp |

**Indexes**:
- `ix_audit_action_date` — composite index on `(action, created_at DESC)`

**Constraints**: INSERT-only at application level (no UPDATE/DELETE queries on this table).

## State Transitions

### User Account
```
(none) → [Bootstrap creates] → active (is_active=true, must_change_password=true)
active → [Admin logs in with default password] → prompted to change password
active → [Password changed] → active (must_change_password=false)
```

## Relationships

```
users 1──∞ audit_logs (via actor_id / target_id, logical reference, not FK)
```

Audit logs use string references (not FK) to allow logging for system-level actors and to maintain immutability.
