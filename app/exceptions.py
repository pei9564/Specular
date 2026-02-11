"""Custom exception classes mapped to HTTP status codes (Constitution VII)."""


class AppException(Exception):
    """Base exception for all application errors."""

    status_code: int = 500
    error_code: str = "INTERNAL_ERROR"

    def __init__(self, message: str, details: dict | None = None) -> None:
        self.message = message
        self.details = details or {}
        super().__init__(self.message)


class ResourceNotFound(AppException):
    """Raised when a referenced resource does not exist (404)."""

    status_code = 404
    error_code = "RESOURCE_NOT_FOUND"


class DuplicateResource(AppException):
    """Raised when a unique constraint would be violated (409)."""

    status_code = 409
    error_code = "DUPLICATE_RESOURCE"


class InvalidState(AppException):
    """Raised when a resource is in an invalid state for the operation (400)."""

    status_code = 400
    error_code = "INVALID_STATE"


class PermissionDenied(AppException):
    """Raised when the user lacks required permissions (403)."""

    status_code = 403
    error_code = "PERMISSION_DENIED"


class QuotaExceeded(AppException):
    """Raised when a user exceeds their resource quota (429)."""

    status_code = 429
    error_code = "QUOTA_EXCEEDED"


class ValidationError(AppException):
    """Raised when input validation fails (422)."""

    status_code = 422
    error_code = "VALIDATION_ERROR"
