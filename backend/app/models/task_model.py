from sqlalchemy import Column, String, Text, DateTime, Float, ForeignKey, Integer
from sqlalchemy.dialects.postgresql import ARRAY, UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid
from datetime import datetime
from app.database import Base

class Task(Base):
    __tablename__ = "tasks"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title = Column(String, nullable=False)
    description = Column(Text)
    status = Column(String, server_default="todo")
    priority = Column(String, server_default="medium")
    energy_level = Column(Integer)
    estimated_time = Column(Integer)
    urgency_score = Column(Float)
    tags = Column(ARRAY(String), server_default='{}')
    due_date = Column(DateTime(timezone=True))
    user_id = Column(UUID(as_uuid=True), ForeignKey("auth.users.id"), nullable=True)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user = relationship("User", back_populates="tasks")
    project = relationship("Project", back_populates="tasks")