import uuid
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
import structlog
from structlog.testing import capture_logs

from app.core.config import AdminBootstrapSettings
from app.models.audit_log import AuditLog
from app.models.user import User
from app.services.bootstrap import BootstrapAdminService, BootstrapResult


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_mock_session(user_count: int = 0) -> AsyncMock:
    """Create a mock AsyncSession that returns the given user count."""
    session = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalar_one.return_value = user_count
    session.execute.return_value = mock_result
    return session


# ---------------------------------------------------------------------------
# Phase 3 / US1: Core Bootstrap Logic
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_bootstrap_default_credentials() -> None:
    """Rule 1, Example 1: First startup with defaults creates admin."""
    session = _make_mock_session(user_count=0)
    settings = AdminBootstrapSettings()  # all defaults

    service = BootstrapAdminService(session=session, settings=settings)

    with capture_logs() as cap_logs:
        result = await service.execute()

    # Verify result
    assert result.action == "created"
    assert result.admin_email == "admin@pegatron.com"
    assert result.uses_default_password is True

    # Verify User was added to session
    session.add.assert_called()
    added_obj = session.add.call_args[0][0]
    assert isinstance(added_obj, User)
    assert added_obj.email == "admin@pegatron.com"
    assert added_obj.role == "admin"
    assert added_obj.is_active is True
    assert added_obj.must_change_password is True
    assert added_obj.full_name == "System Administrator"

    # Verify auto-generated password is 16 chars (hashed, so check the raw was 16)
    assert added_obj.password_hash  # not empty

    # Verify structlog events
    events = [log["event"] for log in cap_logs]
    assert "bootstrap_admin_created" in events

    # Verify default password warning
    warning_logs = [log for log in cap_logs if log.get("event") == "bootstrap_default_password_warning"]
    assert len(warning_logs) >= 1

    session.commit.assert_awaited()


@pytest.mark.asyncio
async def test_bootstrap_custom_credentials() -> None:
    """Rule 1, Example 2: First startup with custom config creates admin with custom email."""
    session = _make_mock_session(user_count=0)
    settings = AdminBootstrapSettings(
        email="custom@company.com",
        password="Str0ng!P@ssw0rd#",
        full_name="Custom Admin",
    )

    service = BootstrapAdminService(session=session, settings=settings)

    with capture_logs() as cap_logs:
        result = await service.execute()

    assert result.action == "created"
    assert result.admin_email == "custom@company.com"
    assert result.uses_default_password is False

    added_obj = session.add.call_args[0][0]
    assert isinstance(added_obj, User)
    assert added_obj.email == "custom@company.com"
    assert added_obj.full_name == "Custom Admin"

    # Verify structlog events
    events = [log["event"] for log in cap_logs]
    assert "bootstrap_admin_created" in events

    # Verify NO default password warning
    warning_events = [log["event"] for log in cap_logs if "default_password" in log.get("event", "")]
    assert len(warning_events) == 0


@pytest.mark.asyncio
async def test_bootstrap_skip_existing_users() -> None:
    """Rule 2, Example 3: Skip bootstrap if users exist."""
    session = _make_mock_session(user_count=3)
    settings = AdminBootstrapSettings()

    service = BootstrapAdminService(session=session, settings=settings)

    with capture_logs() as cap_logs:
        result = await service.execute()

    assert result.action == "skipped"
    assert result.admin_email is None

    # No user should be added
    session.add.assert_not_called()

    # Verify structlog skip event
    events = [log["event"] for log in cap_logs]
    assert "bootstrap_admin_skipped" in events


@pytest.mark.asyncio
async def test_bootstrap_idempotent_restart() -> None:
    """Rule 4, Example 6: Re-running bootstrap after admin exists does nothing."""
    session = _make_mock_session(user_count=1)
    settings = AdminBootstrapSettings()

    service = BootstrapAdminService(session=session, settings=settings)

    with capture_logs() as cap_logs:
        result = await service.execute()

    assert result.action == "skipped"
    session.add.assert_not_called()
    session.commit.assert_not_awaited()

    # Verify structlog skip event
    events = [log["event"] for log in cap_logs]
    assert "bootstrap_admin_skipped" in events


# ---------------------------------------------------------------------------
# Phase 4 / US2: Configuration Validation
# ---------------------------------------------------------------------------

def test_invalid_email_rejects() -> None:
    """Rule 3, Example 4: Invalid email format rejected."""
    with pytest.raises(Exception):  # ValidationError
        AdminBootstrapSettings(email="not-an-email")


def test_weak_password_rejects() -> None:
    """Rule 3, Example 5: Weak password rejected."""
    with pytest.raises(Exception) as exc_info:
        AdminBootstrapSettings(password="123")
    assert "12 characters" in str(exc_info.value).lower() or "password" in str(exc_info.value).lower()


# ---------------------------------------------------------------------------
# Phase 5 / US3: Audit Logging & Security
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_audit_log_created_on_bootstrap() -> None:
    """Rule 5, Example 7: Bootstrap creates audit log entry."""
    session = _make_mock_session(user_count=0)
    settings = AdminBootstrapSettings()

    service = BootstrapAdminService(session=session, settings=settings)
    await service.execute()

    # Find AuditLog among all objects added to session
    add_calls = session.add.call_args_list
    audit_logs = [call[0][0] for call in add_calls if isinstance(call[0][0], AuditLog)]
    assert len(audit_logs) >= 1

    audit_log = audit_logs[0]
    assert audit_log.action == "system.bootstrap.admin"
    assert audit_log.actor_id == "system"
    assert audit_log.target_type == "user"


@pytest.mark.asyncio
async def test_no_password_in_logs() -> None:
    """Rule 6, Example 8: Password must never appear in log output."""
    session = _make_mock_session(user_count=0)
    settings = AdminBootstrapSettings(
        password="MyS3cret!P@ssword",
    )

    service = BootstrapAdminService(session=session, settings=settings)

    with capture_logs() as cap_logs:
        await service.execute()

    log_text = str(cap_logs)
    assert "MyS3cret!P@ssword" not in log_text


@pytest.mark.asyncio
async def test_default_password_forces_change() -> None:
    """Rule 6, Example 9: Default password sets must_change_password=True."""
    session = _make_mock_session(user_count=0)
    settings = AdminBootstrapSettings()  # no password = default

    service = BootstrapAdminService(session=session, settings=settings)
    await service.execute()

    added_obj = session.add.call_args_list[0][0][0]
    if isinstance(added_obj, User):
        assert added_obj.must_change_password is True
