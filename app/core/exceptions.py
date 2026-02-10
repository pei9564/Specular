class BootstrapError(Exception):
    """Base exception for bootstrap operations."""


class BootstrapValidationError(BootstrapError):
    """Raised when bootstrap configuration is invalid (bad email, weak password)."""


class BootstrapDatabaseError(BootstrapError):
    """Raised when bootstrap cannot access the database."""
