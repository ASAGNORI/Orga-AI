"""
Serviço para gerenciar o streaming de respostas do Ollama.
Integrado com reconhecimento de intenções e contexto RAG.
"""
import aiohttp
import json
import logging
import asyncio
from typing import Dict, AsyncIterator, Any, List, Tuple, Optional
from fastapi import HTTPException, status
import os
import time

from app.services.intent_recognizer import intent_recognizer
from app.services.vector_store_service import vector_store_service

logger = logging.getLogger(__name__)

class StreamService:
    """
    Serviço para gerenciar o streaming de respostas do Ollama.
    Implementa comunicação direta com a API do Ollama para streaming,
    com melhorias de reconhecimento de intenção e RAG.
    """
    
    def _clean_stream_content(self, content: str) -> str:
        """
        Limpa o conteúdo da resposta para remover caracteres repetidos e problemas de formatação.
        
        Args:
            content: O conteúdo da resposta a ser limpo
            
        Returns:
            Conteúdo limpo
        """
        if not content:
            return content
            
        # Remover completamente todos os asteriscos (principal problema relatado)
        content = content.replace("*", "")
            
        # Fix repeated backticks (code formatting issue)
        while "```" in content:
            content = content.replace("```", "")
        while "``" in content:
            content = content.replace("``", "")
        while "`" in content:
            content = content.replace("`", "")
            
        # Fix other common markdown issues
        while "__" in content:
            content = content.replace("__", "")
        while "_" in content:
            content = content.replace("_", "")
            
        # Remove any repeated punctuation
        for char in [".", "!", "?"]:
            while char * 3 in content:
                content = content.replace(char * 3, char * 2)
        
        return content
    
    def __init__(self): 
        # Forçar a URL para o serviço Ollama dentro da rede Docker
        self.ollama_api_url = "http://ollama:11434"
        logger.info(f"Stream Service usando URL fixa do Ollama: {self.ollama_api_url}")
            
        self.model = os.getenv("OLLAMA_MODEL", "optimized-gemma3") 
        logger.info(f"Stream Service usando modelo: {self.model}")
        
        # Lista de modelos de fallback, do mais leve para o mais pesado
        # Idealmente, o modelo principal (self.model) deve ser o primeiro aqui.
        self.fallback_models = [
            self.model, # Garante que o modelo principal seja tentado primeiro
            "gemma3:1b", # Um fallback razoável e leve
            "phi:latest",
            "mistral:latest", 
            "llama2:7b",
            "gemma:2b"
        ]
        # Remover duplicatas caso self.model seja igual a um dos fallbacks já listados
        self.fallback_models = list(dict.fromkeys(self.fallback_models))

        # Retry configuration
        self.max_retries = 3
        self.base_timeout = 60.0
        self.backoff_factor = 1.5

    def process_intent(self, message: str) -> Tuple[bool, Optional[Dict[str, Any]], Optional[str]]:
        """
        Processa a intenção da mensagem do usuário.
        
        Args:
            message: A mensagem do usuário
            
        Returns:
            Tupla com: (deve_processar_agora, info_intenção, resposta_rápida)
        """
        try:
            has_intent, intent_info = intent_recognizer.process_message(message)
            
            if has_intent and intent_info and intent_info.get("confidence", 0) > 0.85:
                # Para intenções simples, responder diretamente
                if intent_info["intent"] in ["saudação", "despedida", "agradecimento", "ajuda"]:
                    return True, intent_info, intent_info.get("response")
            
            # Para outras intenções, apenas retornar a informação mas deixar o LLM processar
            if has_intent:
                return False, intent_info, None
                
            return False, None, None
        except Exception as e:
            logger.error(f"Erro ao processar intenção: {str(e)}")
            return False, None, None
    
    def get_enhanced_messages(self, 
                             original_messages: List[Dict[str, str]], 
                             user_id: Optional[str] = None,
                             user_message: Optional[str] = None) -> List[Dict[str, str]]:
        """
        Melhora as mensagens com contexto de RAG quando possível.
        
        Args:
            original_messages: Lista original de mensagens
            user_id: ID do usuário (opcional)
            user_message: Mensagem do usuário (opcional)
            
        Returns:
            Lista de mensagens melhorada
        """
        if not user_id or not user_message or not hasattr(vector_store_service, 'get_formatted_context'):
            return original_messages
        
        try:
            # Obter contexto relevante com base na consulta
            rag_context = vector_store_service.get_formatted_context(user_id, user_message)
            
            if not rag_context:
                return original_messages
                
            # Encontrar a última mensagem do usuário
            enhanced_messages = list(original_messages)
            for i in range(len(enhanced_messages) - 1, -1, -1):
                if enhanced_messages[i].get("role") == "user":
                    # Modificar a última mensagem do usuário para incluir o contexto RAG
                    enhanced_messages[i]["content"] = f"{rag_context}\n\nPergunta: {enhanced_messages[i]['content']}"
                    break
                    
            return enhanced_messages
        except Exception as e:
            logger.error(f"Erro ao melhorar mensagens com RAG: {str(e)}")
            return original_messages
        
    async def generate_stream(self, 
                              messages: List[Dict[str, str]], 
                              user_id: Optional[str] = None) -> AsyncIterator[str]:
        """
        Gera um stream de respostas diretamente do Ollama.
        Aplica reconhecimento de intenção e contexto RAG quando possível.
        
        Args:
            messages: Lista de mensagens para enviar ao Ollama
            user_id: ID do usuário (opcional, para melhorias de RAG)
            
        Returns:
            Um iterador assíncrono que produz partes da resposta
        """
        start_time = time.time()
        
        try:
            # Extrair e validar a última mensagem do usuário para processamento
            user_message = None
            for msg in reversed(messages):
                if msg.get("role") == "user":
                    user_message = msg.get("content")
                    if not user_message:
                        raise HTTPException(
                            status_code=status.HTTP_400_BAD_REQUEST,
                            detail="Mensagem vazia encontrada"
                        )
                    break
            
            if not user_message:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Nenhuma mensagem do usuário encontrada"
                )
        
            # Verificar se temos uma intenção de resposta rápida
            should_respond_directly, intent_info, quick_response = self.process_intent(user_message)
            
            # Para intenções simples, podemos responder diretamente sem chamar o LLM
            if should_respond_directly and quick_response:
                logger.info(f"Respondendo diretamente via intenção: {intent_info['intent']}")
                yield quick_response
                return
        
            # Melhorar as mensagens com contexto RAG se possível
            enhanced_messages = messages
            if user_id:
                enhanced_messages = self.get_enhanced_messages(messages, user_id, user_message)
                if len(enhanced_messages) != len(messages):
                    logger.info("Mensagens melhoradas com contexto RAG")
        
            # Construir o payload para a API do Ollama
            system_message = {
                "role": "system", 
                "content": (
                    "Você é um assistente virtual útil. "
                    "Mantenha suas respostas claras e em um formato natural. "
                    "IMPORTANTE: Não use formatação markdown como asteriscos ou backticks para ênfase. "
                    "Use apenas texto simples sem caracteres especiais para formatação. "
                    "Não repita caracteres como asteriscos ou backticks."
                )
            }
            
            data = {
                "model": self.model,
                "messages": [system_message] + enhanced_messages,
                "stream": True,
                "options": {
                    "num_ctx": 2048,  # Contexto reduzido para performance
                    "temperature": 0.7,
                    "num_thread": 4,
                    "num_gpu": 1,
                    "stop": ["[DONE]", "[ERROR]"],
                    "repeat_penalty": 1.3,  # Increased to prevent repetition
                    "num_predict": 512,
                    "top_k": 40,
                    "top_p": 0.9
                }
            }
        
            async with aiohttp.ClientSession(
                timeout=aiohttp.ClientTimeout(total=self.base_timeout),
                headers={"Connection": "close"}
            ) as session:
                endpoint = "/api/chat"
                full_url = f"{self.ollama_api_url}{endpoint}"
                logger.info(f"Making request to: {full_url}")
                
                empty_responses = 0
                async with session.post(
                    full_url,
                    json=data,
                    headers={"Connection": "close"}
                ) as response:
                    if response.status != 200:
                        error_text = await response.text()
                        if response.status == 503:
                            raise HTTPException(
                                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                                detail="Serviço de IA temporariamente indisponível"
                            )
                        elif response.status == 429:
                            raise HTTPException(
                                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                                detail="Muitas requisições. Tente novamente em alguns instantes"
                            )
                        else:
                            raise HTTPException(
                                status_code=response.status,
                                detail=f"Erro do serviço de IA: {error_text}"
                            )
                    
                    # Process streaming response
                    try:
                        async for line in response.content:
                            if not line:
                                empty_responses += 1
                                if empty_responses > 5:
                                    raise HTTPException(
                                        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                                        detail="Muitas respostas vazias do serviço"
                                    )
                                continue
                            
                            try:
                                json_line = json.loads(line)
                                if 'error' in json_line:
                                    raise HTTPException(
                                        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                                        detail=f"Erro do serviço de IA: {json_line['error']}"
                                    )
                                    
                                if 'message' in json_line and 'content' in json_line['message']:
                                    content = json_line['message']['content']
                                    if content:
                                        # Clean up content - remove repeated asterisks and formatting issues
                                        clean_content = self._clean_stream_content(content)
                                        empty_responses = 0
                                        yield clean_content
                                elif 'done' in json_line and json_line['done']:
                                    return
                            except json.JSONDecodeError:
                                logger.warning(f"Linha inválida no stream: {line}")
                                continue
                            except Exception as e:
                                logger.error(f"Erro processando linha do stream: {str(e)}")
                                raise HTTPException(
                                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                                    detail=f"Erro processando resposta: {str(e)}"
                                )
                    except Exception as e:
                        logger.error(f"Error processing stream: {str(e)}")
                        raise HTTPException(
                            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                            detail=f"Error processing response stream: {str(e)}"
                        )
                    
        except HTTPException:
            raise  # Re-raise HTTP exceptions
        except asyncio.TimeoutError:
            logger.error(f"Timeout após {time.time() - start_time:.2f}s")
            raise HTTPException(
                status_code=status.HTTP_504_GATEWAY_TIMEOUT,
                detail="Tempo limite excedido. O serviço está demorando muito para responder"
            )
        except aiohttp.ClientError as e:
            logger.error(f"Erro de conexão: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Erro de conexão com o serviço de IA"
            )
        except Exception as e:
            logger.error(f"Erro inesperado: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Erro interno do servidor: {str(e)}"
            )

# Instância global para uso em toda a aplicação
stream_service = StreamService()
