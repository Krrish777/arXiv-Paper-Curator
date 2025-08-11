"""Application configuration"""

from typing import List

from pydantic import Field
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings"""

    # API CONFIGS
    API_V1_STR: str = "/api/v1"
    APP_NAME: str = Field(default="arXiv RAG API", env="APP_NAME")
    APP_VERSION: str = Field(default="0.1.0", env="APP_VERSION")
    APP_DESCRIPTION: str = Field(
        default="Production-grade Retrieval-Augmented Generation system",
        env="APP_DESCRIPTION",
    )
    DEBUG: bool = Field(default=False, env="DEBUG")
    ENVIRONMENT: str = Field(default="development", env="ENVIRONMENT")
    LOG_LEVEL: str = Field(default="INFO", env="LOG_LEVEL")

    # DATABASE
    POSTGRES_DB: str = Field(..., env="POSTGRES_DB")
    POSTGRES_USER: str = Field(..., env="POSTGRES_USER")
    POSTGRES_PASSWORD: str = Field(..., env="POSTGRES_PASSWORD")
    DATABASE_URL: str = Field(..., env="DATABASE_URL")
    DATABASE_URL_SYNC: str = Field(..., env="DATABASE_URL_SYNC")

    # OpenSearch
    # OPENSEARCH_URL: str = Field(..., env="OPENSEARCH_URL")
    # OPENSEARCH_USERNAME: str = Field(default="admin", env="OPENSEARCH_USERNAME")
    # OPENSEARCH_PASSWORD: str = Field(..., env="OPENSEARCH_PASSWORD")

    # HF_TOKEN
    HF_TOKEN: str = Field(..., env="HF_TOKEN")

    # OpenAI
    OPENAI_API_KEY: str = Field(..., env="OPENAI_API_KEY")
    OPENAI_API_BASE: str = Field(
        default="https://api-inference.huggingface.co/v1", env="OPENAI_API_BASE"
    )
    OPENAI_MODEL: str = Field(default="gpt-3.5-turbo", env="OPENAI_MODEL")

    # Redis
    REDIS_URL: str = Field(..., env="REDIS_URL")

    # Security
    # SECRET_KEY: str = Field(..., env="SECRET_KEY")

    # Airflow
    AIRFLOW_ADMIN_USER: str = Field(default="admin", env="AIRFLOW_ADMIN_USER")
    AIRFLOW_ADMIN_PASSWORD: str = Field(..., env="AIRFLOW_ADMIN_PASSWORD")

    # Embedding Configuration
    EMBEDDING_MODEL: str = Field(default="thenlper/gte-base", env="EMBEDDING_MODEL")
    EMBEDDING_DEVICE: str = Field(default="gpu", env="EMBEDDING_DEVICE")
    EMBEDDING_BATCH_SIZE: int = Field(default=16, env="EMBEDDING_BATCH_SIZE")
    EMBEDDING_MAX_LENGTH: int = Field(default=512, env="EMBEDDING_MAX_LENGTH")

    # CORS
    ALLOWED_ORIGINS: List[str] = Field(
        default=[
            "http://localhost:3000",
            "http://localhost:8080",
            "http://localhost:8000",
            "http://localhost:8000/docs",
        ],
        env="ALLOWED_ORIGINS",
    )
    ALLOWED_METHODS: List[str] = Field(
        default=["GET", "POST", "PUT", "DELETE", "OPTIONS"], env="ALLOWED_METHODS"
    )
    ALLOWED_HEADERS: List[str] = Field(default=["*"], env="ALLOWED_HEADERS")

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
