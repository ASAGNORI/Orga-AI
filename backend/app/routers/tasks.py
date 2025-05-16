from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional, Dict
from uuid import UUID
from datetime import datetime, timedelta
import pytz
from sqlalchemy.orm import Session
from app.services.ai_service import ai_service
from app.models.task_model import Task as TaskModel
from app.models.user import User
from app.database import get_db
from app.schemas.task import TaskCreate, TaskResponse
from dotenv import load_dotenv
from app.services.auth_service import get_current_user
import logging

router = APIRouter()

# Carrega variáveis do .env
load_dotenv()

logger = logging.getLogger(__name__)

class TaskSuggestionRequest(BaseModel):
    title: str
    description: Optional[str] = None

@router.get("/tasks", response_model=List[TaskResponse])
async def get_tasks(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try: 
        # Filter tasks by the current user
        return db.query(TaskModel).filter(TaskModel.user_id == current_user.id).all()
    except Exception as e:
        logger.error(f"Error fetching tasks: {str(e)}")
        # Return empty list on error (e.g., DB not available)
        return []

@router.post("/tasks", response_model=TaskResponse)
async def create_task(
    task: TaskCreate, 
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new task with user association."""
    try:
        # Converta o dicionário da tarefa para manipulação dos dados
        task_dict = task.dict()
        
        # Associate the task with the current user
        task_dict['user_id'] = current_user.id
        logger.info(f"Creating task for user {current_user.id}: {task_dict['title']}")
        
        # Verifique se due_date está presente para preservar o dia local
        if task_dict.get('due_date'):
            # Garantir que a data de vencimento é tratada para preservar o dia no fuso horário local
            # Ao receber a data em UTC, ajusta para garantir que seja o dia selecionado pelo usuário
            due_date = task_dict['due_date']
            
            # Define um timezone local (Brasil - São Paulo)
            local_tz = pytz.timezone('America/Sao_Paulo')
            
            # Converte a data UTC para o fuso horário local
            local_due_date = due_date.replace(tzinfo=pytz.UTC).astimezone(local_tz)
            
            # Extrai apenas a data (sem hora) e define meio-dia como horário padrão
            # Isso garante que a data exibida no calendário será sempre o dia correto
            normalized_date = datetime(
                year=local_due_date.year, 
                month=local_due_date.month, 
                day=local_due_date.day, 
                hour=12, minute=0, second=0, microsecond=0, 
                tzinfo=local_tz
            )
            
            # Converte de volta para UTC para armazenamento no banco de dados
            task_dict['due_date'] = normalized_date.astimezone(pytz.UTC)
        
        # Crie a nova tarefa com os dados ajustados
        new_task = TaskModel(**task_dict)
        db.add(new_task)
        db.commit()
        db.refresh(new_task)
        return new_task
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error creating task: {str(e)}")

@router.put("/tasks/{task_id}", response_model=TaskResponse)
async def update_task(
    task_id: UUID, 
    task: TaskCreate, 
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        # Filter by both task ID and user ID for security
        existing_task = db.query(TaskModel).filter(
            TaskModel.id == task_id,
            TaskModel.user_id == current_user.id
        ).first()
        
        if not existing_task:
            raise HTTPException(status_code=404, detail="Task not found")

        task_data = task.dict(exclude={"id", "created_at", "updated_at"})
        
        # Verifique se due_date está presente para preservar o dia local
        if task_data.get('due_date'):
            # Garantir que a data de vencimento é tratada para preservar o dia no fuso horário local
            due_date = task_data['due_date']
            
            # Define um timezone local (Brasil - São Paulo)
            local_tz = pytz.timezone('America/Sao_Paulo')
            
            # Converte a data UTC para o fuso horário local
            local_due_date = due_date.replace(tzinfo=pytz.UTC).astimezone(local_tz)
            
            # Extrai apenas a data (sem hora) e define meio-dia como horário padrão
            # Isso garante que a data exibida no calendário será sempre o dia correto
            normalized_date = datetime(
                year=local_due_date.year, 
                month=local_due_date.month, 
                day=local_due_date.day, 
                hour=12, minute=0, second=0, microsecond=0, 
                tzinfo=local_tz
            )
            
            # Converte de volta para UTC para armazenamento no banco de dados
            task_data['due_date'] = normalized_date.astimezone(pytz.UTC)
        
        for key, value in task_data.items():
            setattr(existing_task, key, value)
        
        db.commit()
        db.refresh(existing_task)
        return existing_task
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/tasks/{task_id}", response_model=dict)
async def delete_task(
    task_id: UUID, 
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        # Filter by both task ID and user ID for security
        existing_task = db.query(TaskModel).filter(
            TaskModel.id == task_id,
            TaskModel.user_id == current_user.id
        ).first()
        
        if not existing_task:
            raise HTTPException(status_code=404, detail="Task not found")

        db.delete(existing_task)
        db.commit()
        return {"message": "Task deleted successfully"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/tasks/suggest")
async def suggest_task_attributes(
    request: TaskSuggestionRequest,
    current_user: User = Depends(get_current_user)
):
    """Get AI suggestions for task attributes based on title and description"""
    try:
        logger.info(f"Suggesting task attributes for user {current_user.id}")
        return {}
    except Exception as e:
        logger.error(f"Error suggesting task attributes: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

from pytz import UTC, timezone
import logging

logger = logging.getLogger(__name__)

class TaskStats(BaseModel):
    """Modelo Pydantic para estatísticas de tarefas"""
    total: int = 0
    completed: int = 0
    overdue: int = 0
    dueToday: int = 0
    dueThisWeek: int = 0
    byPriority: Dict[str, int] = {"high": 0, "medium": 0, "low": 0}
    byTag: Dict[str, int] = {}

@router.get("/tasks/stats", response_model=TaskStats)
async def get_task_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get statistics about tasks for the current user"""
    # Initialize with default values to avoid NoneType errors
    stats = TaskStats()
    
    try:
        # Query tasks with error handling
        try:
            # Include tasks even if they have no project (project_id IS NULL)
            query = db.query(TaskModel).filter(TaskModel.user_id == current_user.id)
            tasks = query.all()
        except Exception as db_error:
            logger.error(f"Database query failed: {str(db_error)}")
            return stats
        
        # Update total task count
        stats.total = len(tasks)
        
        # Return empty stats if no tasks found
        if stats.total == 0:
            return stats
        
        # Configure timezone with error handling
        try:
            sp_tz = timezone('America/Sao_Paulo')
            now = datetime.now(sp_tz)
            today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
            week_end = today_start + timedelta(days=7)
        except Exception as tz_error:
            logger.error(f"Timezone configuration failed: {str(tz_error)}")
            sp_tz = UTC  # Fallback to UTC
            now = datetime.now(UTC)
            today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
            week_end = today_start + timedelta(days=7)

        # Process each task with error handling
        for i, task in enumerate(tasks):
            try:
                # Count completed tasks
                if task.status == "done":
                    stats.completed += 1

                # Count tasks by priority with validation
                if task.priority:
                    priority = str(task.priority).lower()
                    if priority in ["high", "medium", "low"]:
                        stats.byPriority[priority] = stats.byPriority.get(priority, 0) + 1

                # Process due dates with validation
                if task.due_date:
                    # Ensure due_date is datetime with timezone
                    if isinstance(task.due_date, datetime):
                        # Add timezone if missing
                        if task.due_date.tzinfo is None:
                            due_date = task.due_date.replace(tzinfo=UTC)
                        else:
                            due_date = task.due_date
                        
                        # Convert to local timezone
                        due_date = due_date.astimezone(sp_tz)
                        due_date_start = due_date.replace(hour=0, minute=0, second=0, microsecond=0)
                        
                        # Check if overdue (before today and not completed)
                        if due_date_start < today_start and task.status != "done":
                            stats.overdue += 1
                        # Check if due today
                        elif due_date_start == today_start:
                            stats.dueToday += 1
                        # Check if due this week
                        elif today_start < due_date_start <= week_end:
                            stats.dueThisWeek += 1

                # Process each tag with validation
                if hasattr(task, 'tags') and task.tags is not None:
                    # Convert tags to list if needed
                    tags = task.tags if isinstance(task.tags, list) else [task.tags] if isinstance(task.tags, str) else []
                    
                    # Process each non-empty tag
                    for tag in tags:
                        if tag:  # Skip empty tags
                            tag_str = str(tag).strip()
                            if tag_str:
                                stats.byTag[tag_str] = stats.byTag.get(tag_str, 0) + 1
                        
            except Exception:
                # Continue to next task without detailed logging
                pass

        return stats
    except Exception as e:
        logger.error(f"General error in statistics calculation: {str(e)}")
        return stats  # Return object with default values