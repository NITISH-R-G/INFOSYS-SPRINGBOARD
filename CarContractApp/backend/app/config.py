"""
Application Configuration
Manages environment variables and settings
"""
import os
from pathlib import Path
from dotenv import load_dotenv
from pydantic_settings import BaseSettings

# Load .env file
env_path = Path(__file__).parent.parent / '.env'
load_dotenv(dotenv_path=env_path)


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""
    
    # App Info
    APP_NAME: str = "Car Contract Review API"
    APP_VERSION: str = "2.0.0"
    DEBUG: bool = False
    
    # API Keys
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    
    # Database (PostgreSQL required)
    DATABASE_URL: str = os.getenv("DATABASE_URL", "")
    
    # Security
    SECRET_KEY: str = os.getenv("SECRET_KEY", "")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # File Upload
    MAX_UPLOAD_SIZE_MB: int = 10
    UPLOAD_DIR: str = "./uploads"
    ALLOWED_EXTENSIONS: list = [".pdf", ".png", ".jpg", ".jpeg", ".tiff", ".bmp"]
    
    # External APIs
    NHTSA_API_BASE: str = "https://vpic.nhtsa.dot.gov/api/vehicles"
    
    # Tesseract Path (read from env only)
    TESSERACT_CMD: str = os.getenv("TESSERACT_CMD", "")

    # CORS
    ALLOWED_ORIGINS: str = os.getenv("ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:8080")

    # Redis / Celery
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")
    CELERY_BROKER_URL: str = os.getenv("CELERY_BROKER_URL", "redis://localhost:6379/0")
    CELERY_RESULT_BACKEND: str = os.getenv("CELERY_RESULT_BACKEND", "redis://localhost:6379/0")

    def get_allowed_origins(self) -> list:
        """Parse comma-separated ALLOWED_ORIGINS into a list"""
        return [o.strip() for o in self.ALLOWED_ORIGINS.split(",") if o.strip()]

    def validate_required(self):
        """Validate that required settings are configured"""
        errors = []
        if not self.DATABASE_URL:
            errors.append("DATABASE_URL is not set")
        if not self.SECRET_KEY:
            errors.append("SECRET_KEY is not set")
        if errors:
            raise ValueError(f"Missing required configuration: {'; '.join(errors)}")
    
    class Config:
        env_file = ".env"
        case_sensitive = True


def get_settings() -> Settings:
    """Return fresh settings instance"""
    return Settings()


# Convenience instance
settings = get_settings()
