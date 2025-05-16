from fastapi import APIRouter, HTTPException, Depends
from typing import List
from sqlalchemy.orm import Session
from uuid import UUID
from app.models.project_model import Project as ProjectModel
from app.models.user import User
from app.schemas.project import ProjectCreate, ProjectUpdate, ProjectResponse
from app.database import get_db
from app.services.auth_service import get_current_user
from datetime import datetime
import logging

logger = logging.getLogger(__name__)
router = APIRouter()

@router.get("/projects", response_model=List[ProjectResponse])
async def get_projects(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Filter projects by the current user
    return db.query(ProjectModel).filter(ProjectModel.user_id == current_user.id).all()

@router.post("/projects", response_model=ProjectResponse)
async def create_project(
    project: ProjectCreate, 
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Associate the project with the current user
    project_dict = project.dict()
    project_dict['user_id'] = current_user.id
    logger.info(f"Creating project for user {current_user.id}: {project_dict['title']}")
    
    new = ProjectModel(**project_dict, created_at=datetime.utcnow(), updated_at=datetime.utcnow())
    db.add(new)
    db.commit()
    db.refresh(new)
    return new

@router.get("/projects/{project_id}", response_model=ProjectResponse)
async def get_project(
    project_id: UUID, 
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    proj = db.query(ProjectModel).filter(
        ProjectModel.id == project_id,
        ProjectModel.user_id == current_user.id
    ).first()
    if not proj:
        raise HTTPException(status_code=404, detail="Project not found")
    return proj

@router.put("/projects/{project_id}", response_model=ProjectResponse)
async def update_project(
    project_id: UUID, 
    project_update: ProjectUpdate, 
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    proj = db.query(ProjectModel).filter(
        ProjectModel.id == project_id,
        ProjectModel.user_id == current_user.id
    ).first()
    if not proj:
        raise HTTPException(status_code=404, detail="Project not found")
    
    for key, val in project_update.dict(exclude_unset=True).items():
        setattr(proj, key, val)
    
    proj.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(proj)
    return proj

@router.delete("/projects/{project_id}", response_model=dict)
async def delete_project(
    project_id: UUID, 
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    proj = db.query(ProjectModel).filter(
        ProjectModel.id == project_id,
        ProjectModel.user_id == current_user.id
    ).first()
    if not proj:
        raise HTTPException(status_code=404, detail="Project not found")
    
    db.delete(proj)
    db.commit()
    return {"message": "Project deleted successfully"}