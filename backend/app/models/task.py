from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class Task(BaseModel):
    id: Optional[str] = None
    title: str
    description: str
    status: str
    priority: str
    energy_level: Optional[int] = None
    estimated_time: Optional[int] = None
    urgency_score: Optional[float] = None
    tags: List[str] = []
    due_date: Optional[datetime] = None
    user_id: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat() if v else None
        }