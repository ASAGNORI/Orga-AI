from sqlalchemy import Column, String, DateTime, JSON, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base
from sqlalchemy.orm import relationship
import uuid
from datetime import datetime

class SystemLog(Base):
    """Modelo para logs gerados pelo sistema ou integrações externas como N8N."""
    __tablename__ = "system_logs"
    
    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4
    )
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("auth.users.id", ondelete="SET NULL"),
        nullable=True
    )
    level = Column(String, nullable=True, default="info")  # Novo campo: nível do log (info, warning, error)
    source = Column(String, nullable=True, default="system")  # Novo campo: fonte do log
    message = Column(Text, nullable=True)  # Novo campo: mensagem do log
    action = Column(String, nullable=True, default="action")  # Alterado para ser opcional
    details = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationship (opcional)
    user = relationship("User", back_populates="system_logs", foreign_keys=[user_id])
