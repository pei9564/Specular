"""
應用配置管理
使用 Pydantic Settings 管理環境變數
"""

from functools import lru_cache
from typing import List

from pydantic import Field, PostgresDsn
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """應用設定"""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # 應用基本設定
    app_name: str = Field(default="Specular AI", alias="APP_NAME")
    app_version: str = Field(default="1.0.0", alias="APP_VERSION")
    debug: bool = Field(default=False, alias="DEBUG")
    environment: str = Field(default="production", alias="ENVIRONMENT")

    # 資料庫設定
    database_url: PostgresDsn = Field(
        default="postgresql+asyncpg://postgres:password@localhost:5432/specular_ai",
        alias="DATABASE_URL",
    )
    audit_log_database_url: PostgresDsn = Field(
        default="postgresql+asyncpg://postgres:password@localhost:5432/audit_logs",
        alias="AUDIT_LOG_DATABASE_URL",
    )

    # CORS 設定
    allowed_origins: List[str] = Field(
        default=["http://localhost:3000"],
        alias="ALLOWED_ORIGINS",
    )

    # LLM 設定
    openai_api_key: str = Field(default="", alias="OPENAI_API_KEY")
    openai_base_url: str = Field(
        default="https://api.openai.com/v1",
        alias="OPENAI_BASE_URL",
    )
    vllm_base_url: str = Field(default="http://localhost:8000/v1", alias="VLLM_BASE_URL")
    ollama_base_url: str = Field(default="http://localhost:11434", alias="OLLAMA_BASE_URL")

    # 日誌設定
    log_level: str = Field(default="INFO", alias="LOG_LEVEL")
    log_format: str = Field(default="json", alias="LOG_FORMAT")

    # 安全設定
    secret_key: str = Field(
        default="your-secret-key-change-this-in-production",
        alias="SECRET_KEY",
    )
    algorithm: str = Field(default="HS256", alias="ALGORITHM")
    access_token_expire_minutes: int = Field(default=30, alias="ACCESS_TOKEN_EXPIRE_MINUTES")

    # 外部認證
    trust_external_auth: bool = Field(default=True, alias="TRUST_EXTERNAL_AUTH")

    @property
    def database_url_str(self) -> str:
        """取得資料庫連線字串"""
        return str(self.database_url)

    @property
    def audit_log_database_url_str(self) -> str:
        """取得審計日誌資料庫連線字串"""
        return str(self.audit_log_database_url)


@lru_cache
def get_settings() -> Settings:
    """取得應用設定（單例模式）"""
    return Settings()
