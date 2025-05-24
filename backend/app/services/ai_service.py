import os
import json
import logging
import requests
import time
import numpy as np
import uuid
from typing import Optional, Any, Dict, List, Tuple

from langchain_core.prompts import PromptTemplate
from langchain_core.runnables import RunnableLambda, RunnableMap
from langchain_core.messages import AIMessage, SystemMessage, HumanMessage
from langchain_ollama import ChatOllama

from app.services.context_manager import context_manager
from app.services.vector_store_service import vector_store_service 
from app.services.intent_recognizer import intent_recognizer

# Configuração de logging
logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

class AIService:
    def _clean_response(self, response: str) -> str:
        """Remove repetitive markdown/formatting artifacts from the response."""
        if not response:
            return response
            
        # Remove all asterisks completely (main reported problem)
        response = response.replace("*", "")
        
        # Remove all backticks
        response = response.replace("`", "")
        
        # Remove underscore formatting
        response = response.replace("_", "")
        
        # Remove phrase that might be included in template
        response = response.replace("Para ajudar você da melhor forma possível, vou levar em consideração suas tarefas e preferências.", "")
        
        # Remove multiple asterisks that appear together
        response = response.replace("** ** **", "")
        
        import re
        # Remove code blocks entirely
        response = re.sub(r'```[\s\S]*?```', '', response)
        
        # Remove backtick blocks and their content
        response = re.sub(r'`[^`]*`', '', response)
        
        # Clean up excessive newlines
        response = re.sub(r'\n\s*\n', '\n\n', response)
        response = re.sub(r'\n{3,}', '\n\n', response)
        
        # Clean up extra whitespace
        response = re.sub(r'\s+', ' ', response).strip()
            
        return response

    def __init__(self):
        self.ollama_api_url = "http://ollama:11434"
        self.ollama_model = os.environ.get("OLLAMA_MODEL_CHAT", "optimized-gemma3")
        self.llm = None
        self.max_retries = 3
        self.request_timeout = 120.0  # 2 minutes timeout
        self.backoff_factor = 1.5
        self.session = None
        
        # Models in order of preference (from heaviest to lightest)
        self.fallback_models = [
            self.ollama_model,
        ]
        
        # Default system message to prevent repetition/formatting issues
        self.default_system_message = {
            "role": "system",
            "content": "You are a helpful assistant. Keep your responses clear and natural. Do not repeat formatting characters or use unnecessary markdown."
        }
        
        # Initialize
        self._initialize()

    def _initialize(self):
        """Initialize the service with retry logic"""
        for attempt in range(self.max_retries):
            try:
                available_models = self._get_available_models()
                if self._initialize_llm_with_fallback(available_models):
                    return
            except Exception as e:
                logger.error(f"Failed to initialize on attempt {attempt + 1}: {e}")
                time.sleep(min(10 * (self.backoff_factor ** attempt), 30))
        
        logger.error("All initialization attempts failed")

    def _get_available_models(self) -> List[Dict[str, Any]]:
        """Get available models with improved error handling"""
        for attempt in range(self.max_retries):
            try:
                endpoint = "/api/tags"
                timeout = min(10 * (self.backoff_factor ** attempt), 30)
                response = requests.get(
                    f"{self.ollama_api_url}{endpoint}",
                    timeout=timeout,
                    headers={"Connection": "close"}  # Prevent connection pooling issues
                )
                
                if response.status_code == 200:
                    return response.json().get('models', [])
                
                if response.status_code >= 500:
                    logger.warning(f"Attempt {attempt + 1}/{self.max_retries}: Ollama server error")
                    time.sleep(timeout * 0.5)
                    continue
                    
                logger.error(f"Error getting models. Status: {response.status_code}")
                return []
                
            except (requests.Timeout, requests.ConnectionError) as e:
                logger.warning(f"Attempt {attempt + 1}/{self.max_retries}: Connection error: {e}")
                if attempt < self.max_retries - 1:
                    time.sleep(timeout * 0.5)
                continue
                
            except Exception as e:
                logger.error(f"Error getting models: {e}")
                return []
        
        logger.error("All attempts to get models failed")
        return []

    def _initialize_llm_with_fallback(self, available_models):
        """Initialize LLM with proper cleanup and connection settings"""
        if not available_models:
            logger.error("No models available")
            return False

        available_model_names = {m['name'].split(':')[0] for m in available_models}
        
        for model in self.fallback_models:
            model_name = model.split(':')[0]
            if model_name not in available_model_names:
                continue
                
            try:
                # Cleanup any existing LLM instance
                if self.llm:
                    try:
                        self.llm = None
                    except Exception as e:
                        logger.warning(f"Error cleaning up old LLM: {e}")

                self.llm = ChatOllama(
                    model=model,
                    base_url=self.ollama_api_url,
                    num_ctx=2048,
                    num_gpu=1,
                    num_thread=4,
                    temperature=0.1,
                    num_predict=512,
                    top_k=40,
                    top_p=0.9,
                    repeat_penalty=1.1,
                    seed=42,
                    timeout=self.request_timeout,
                    streaming=False,  # Disable streaming to avoid timeouts
                    headers={"Connection": "close"}  # Prevent connection pooling issues
                )
                self.ollama_model = model
                logger.info(f"LLM initialized with model: {model}")
                return True
            except Exception as e:
                logger.error(f"Error initializing model {model}: {e}")
        
        logger.error("Failed to initialize any model")
        self.llm = None
        return False

    def process_message(self,
                       message: str,
                       history: List[Tuple[str, str]] = [],
                       user_context: Optional[Dict[str, Any]] = None,
                       user_id: Optional[str] = None) -> Tuple[str, Dict[str, Any]]:
        metadata = {
            "start_time": time.time(),
            "processing_steps": [],
            "used_model": self.ollama_model,
            "used_rag": False,
            "used_intent": False,
            "retries": 0,
            "error": None
        }

        try:
            if not message.strip():
                metadata["processing_steps"].append("empty_message")
                return "Por favor, digite uma mensagem.", metadata
            
            # Check intent
            has_intent, intent_info = intent_recognizer.process_message(message)
            metadata["intent_detected"] = has_intent
            
            if has_intent and intent_info.get("response"):
                metadata["used_intent"] = True
                metadata["intent_type"] = intent_info["intent"]
                metadata["processing_steps"].append("intent_response")
                return intent_info["response"], metadata
            
            # Check LLM availability
            if not self.llm:
                metadata["error"] = "LLM unavailable"
                return "AI service temporarily unavailable.", metadata
            
            # --- FORÇAR SYSTEM PROMPT E CONTEXTO ---
            system_prompt = (
                "Você é um assistente de produtividade. Sempre responda com base nas tarefas e projetos abaixo, "
                "gerando um texto motivacional, prático e personalizado. Se não houver tarefas, incentive o usuário a planejar o dia. "
                "Use listas HTML (<ul>, <li>) para tarefas e parágrafos (<p>) para mensagens. Seja sempre positivo e prático."
            )
            context_text = None
            if user_context and user_context.get("tasks"):
                tasks = user_context["tasks"]
                if tasks:
                    context_text = "Minhas tarefas atuais:\n" + "\n".join([
                        f"- {t['title']} (Prioridade: {t.get('priority', '-')}, Status: {t.get('status', '-')}, Vencimento: {t.get('due_date', '-')})"
                        for t in tasks
                    ])
            if user_context and user_context.get("projects"):
                projects = user_context["projects"]
                if projects:
                    if not context_text:
                        context_text = ""
                    context_text += "\nMeus projetos ativos:\n" + "\n".join([
                        f"- {p['title']} (Status: {p.get('status', '-')})" + (f" - {p.get('description', '')}" if p.get('description') else "")
                        for p in projects
                    ])
            if not context_text:
                context_text = "Não há tarefas ou projetos cadastrados. Sugira ações úteis para organização pessoal."
            # Prompt final
            prompt = f"{system_prompt}\n\n{context_text}\n\nSolicitação: {message.strip()}"
            logger.info(f"[AI SERVICE] Prompt final enviado ao modelo:\n{prompt}")

            chain_history = []
            
            # Add limited history
            for h_message, h_response in (history[-5:] if history else []):
                chain_history.extend([
                    {"role": "user", "content": h_message},
                    {"role": "assistant", "content": h_response}
                ])

            # Process response with retries
            start_time = time.time()
            response = None
            last_error = None

            for attempt in range(self.max_retries):
                try:
                    metadata["retries"] = attempt
                    
                    ai_message = self.llm.invoke(
                        prompt,
                        config={
                            "message_history": chain_history,
                            "timeout": self.request_timeout * (1 + attempt * 0.5),  # Increase timeout with each attempt
                            "headers": {"Connection": "close"}  # Prevent connection issues
                        }
                    )
                    
                    # Extract response
                    if isinstance(ai_message, AIMessage):
                        response = ai_message.content
                    elif hasattr(ai_message, 'content'):
                        response = ai_message.content
                    else:
                        response = str(ai_message)
                    
                    # Clean up any repeated markdown or formatting artifacts using both internal and advanced cleaner
                    response = self._clean_response(response)
                    
                    # Apply advanced cleaning from ollama_cleaner utility
                    from app.utils.ollama_cleaner import clean_ollama_response
                    response = clean_ollama_response(response)
                    
                    break  # Success
                    
                except Exception as e:
                    last_error = str(e)
                    logger.warning(f"Attempt {attempt + 1}/{self.max_retries} failed: {e}")
                    
                    if "peer closed connection" in str(e).lower() or "timeout" in str(e).lower():
                        wait_time = self.backoff_factor ** attempt
                        time.sleep(min(wait_time, 10))
                        continue
                    else:
                        raise
            
            if response is None:
                raise Exception(f"All attempts failed. Last error: {last_error}")
            
            # Update metadata
            processing_time = time.time() - start_time
            metadata["processing_time"] = processing_time
            metadata["response_length"] = len(response.split())
            
            return response, metadata
            
        except Exception as e:
            logger.error(f"Error processing message: {e}")
            metadata["error"] = str(e)
            metadata["processing_time"] = time.time() - metadata["start_time"]
            return "An error occurred while processing your message.", metadata

    def _get_default_suggestions(self):
        return {
            "context": "sem contexto",
            "category": "geral", 
            "priority": "média",
            "risk": "baixo"
        }
    
    def suggest_task_attributes(self, task_description):
        if not self.llm:
            return self._get_default_suggestions()
        
        system_prompt = """
        Você é um assistente especialista em análise de tarefas.
        Analise a tarefa e sugira atributos no formato JSON:
        {
            "context": "...",
            "category": "...",
            "priority": "...",
            "risk": "..."
        }
        """
        
        try:
            response = self.llm.invoke([
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": task_description}
            ])
            
            if isinstance(response, str):
                return json.loads(response)
            elif isinstance(response, dict):
                return response
            else:
                return self._get_default_suggestions()
                
        except Exception as e:
            logger.error(f"Erro ao sugerir atributos: {e}")
            return self._get_default_suggestions()

# Instâncias globais
ai_service = AIService()

# RunnableMap
app = RunnableMap({
    "response": lambda x: ai_service.process_message(
        message=x.get('message'),
        history=x.get('context', {}).get('history', []),
        user_context=x.get('context'),
        user_id=x.get('context', {}).get('user', {}).get('id')
    ),
    "suggest": lambda x: ai_service.suggest_task_attributes(x.get('message')),
    "context": lambda x: {
        "tasks": x.get('context', {}).get('tasks', []),
        "history": x.get('context', {}).get('history', []),
        "user": x.get('context', {}).get('user', {})
    }
})
