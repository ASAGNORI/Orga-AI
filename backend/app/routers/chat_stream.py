"""
Roteador para comunicação streaming com o Ollama.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from app.database import get_db
from app.services.auth_service import get_current_user
from app.schemas.user import User
from app.models.chat import ChatHistory
from app.schemas.chat import ChatRequest, ChatResponse
from app.services.stream_service import stream_service
from app.services.context_manager import context_manager
import logging
import traceback
from datetime import datetime
import asyncio
from typing import List, Dict, Any
import json

router = APIRouter(prefix="/chat/stream", tags=["chat-stream"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")
logger = logging.getLogger(__name__)

async def handle_stream_error(error: Exception) -> None:
    """Standardized error handling for stream generation"""
    error_details = {
        "error": str(error),
        "type": error.__class__.__name__,
        "traceback": traceback.format_exc()
    }
    logger.error(f"Stream error: {error_details}")
    
    if isinstance(error, HTTPException):
        raise error
    elif "peer closed connection" in str(error).lower():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Connection to AI service was interrupted. Please try again."
        )
    elif isinstance(error, asyncio.TimeoutError):
        raise HTTPException(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT,
            detail="Request timed out. The AI service is taking too long to respond."
        )
    else:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An error occurred: {str(error)}"
        )

@router.post("")
async def chat_stream(
    request: ChatRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Endpoint para streaming de chat com o Ollama.
    Retorna as respostas à medida que são geradas.
    """
    try:
        if not request.message or not request.message.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Message cannot be empty"
            )

        logger.info(f"Received streaming chat request from user {current_user.id}: {request.message}")
        
        # Histórico vazio para máxima performance
        history = []
        
        # Converter histórico para o formato aceito pelo Ollama
        history_tuples = [(h.user_message, h.ai_response) for h in history]
        context_messages = context_manager.optimize_context(history_tuples)
        
        # Adicionar a mensagem atual
        messages = context_messages + [{"role": "user", "content": request.message}]
        
        # Criar função para gerar resposta em streaming
        async def generate_response_stream():
            full_response = ""
            error_occurred = False
            
            try:
                async for content_chunk in stream_service.generate_stream(
                    messages, 
                    user_id=str(current_user.id)
                ):
                    if content_chunk:
                        full_response += content_chunk
                        yield f"data: {content_chunk}\n\n"
                
                # Salvar no histórico apenas se não houve erros
                try:
                    chat_entry = ChatHistory(
                        user_id=current_user.id,
                        user_message=request.message,
                        ai_response=full_response,
                        tags=["streaming"],
                        created_at=datetime.utcnow().isoformat()
                    )
                    db.add(chat_entry)
                    db.commit()
                    logger.info(f"Saved streaming conversation to history, id: {chat_entry.id}")
                except Exception as db_error:
                    logger.error(f"Failed to save chat history: {str(db_error)}")
                    db.rollback()
                
                # Sinal de finalização bem-sucedida
                yield "data: [DONE]\n\n"
                
            except Exception as stream_error:
                error_occurred = True
                logger.error(f"Error during stream generation: {str(stream_error)}")
                error_msg = {
                    "error": str(stream_error),
                    "type": "stream_error"
                }
                yield f"data: {json.dumps(error_msg)}\n\n"
                yield "data: [ERROR]\n\n"
                await handle_stream_error(stream_error)
        
        # Retornar streaming response
        return StreamingResponse(
            generate_response_stream(),
            media_type="text/event-stream"
        )
        
    except Exception as e:
        await handle_stream_error(e)
