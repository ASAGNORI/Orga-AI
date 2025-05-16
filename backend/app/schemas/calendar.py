from pydantic import BaseModel
from typing import Optional, List
from uuid import UUID
from datetime import datetime

class EventResponse(BaseModel):
    """
    Schema for calendar event used in events router
    """
    id: UUID
    title: str
    description: Optional[str] = None
    start: datetime
    end: datetime
