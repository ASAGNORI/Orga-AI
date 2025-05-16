from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "Orga.AI"
    VERSION: str = "1.0.0"
    DATABASE_URL: str = "postgresql://postgres:postgres25@db:5432/postgres"
    SECRET_KEY: str = "your-secret-key"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

settings = Settings()
