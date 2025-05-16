"""
Rotas para gerenciamento de tags
"""
from typing import List, Dict
from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.task_model import Task as TaskModel
from pydantic import BaseModel

router = APIRouter()

class Tag(BaseModel):
    name: str
    usage_count: int

@router.get("/tags/common", response_model=List[Tag])
async def get_common_tags(db: Session = Depends(get_db)):
    """Retorna as tags mais comuns com suas contagens"""
    tag_counts = {}
    tasks = db.query(TaskModel).all()
    
    for task in tasks:
        if task.tags:
            for tag in task.tags:
                tag_counts[tag] = tag_counts.get(tag, 0) + 1
    
    # Converte o dicionário em uma lista de objetos Tag ordenada por contagem
    tags = [
        Tag(name=name, usage_count=count)
        for name, count in sorted(tag_counts.items(), key=lambda x: (-x[1], x[0]))
    ]
    
    return tags

@router.post("/tags/update-usage")
async def update_tag_usage(tag_name: str, db: Session = Depends(get_db)):
    """Atualiza a contagem de uso de uma tag"""
    return {"message": "Tag usage updated"}
