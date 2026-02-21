"""
Application Configuration
Manages environment variables and settings
"""
import os
from pathlib import Path
from dotenv import load_dotenv
from pydantic_settings import BaseSettings
from functools import lru_cache

# Load .env file
env_path = Path(__file__).parent.parent / '.env'
load_dotenv(dotenv_path=env_path)


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""
    
    # App Info
    APP_NAME: str = "Car Contract Review API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True
    
    # API Keys
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    
    # Database
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./car_contracts.db")
    
    # Security
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # File Upload
    MAX_UPLOAD_SIZE_MB: int = 10
    UPLOAD_DIR: str = "./uploads"
    ALLOWED_EXTENSIONS: list = [".pdf", ".png", ".jpg", ".jpeg", ".tiff", ".bmp"]
    
    # External APIs
    NHTSA_API_BASE: str = "https://vpic.nhtsa.dot.gov/api/vehicles"
    
    # Tesseract Path (Windows)
    TESSERACT_CMD: str = os.getenv("TESSERACT_CMD", "")

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        if not self.TESSERACT_CMD or not os.path.exists(self.TESSERACT_CMD):
            # Try to find it in common locations
            common_paths = [
                r"C:\Program Files\Tesseract-OCR\tesseract.exe",
                r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe",
                os.path.expandvars(r"%LOCALAPPDATA%\Programs\Tesseract-OCR\tesseract.exe"),
                os.path.expandvars(r"%LOCALAPPDATA%\Tesseract-OCR\tesseract.exe"),
            ]
            for path in common_paths:
                if os.path.exists(path):
                    self.TESSERACT_CMD = path
                    break
    
    class Config:
        env_file = ".env"
        case_sensitive = True


def get_settings() -> Settings:
    """Return fresh settings instance"""
    return Settings()


# Convenience instance
settings = get_settings()
