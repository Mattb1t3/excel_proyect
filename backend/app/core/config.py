from pydantic_settings import BaseSettings
from typing import List
import json


class Settings(BaseSettings):
    APP_NAME: str = "XLSX Loader API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True
    
    DATABASE_URL: str
    DB_HOST: str = "mysql"
    DB_PORT: int = 3306
    DB_USER: str = "user"
    DB_PASSWORD: str = "password"
    DB_NAME: str = "xlsx_db"
    
    REDIS_URL: str = "redis://redis:6379/0"
    REDIS_HOST: str = "redis"
    REDIS_PORT: int = 6379
    
    CELERY_BROKER_URL: str = "redis://redis:6379/0"
    CELERY_RESULT_BACKEND: str = "redis://redis:6379/0"
    CELERY_TASK_TIME_LIMIT: int = 3600
    
    CORS_ORIGINS: str = '["http://localhost:4200"]'
    
    @property
    def cors_origins_list(self) -> List[str]:
        return json.loads(self.CORS_ORIGINS)
    
    MAX_UPLOAD_SIZE: int = 10485760
    ASYNC_THRESHOLD: int = 200
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
