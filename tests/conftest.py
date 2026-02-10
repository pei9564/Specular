import structlog

from app.core.logging import configure_logging


def pytest_configure(config):
    configure_logging()
    structlog.reset_defaults()
