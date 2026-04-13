import pydantic
import pydantic_settings


class Settings(pydantic_settings.BaseSettings):
    model_config = pydantic_settings.SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    database_driver: str = "postgresql+psycopg"
    database_host: str
    database_port: int
    database_username: str
    database_password: str
    database_name: str

    redis_host: str
    redis_port: int
    redis_username: str
    redis_password: str | None
    redis_name: int | str
