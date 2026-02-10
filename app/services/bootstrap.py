import secrets
import string
from typing import Any, Literal

import structlog
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import AdminBootstrapSettings
from app.core.security import hash_password
from app.models.audit_log import AuditLog
from app.models.user import User

log = structlog.get_logger()


class BootstrapResult(BaseModel):
    action: Literal["created", "skipped"]
    admin_email: str | None = None
    uses_default_password: bool = False


class BootstrapAdminService:
    def __init__(self, session: AsyncSession, settings: AdminBootstrapSettings) -> None:
        self._session = session
        self._settings = settings

    async def execute(self) -> BootstrapResult:
        if await self._has_existing_users():
            log.info("bootstrap_admin_skipped", reason="users_already_exist")
            return BootstrapResult(action="skipped")

        user = await self._create_admin_user()
        await self._record_audit_event(
            action="system.bootstrap.admin",
            target_id=str(user.id),
            details={
                "email": user.email,
                "requires_password_change": user.must_change_password,
                "uses_default_password": self._settings.password is None,
            },
        )
        await self._session.commit()

        uses_default = self._settings.password is None
        log.info(
            "bootstrap_admin_created",
            email=user.email,
            uses_default_password=uses_default,
        )
        if uses_default:
            log.warning(
                "bootstrap_default_password_warning",
                message="Admin account created with auto-generated password; change required on first login",
            )

        return BootstrapResult(
            action="created",
            admin_email=user.email,
            uses_default_password=uses_default,
        )

    async def _has_existing_users(self) -> bool:
        result = await self._session.execute(select(func.count(User.id)))
        count = result.scalar_one()
        return count > 0

    async def _create_admin_user(self) -> User:
        password = self._settings.password
        uses_default = password is None
        if uses_default:
            password = self._generate_random_password(16)

        user = User(
            email=self._settings.email,
            password_hash=hash_password(password),
            full_name=self._settings.full_name,
            role="admin",
            is_active=True,
            must_change_password=uses_default,
        )
        self._session.add(user)
        return user

    async def _record_audit_event(
        self, action: str, target_id: str | None, details: dict[str, Any]
    ) -> None:
        audit_log = AuditLog(
            action=action,
            actor_id="system",
            target_type="user",
            target_id=target_id,
            details=details,
        )
        self._session.add(audit_log)

    @staticmethod
    def _generate_random_password(length: int = 16) -> str:
        alphabet = string.ascii_letters + string.digits + "!@#$%^&*"
        while True:
            password = "".join(secrets.choice(alphabet) for _ in range(length))
            if (
                any(c.isupper() for c in password)
                and any(c.islower() for c in password)
                and any(c.isdigit() for c in password)
                and any(c in "!@#$%^&*" for c in password)
            ):
                return password
