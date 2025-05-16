from fastapi import APIRouter
from typing import List
from app.schemas.calendar import EventResponse

router = APIRouter()

@router.get("/events", response_model=List[EventResponse])
async def get_events():
    """Return list of calendar events (stub)"""
    return []