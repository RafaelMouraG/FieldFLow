from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    database_url: str = Field(alias="DATABASE_URL")
    rabbitmq_url: str | None = Field(default=None, alias="RABBITMQ_URL")
    mom_exchange: str = Field(default="fieldflow.events", alias="MOM_EXCHANGE")

    jwt_secret: str = Field(alias="JWT_SECRET")
    jwt_algorithm: str = Field(default="HS256", alias="JWT_ALGORITHM")
    jwt_expires_minutes: int = Field(default=60 * 24, alias="JWT_EXPIRES_MINUTES")

    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=False,
        extra="ignore",
    )


settings = Settings()
DATABASE_URL = settings.database_url
