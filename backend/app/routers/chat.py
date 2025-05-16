from fastapi import APIRouter, HTTPException, Depends
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from sqlalchemy import or_, text
from app.services.ai_service import ai_service
from app.database import get_db
from app.services.auth_service import get_current_user
from app.services.vector_store_service import vector_store_service
from app.services.intent_recognizer import intent_recognizer
from app.schemas.user import User
from app.models.chat import ChatHistory, ChatPrompt
from app.models.task_model import Task as TaskModel
from app.schemas.chat import ChatRequest, ChatResponse, ChatHistoryEntry, ChatPromptRequest, ChatPromptResponse
import logging
from datetime import datetime 
import uuid
import time
from typing import List, Dict, Any

router = APIRouter(prefix="/chat", tags=["chat"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")
logger = logging.getLogger(__name__)

@router.post("", response_model=ChatResponse)
async def chat(
    request: ChatRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        start_time = time.time()
        message = request.message
        logger.info(f"Received chat request from user {current_user.id}: {message[:100]}...")
        
        # Step 1: Check for cached responses or intent-based quick replies
        has_intent, intent_info = intent_recognizer.process_message(message)
        
        # Step 2: Update the user's vector store asynchronously (if it hasn't been updated recently)
        try:
            # Atualizar apenas se o cache estiver muito velho ou se for uma mensagem longa
            # (mensagens longas têm mais conteúdo a indexar)
            force_update = len(message) > 200
            vector_store_service.update_user_vectorstore(str(current_user.id), db, force=force_update)
        except Exception as ve:
            logger.warning(f"Error updating vector store: {str(ve)}")
        
        # Step 3: Get conversation history with more context
        history = db.query(ChatHistory).filter(
            ChatHistory.user_id == current_user.id
        ).order_by(ChatHistory.created_at.asc()).limit(15).all()  # Order by ASC para manter ordem cronológica
        
        # Não precisa mais reverter pois já está na ordem correta
        # Validar se temos histórico
        if not history:
            history = []
        
        # Step 4: Build enhanced context with history, tasks and user data
        # Buscar tarefas do usuário
        tasks = db.query(TaskModel).filter(
            TaskModel.user_id == current_user.id,
            TaskModel.status != 'done'
        ).order_by(TaskModel.due_date.desc()).all()
        
        task_context = [
            {
                "id": str(t.id),
                "title": t.title,
                "status": t.status,
                "priority": t.priority,
                "due_date": t.due_date.isoformat() if t.due_date else None
            } for t in tasks
        ]
        
        context = {
            "user": {"id": current_user.id, "email": current_user.email},
            "history": [(h.user_message, h.ai_response) for h in history],
            "tasks": task_context,
            "session": {"db": db}
        }
        
        # Step 5: Process message using our hybrid system (RAG + Intent + LLM)
        history_tuples = [(h.user_message, h.ai_response) for h in history]
        reply, metadata = ai_service.process_message(
            message=message,
            history=history_tuples,
            user_context=context,  # Usando o contexto completo construído acima
            user_id=str(current_user.id)
        )
        
        # Extract suggested tags based on intent and content
        suggested_tags = []
        
        # Add tags based on intent if detected
        if metadata.get("used_intent") and metadata.get("intent_type"):
            suggested_tags.append(metadata.get("intent_type"))
            
        # Add RAG tag if used
        if metadata.get("used_rag"):
            suggested_tags.append("contexto")
            
        # Add some basic classification tags
        if "tarefa" in message.lower() or "task" in message.lower():
            suggested_tags.append("tarefa")
            
        if "projeto" in message.lower() or "project" in message.lower():
            suggested_tags.append("projeto")
            
        # Ensure we have at least one tag
        if not suggested_tags:
            suggested_tags = ["chat"]
        
        # Save to history with additional metadata
        chat_entry = ChatHistory(
            user_id=current_user.id,
            user_message=message,
            ai_response=reply,
            tags=suggested_tags,
            created_at=datetime.utcnow().isoformat(),
            response_metadata=metadata
        )
        db.add(chat_entry)
        db.commit()
        
        # Calculate total processing time
        elapsed_time = time.time() - start_time
        logger.info(f"Generated reply for user {current_user.id} in {elapsed_time:.2f}s: {reply[:100]}...")
        
        return ChatResponse(
            message=reply,
            suggestions=suggested_tags,
            context={
                "history_id": str(chat_entry.id),
                "processing_info": metadata
            }
        )
        
    except Exception as e:
        logger.error(f"Error in chat endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/history", response_model=list[ChatHistoryEntry])
async def get_chat_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Buscar o histórico do chat do usuário
    history_records = db.query(ChatHistory).filter(
        ChatHistory.user_id == current_user.id
    ).order_by(ChatHistory.created_at.desc()).limit(20).all()
    
    # Converter os registros para o formato esperado pelo esquema
    # Convertendo explicitamente datetime para string ISO
    formatted_history = []
    for record in history_records:
        formatted_record = {
            "id": record.id,
            "user_id": record.user_id,
            "user_message": record.user_message,
            "ai_response": record.ai_response,
            "tags": record.tags or [],
            "created_at": record.created_at.isoformat() if record.created_at else datetime.utcnow().isoformat()
        }
        formatted_history.append(formatted_record)
    
    return formatted_history

@router.get("/tags/common", response_model=list[str])
async def get_common_tags(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Get most used tags from user's chat history
    history = db.query(ChatHistory).filter(
        ChatHistory.user_id == current_user.id
    ).order_by(ChatHistory.created_at.desc()).limit(100).all()
    
    # Extract and count tags
    tag_counts = {}
    for entry in history:
        for tag in entry.tags or []:
            tag_counts[tag] = tag_counts.get(tag, 0) + 1
    
    # Return top 10 most common tags
    common_tags = sorted(tag_counts.items(), key=lambda x: x[1], reverse=True)[:10]
    return [tag for tag, _ in common_tags] or ["work", "personal", "urgent", "meeting", "followup"]

@router.delete("/history", status_code=204)
async def delete_chat_history(
    request: dict,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Exclui mensagens específicas do histórico de chat pelo ID.
    Suporta tanto IDs completos no formato UUID quanto IDs parciais/truncados.
    Apenas as mensagens do usuário atual podem ser excluídas.
    """
    try:
        # Verificar se o corpo da requisição contém IDs a serem excluídos
        if not request.get("ids") or not isinstance(request["ids"], list):
            raise HTTPException(status_code=400, detail="Lista de IDs é obrigatória")
            
        # Verificar se há mensagens para excluir
        if len(request["ids"]) == 0:
            return
        
        # Obter IDs das mensagens
        message_ids = request["ids"]
        
        # Log da operação
        logger.info(f"User {current_user.id} requested to delete {len(message_ids)} chat history entries: {message_ids}")
        
        deleted_count = 0
        for msg_id in message_ids:
            try:
                # Primeiro tenta encontrar a mensagem com ID exato (se for um UUID completo válido)
                query = db.query(ChatHistory).filter(
                    ChatHistory.user_id == current_user.id
                )
                
                # Tenta converter para UUID se possível (para IDs completos)
                try:
                    valid_uuid = uuid.UUID(msg_id)
                    chat_message = query.filter(ChatHistory.id == valid_uuid).first()
                except ValueError:
                    # Se não for um UUID válido, procura por mensagens cujo ID começa com o valor fornecido
                    # Usamos SQL raw para evitar problemas com o cast
                    sql = text(f"SELECT * FROM chat_history WHERE user_id = :user_id AND id::text LIKE :pattern LIMIT 1")
                    result = db.execute(
                        sql, 
                        {"user_id": str(current_user.id), "pattern": f"{msg_id}%"}
                    ).fetchone()
                    
                    if result:
                        chat_message = db.query(ChatHistory).filter(ChatHistory.id == result[0]).first()
                    else:
                        chat_message = None
                
                if chat_message:
                    db.delete(chat_message)
                    deleted_count += 1
                else:
                    logger.warning(f"Message with ID {msg_id} not found or doesn't belong to user {current_user.id}")
            
            except Exception as msg_error:
                logger.error(f"Error processing message ID {msg_id}: {str(msg_error)}")
                continue
        
        # Commit das alterações
        db.commit()
        logger.info(f"Successfully deleted {deleted_count} chat history entries for user {current_user.id}")
        
        return None
        
    except Exception as e:
        logger.error(f"Error deleting chat history: {str(e)}")
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Erro ao excluir mensagens: {str(e)}")

@router.post("/prompts", response_model=ChatPromptResponse)
async def create_prompt(
    request: ChatPromptRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Create a new saved prompt. These prompts can be reused in chat conversations.
    """
    try:
        # Create new prompt with enhanced fields
        new_prompt = ChatPrompt(
            user_id=current_user.id,
            text=request.text,
            title=request.title or "Prompt sem título",
            category=request.category,
            tags=request.tags or []
        )
        db.add(new_prompt)
        db.commit()
        db.refresh(new_prompt)
        
        logger.info(f"New prompt created: {new_prompt.id} by user {current_user.id}")
        
        # Return with enhanced fields
        # Garantir que created_at é um datetime válido antes de chamar isoformat()
        created_at_str = datetime.utcnow().isoformat() if new_prompt.created_at is None else new_prompt.created_at.isoformat()
        
        return {
            "id": new_prompt.id,
            "text": new_prompt.text,
            "title": new_prompt.title,
            "category": new_prompt.category, 
            "tags": new_prompt.tags,
            "created_at": created_at_str
        }
        
    except Exception as e:
        logger.error(f"Error creating prompt: {str(e)}")
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/prompts", response_model=List[ChatPromptResponse])
async def list_prompts(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    List all saved prompts for the current user.
    """
    try:
        # Filter prompts by current user
        prompts = db.query(ChatPrompt)\
            .filter(ChatPrompt.user_id == current_user.id)\
            .order_by(ChatPrompt.created_at.desc())\
            .all()
        
        result = []
        for prompt in prompts:
            # Garantir que created_at é um datetime válido antes de chamar isoformat()
            created_at_str = datetime.utcnow().isoformat() if prompt.created_at is None else prompt.created_at.isoformat()
            
            result.append({
                "id": prompt.id,
                "text": prompt.text,
                "title": prompt.title,
                "category": prompt.category, 
                "tags": prompt.tags or [],
                "created_at": created_at_str
            })
        
        return result
        
    except Exception as e:
        logger.error(f"Error listing prompts: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/prompts/{prompt_id}", response_model=ChatPromptResponse)
async def get_prompt(
    prompt_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get a specific saved prompt by ID. Only prompts owned by the current user can be accessed.
    """
    prompt = db.query(ChatPrompt).filter(ChatPrompt.id == prompt_id).first()
    if not prompt:
        raise HTTPException(status_code=404, detail="Prompt não encontrado")
        
    # Garantir que created_at é um datetime válido antes de chamar isoformat()
    created_at_str = datetime.utcnow().isoformat() if prompt.created_at is None else prompt.created_at.isoformat()
    
    return {
        "id": prompt.id,
        "text": prompt.text,
        "title": prompt.title,
        "category": prompt.category,
        "tags": prompt.tags or [],
        "created_at": created_at_str
    }

@router.delete("/prompts/{prompt_id}", status_code=204)
async def delete_prompt(
    prompt_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Delete a saved prompt by ID.
    """
    try:
        prompt = db.query(ChatPrompt).filter(ChatPrompt.id == prompt_id).first()
        if not prompt:
            raise HTTPException(status_code=404, detail="Prompt não encontrado")
            
        db.delete(prompt)
        db.commit()
        
        logger.info(f"Prompt {prompt_id} deleted")
        
        return None
        
    except Exception as e:
        logger.error(f"Error deleting prompt: {str(e)}")
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))