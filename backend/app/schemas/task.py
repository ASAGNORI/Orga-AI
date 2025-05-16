from pydantic import BaseModel, UUID4, validator
from typing import Optional, List
from datetime import datetime

from pytz import UTC, timezone

class TaskBase(BaseModel):
    title: str
    description: Optional[str] = None
    status: Optional[str] = "todo"
    priority: Optional[str] = "medium"
    energy_level: Optional[int] = None
    estimated_time: Optional[int] = None
    tags: Optional[List[str]] = []
    due_date: Optional[datetime] = None
    project_id: Optional[UUID4] = None

    @validator('due_date')
    def validate_due_date(cls, v):
        if v is None:
            return v
        
        # Se a data não tem timezone, assume UTC
        if v.tzinfo is None:
            v = v.replace(tzinfo=UTC)
        
        # Converte para o timezone local (Brasil/São Paulo)
        local_tz = timezone('America/Sao_Paulo')
        local_date = v.astimezone(local_tz)
        
        # Normaliza para meio-dia do dia local
        normalized_date = datetime(
            year=local_date.year,
            month=local_date.month,
            day=local_date.day,
            hour=12,
            minute=0,
            second=0,
            microsecond=0,
            tzinfo=local_tz
        )
        
        # Converte de volta para UTC para armazenamento
        return normalized_date.astimezone(UTC)

class TaskCreate(TaskBase):
    pass

class TaskUpdate(TaskBase):
    title: Optional[str] = None

class TaskResponse(TaskBase):
    id: UUID4
    user_id: Optional[UUID4] = None
    project_id: Optional[UUID4] = None
    created_at: datetime
    updated_at: datetime
    urgency_score: Optional[float] = None

    class Config:
        from_attributes = True