"""
Serviço de fila para gerenciar requisições ao LLM.
Usado para evitar sobrecarga e permitir processamento paralelo.
"""
import asyncio
import logging
from typing import Dict, List, Any, Callable, Awaitable, Optional
import time
import uuid

logger = logging.getLogger(__name__)

class QueueService:
    """
    Implementa um sistema de fila para processar requisições de chat.
    
    Características:
    - Processamento assíncrono de requisições
    - Limite de concorrência para o Ollama
    - Sistema de prioridade para requisições
    - Timeout para evitar esperas infinitas
    """
    
    def __init__(self, max_concurrent: int = 2, timeout_seconds: int = 60):
        """
        Inicializa o serviço de fila.
        
        Args:
            max_concurrent: Número máximo de requisições concorrentes
            timeout_seconds: Tempo máximo para processar uma requisição (segundos)
        """
        self.semaphore = asyncio.Semaphore(max_concurrent)
        self.timeout = timeout_seconds
        self.pending_tasks = {}  # ID da tarefa -> task
        self.results = {}        # ID da tarefa -> resultado
        
    async def enqueue_task(self, 
                        handler: Callable[[Dict[str, Any]], Awaitable[Any]], 
                        params: Dict[str, Any]) -> str:
        """
        Adiciona uma tarefa à fila e retorna um ID para consulta posterior.
        
        Args:
            handler: Função assíncrona que processa a requisição
            params: Parâmetros para passar ao handler
            
        Returns:
            ID da tarefa para consulta posterior
        """
        task_id = str(uuid.uuid4())
        logger.info(f"Enfileirada nova tarefa {task_id}")
        
        # Criar e armazenar a tarefa
        task = asyncio.create_task(self._execute_task(handler, params, task_id))
        self.pending_tasks[task_id] = task
        
        return task_id
        
    async def _execute_task(self, 
                         handler: Callable[[Dict[str, Any]], Awaitable[Any]], 
                         params: Dict[str, Any],
                         task_id: str) -> None:
        """
        Executa a tarefa quando um slot estiver disponível.
        
        Args:
            handler: Função assíncrona que processa a requisição
            params: Parâmetros para passar ao handler
            task_id: ID da tarefa
        """
        async with self.semaphore:
            start_time = time.time()
            logger.info(f"Iniciando processamento da tarefa {task_id}")
            
            try:
                # Executar a tarefa com timeout
                result = await asyncio.wait_for(
                    handler(params),
                    timeout=self.timeout
                )
                
                # Armazenar resultado
                self.results[task_id] = {
                    "success": True,
                    "result": result,
                    "elapsed": time.time() - start_time
                }
                
                logger.info(f"Tarefa {task_id} completada em {time.time() - start_time:.2f}s")
                
            except asyncio.TimeoutError:
                logger.error(f"Timeout na tarefa {task_id} após {self.timeout}s")
                self.results[task_id] = {
                    "success": False,
                    "error": "Timeout excedido",
                    "elapsed": time.time() - start_time
                }
                
            except Exception as e:
                logger.error(f"Erro na tarefa {task_id}: {str(e)}")
                self.results[task_id] = {
                    "success": False,
                    "error": str(e),
                    "elapsed": time.time() - start_time
                }
                
            finally:
                # Remover da lista de pendentes
                if task_id in self.pending_tasks:
                    del self.pending_tasks[task_id]
    
    async def get_task_result(self, task_id: str, wait: bool = True) -> Optional[Dict[str, Any]]:
        """
        Obtém o resultado de uma tarefa pelo ID.
        
        Args:
            task_id: ID da tarefa
            wait: Se deve esperar a tarefa completar
            
        Returns:
            Resultado da tarefa ou None se não encontrada
        """
        # Verificar se a tarefa já está concluída
        if task_id in self.results:
            result = self.results[task_id]
            # Limpar resultados antigos para economizar memória
            del self.results[task_id]
            return result
            
        # Verificar se a tarefa está pendente
        if task_id in self.pending_tasks:
            if wait:
                # Esperar a tarefa completar
                try:
                    await self.pending_tasks[task_id]
                    return self.results.pop(task_id, None)
                except Exception:
                    logger.error(f"Erro ao aguardar tarefa {task_id}")
                    return None
            else:
                # Retornar status em andamento
                return {
                    "status": "processing",
                    "message": "A tarefa está sendo processada"
                }
                
        # Tarefa não encontrada
        return None

# Instância global para uso em toda a aplicação
queue_service = QueueService(max_concurrent=2, timeout_seconds=60)
