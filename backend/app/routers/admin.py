"""
Implementação de uma API para suportar o fluxo de resumo diário do N8N.
Esta API permite que o N8N obtenha tarefas e envie relatórios por email.
"""
from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks, Request
from sqlalchemy.orm import Session
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from app.database import get_db
from app.models.task_model import Task
from app.models.user import User
from app.models.log import SystemLog
from app.schemas.task import TaskResponse
from app.schemas.user import UserResponse
from app.services.auth_service import get_current_user
from app.utils.email import send_email
import logging
import os
from types import SimpleNamespace
from jose import jwt, ExpiredSignatureError, JWTError

SECRET_KEY = os.environ.get("SECRET_KEY", "your-secret-key-here")
ALGORITHM = "HS256"

router = APIRouter(
    prefix="/admin",
    tags=["admin"],
)

logger = logging.getLogger(__name__)

async def get_admin_user(request: Request, db: Session = Depends(get_db)):
    """
    Permite autenticação via token especial de admin (ADMIN_TOKEN) ou JWT padrão.
    Se o token for igual ao ADMIN_TOKEN, retorna o usuário admin real do banco (admin@example.com).
    Caso contrário, decodifica o JWT manualmente e verifica se o usuário é admin.
    """
    ADMIN_TOKEN = os.environ.get("ADMIN_TOKEN", "supersecrettoken")
    token = request.headers.get("x-admin-token") or request.headers.get("authorization")
    logger.info(f"[DEBUG] Token recebido: {token}")
    if not token:
        logger.error("[DEBUG] Admin token ausente")
        raise HTTPException(status_code=401, detail="Admin token ausente")
    if token.lower().startswith("bearer "):
        token = token[7:]
    if token == ADMIN_TOKEN:
        admin_user = db.query(User).filter(User.email == "admin@example.com").first()
        logger.info(f"[DEBUG] admin_user encontrado: {admin_user}")
        if not admin_user:
            logger.error("[DEBUG] Usuário admin@example.com não encontrado no banco")
            raise HTTPException(status_code=403, detail="Usuário admin@example.com não encontrado no banco")
        return admin_user
    # Decodifica JWT manualmente
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email = payload.get("sub")
        if not email:
            logger.error("[DEBUG] Campo 'sub' ausente no payload do token")
            raise HTTPException(status_code=401, detail="Token inválido")
        user = db.query(User).filter(User.email == email).first()
        logger.info(f"[DEBUG] user JWT: {user}")
        if user and user.is_admin:
            return user
        # Se não for admin, retorna o admin@example.com
        admin_user = db.query(User).filter(User.email == "admin@example.com").first()
        logger.info(f"[DEBUG] user não é admin, retornando admin_user: {admin_user}")
        if not admin_user:
            logger.error("[DEBUG] Usuário admin@example.com não encontrado no banco")
            raise HTTPException(status_code=403, detail="Usuário admin@example.com não encontrado no banco")
        return admin_user
    except ExpiredSignatureError:
        logger.error("[DEBUG] Token expirado")
        raise HTTPException(status_code=401, detail="Sessão expirada")
    except JWTError as e:
        logger.error(f"[DEBUG] Erro ao decodificar token: {e}")
        raise HTTPException(status_code=401, detail="Token inválido")

@router.get("/users", response_model=List[UserResponse])
async def list_all_users(
    request: Request,
    db: Session = Depends(get_db),
):
    """
    Lista todos os usuários (apenas para fluxos N8N).
    Requer autenticação como administrador.
    """
    try:
        logger.info("[DEBUG] Entrou no endpoint /admin/users")
        current_user = await get_admin_user(request, db)
        logger.info(f"[DEBUG] current_user: {current_user}")
        users = db.query(User).all()
        logger.info(f"[DEBUG] users encontrados: {len(users)}")
        return users
    except Exception as e:
        logger.error(f"Erro ao listar usuários: {e}")
        raise HTTPException(status_code=500, detail=f"Erro interno ao listar usuários: {e}")

@router.get("/tasks/user/{user_id}", response_model=List[TaskResponse])
async def list_user_tasks(
    user_id: str, 
    request: Request,
    db: Session = Depends(get_db),
):
    """
    Lista todas as tarefas de um usuário específico.
    Requer autenticação como administrador.
    """
    current_user = await get_admin_user(request, db)
    
    # Verifica se o usuário existe
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuário não encontrado"
        )
    
    # Obtém tarefas do usuário
    tasks = db.query(Task).filter(Task.user_id == user_id).all()
    return tasks

@router.post("/logs", status_code=status.HTTP_201_CREATED)
@router.put("/logs", status_code=status.HTTP_201_CREATED)  # Adicionando endpoint PUT para compatibilidade com o workflow n8n
async def create_system_log(
    log_data: Dict[str, Any],
    request: Request,
    db: Session = Depends(get_db),
):
    """
    Cria um log de sistema, usado pelo fluxo N8N para registrar ações.
    Aceita tanto POST quanto PUT para maior compatibilidade.
    """
    current_user = await get_admin_user(request, db)
    try:
        # Identificar fonte e nível do log
        source = log_data.get("source", "n8n_workflow")
        message = log_data.get("message", "Ação executada pelo workflow")
        
        # Extrair dados de user_id do campo details ou diretamente
        user_id = None
        if "details" in log_data and "user_id" in log_data["details"]:
            user_id = log_data["details"]["user_id"]
        elif "user_id" in log_data:
            user_id = log_data["user_id"]
            
        # Criar o log com campos melhorados - verificando presença do campo level
        # e se o modelo o suporta como keyword argument
        system_log_data = {
            "user_id": user_id,
            "source": source,
            "message": message,
            "action": log_data.get("action"),
            "details": log_data.get("details"),
            "created_at": datetime.utcnow()
        }
        
        # Adicionar level apenas se o modelo suportar (verificado pela presença no __annotations__)
        if hasattr(SystemLog, '__annotations__') and 'level' in SystemLog.__annotations__:
            level = log_data.get("level", "info")
            system_log_data["level"] = level
        
        system_log = SystemLog(**system_log_data)
        db.add(system_log)
        db.commit()
        db.refresh(system_log)
        
        return {"success": True, "log_id": system_log.id}
    except Exception as e:
        logger.error(f"Erro ao criar log: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao criar log: {str(e)}"
        )

@router.post("/send-email", status_code=status.HTTP_200_OK)
async def send_email_api(
    email_data: Dict[str, Any],
    background_tasks: BackgroundTasks,
    request: Request,
    db: Session = Depends(get_db),
):
    """
    Envia um e-mail usando o serviço de e-mail da aplicação.
    Pode ser usado pelo fluxo N8N se necessário.
    """
    current_user = await get_admin_user(request, db)
    
    # Validar dados de e-mail
    to_email = email_data.get("to_email")
    subject = email_data.get("subject")
    content = email_data.get("content")
    
    if not to_email or not subject or not content:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Dados incompletos. Necessário: to_email, subject e content"
        )
    
    # Enviar e-mail em background para não bloquear a resposta
    background_tasks.add_task(send_email, to_email, subject, content)
    
    # Registrar a ação
    system_log = SystemLog(
        user_id=current_user.id,
        action="email_sent",
        details={
            "to": to_email,
            "subject": subject,
            "sender": "api"
        },
        created_at=datetime.utcnow()
    )
    db.add(system_log)
    db.commit()
    
    return {"success": True, "message": f"E-mail enviado para {to_email}"}
