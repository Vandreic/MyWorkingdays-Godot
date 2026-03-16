"""Application configuration module.

This module handles all application settings using Pydantic.
Settings are loaded from environment variables or a .env file.

Example:
    >>> from app.core.config import settings
    >>> print(settings.title)
    Server API
"""

from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field


class Settings(BaseSettings):
    """Application settings loaded from environment variables.

    This class uses Pydantic's BaseSettings to load configuration from
    environment variables or a .env file.

    Attributes:
        global_access_key (str): Secret key for API authentication (required).
        title (str): API title displayed in documentation.
        description (str): API description displayed in documentation.
        version (str): Current API version.
        host (str): Server host address.
        port (int): Server port number.
        debug (bool): Enable debug mode for development.
    """
    
    # Security Configuration
    global_access_key: str

    # API Configuration (loaded from environment variables or .env file)
    title: str
    description: str
    version: str

    # Server Configuration
    host: str
    port: int
    debug: bool

    # Pydantic Settings Configuration
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )


# Create a single settings instance for the entire application
settings = Settings()
