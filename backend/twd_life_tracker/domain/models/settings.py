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

    cache_dir_path: pydantic.DirectoryPath | None = None
