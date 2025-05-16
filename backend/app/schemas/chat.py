from pydantic import BaseModel
from typing import Optional, List
from uuid import UUID
from datetime import datetime

class ChatRequest(BaseModel):
    message: str
    context: Optional[dict] = None

class ChatResponse(BaseModel):
    message: str
    suggestions: Optional[List[str]] = None
    context: Optional[dict] = None

class ChatHistoryEntry(BaseModel):
    id: UUID
    user_id: UUID
    user_message: str
    ai_response: str
    tags: Optional[List[str]] = []
    response_metadata: Optional[dict] = None  # Renamed from metadata to match model field
    created_at: str

    class Config:
        from_attributes = True

class ChatPromptRequest(BaseModel):
    text: str
    title: Optional[str] = None
    category: Optional[str] = None
    tags: Optional[List[str]] = None

class ChatPromptResponse(BaseModel):
    id: UUID
    text: str
    title: Optional[str] = None
    category: Optional[str] = None
    tags: Optional[List[str]] = []
    created_at: str