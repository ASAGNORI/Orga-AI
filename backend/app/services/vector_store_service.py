"""
Serviço para gerenciar o armazenamento e recuperação de embeddings de vetores.
Implementa um sistema de RAG (Retrieval Augmented Generation) para melhorar as respostas da IA
com dados contextuais do usuário.
"""
import logging
import numpy as np
from typing import List, Dict, Any, Tuple, Optional
from sentence_transformers import SentenceTransformer
from sqlalchemy.orm import Session
try:
    from app.models.task_model import Task
    from app.models.project_model import Project
except ImportError:
    # Fall back to models from all_models if direct import fails
    from app.models.all_models import Task, Project
from app.models.chat import ChatHistory
import os
import torch
import json
import time

logger = logging.getLogger(__name__)

class VectorStoreService:
    """
    Serviço para armazenar e recuperar embeddings vetoriais para RAG.
    Utiliza sentence-transformers para criar embeddings e implementa busca por similaridade.
    """
    
    def __init__(self):
        """
        Inicializa o serviço de armazenamento vetorial.
        Carrega o modelo de embedding e inicializa estruturas de dados necessárias.
        """
        logger.info("Inicializando serviço de armazenamento vetorial...")
        
        # Inicializar atributos básicos para evitar erros de atributo não encontrado
        self.task_embeddings = {}
        self.project_embeddings = {}
        self.chat_embeddings = {}
        self.last_update = {}
        self.embedding_model = None
        self.embedding_dim = 384  # Dimensão padrão para o modelo all-MiniLM-L6-v2
        self.cache_ttl = 300  # 5 minutos em segundos
        
        self.cache_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "cache")
        os.makedirs(self.cache_dir, exist_ok=True)
        
        try:
            # Escolha um modelo leve - all-MiniLM-L6-v2 (33MB) é um bom equilíbrio entre tamanho e performance
            self.model_name = "sentence-transformers/all-MiniLM-L6-v2"
            logger.info(f"Carregando modelo de embedding: {self.model_name}")
            
            try:
                self.embedding_model = SentenceTransformer(self.model_name)
                self.embedding_dim = self.embedding_model.get_sentence_embedding_dimension()
                logger.info(f"Modelo de embedding carregado com sucesso. Dimensão: {self.embedding_dim}")
            except Exception as e:
                logger.error(f"Erro ao carregar modelo de embedding: {str(e)}")
                # Fallback para modo sem embedding
                self.embedding_model = None
            
            # Carregar embeddings do cache disk se disponíveis
            self._load_embeddings_from_disk()
            
        except Exception as e:
            logger.error(f"Erro ao inicializar serviço de armazenamento vetorial: {str(e)}")
            # Garantir que as estruturas básicas estão definidas mesmo em caso de erro
            self.task_embeddings = {}
            self.project_embeddings = {}
            self.chat_embeddings = {}
            self.last_update = {}
            self.embedding_model = None

    def _load_embeddings_from_disk(self):
        """Carrega embeddings salvos anteriormente em disco."""
        try:
            cache_file = os.path.join(self.cache_dir, "vector_cache.json")
            if os.path.exists(cache_file):
                with open(cache_file, 'r') as f:
                    metadata_cache = json.load(f)
                    self.last_update = metadata_cache.get('last_update', {})
                    logger.info(f"Cache de vetores carregado do disco. Última atualização: {self.last_update}")
        except Exception as e:
            logger.warning(f"Erro ao carregar cache de embeddings: {str(e)}")

    def _save_embeddings_to_disk(self):
        """Salva metadados de embeddings em disco para persistência."""
        try:
            cache_file = os.path.join(self.cache_dir, "vector_cache.json")
            metadata_cache = {
                'last_update': self.last_update,
                'stats': {
                    'users': len(self.task_embeddings),
                    'total_tasks': sum(len(data['metadata']) for user_id, data in self.task_embeddings.items()),
                    'total_projects': sum(len(data['metadata']) for user_id, data in self.project_embeddings.items() if user_id in self.project_embeddings),
                    'total_chats': sum(len(data['metadata']) for user_id, data in self.chat_embeddings.items() if user_id in self.chat_embeddings),
                }
            }
            with open(cache_file, 'w') as f:
                json.dump(metadata_cache, f)
            logger.info(f"Cache de vetores salvo em disco: {metadata_cache['stats']}")
        except Exception as e:
            logger.warning(f"Erro ao salvar cache de embeddings: {str(e)}")

    def _create_embedding(self, text: str) -> np.ndarray:
        """
        Cria um embedding vetorial para um texto.
        
        Args:
            text: Texto a ser convertido em embedding
            
        Returns:
            Vetor de embedding numpy
        """
        if self.embedding_model is None:
            # Retornar vetor vazio se não há modelo
            return np.zeros(384)  # 384 é o tamanho padrão do all-MiniLM-L6-v2
            
        try:
            return self.embedding_model.encode(text)
        except Exception as e:
            logger.error(f"Erro ao criar embedding: {str(e)}")
            return np.zeros(self.embedding_dim)

    def _ensure_user_structures(self, user_id: str):
        """
        Garante que as estruturas de dados necessárias para o usuário estão inicializadas.
        
        Args:
            user_id: ID do usuário
        """
        # Inicializar task_embeddings para o usuário se não existir
        if user_id not in self.task_embeddings:
            self.task_embeddings[user_id] = {"vectors": np.array([]), "metadata": []}
            
        # Inicializar project_embeddings para o usuário se não existir
        if user_id not in self.project_embeddings:
            self.project_embeddings[user_id] = {"vectors": np.array([]), "metadata": []}
            
        # Inicializar chat_embeddings para o usuário se não existir
        if user_id not in self.chat_embeddings:
            self.chat_embeddings[user_id] = {"vectors": np.array([]), "metadata": []}
            
        # Inicializar last_update para o usuário se não existir
        if user_id not in self.last_update:
            self.last_update[user_id] = 0  # Timestamp 0 forçará atualização

    def update_user_vectorstore(self, user_id: str, db: Session, force: bool = False):
        """
        Atualiza o armazenamento de vetores para um usuário específico.
        Coleta tarefas, projetos e histórico de chat recentes e cria embeddings.
        
        Args:
            user_id: ID do usuário
            db: Sessão do banco de dados
            force: Se True, força atualização mesmo se cache for recente
        """
        # Garantir que as estruturas de dados do usuário estão inicializadas
        self._ensure_user_structures(user_id)
        
        # Verificar se precisamos atualizar (TTL do cache)
        current_time = time.time()
        if not force:
            last_update_time = self.last_update.get(user_id, 0)
            if current_time - last_update_time < self.cache_ttl:
                logger.info(f"Usando cache de vetores para o usuário {user_id} (atualizado há {current_time - last_update_time:.1f}s)")
                return
        
        logger.info(f"Atualizando vectorstore para o usuário {user_id}")
        start_time = time.time()
        
        try:
            # Buscar tarefas do usuário
            tasks = db.query(Task).filter(Task.user_id == user_id).all()
            
            # Buscar projetos do usuário
            projects = db.query(Project).filter(Project.user_id == user_id).all()
            
            # Buscar histórico de chat recente
            chat_history = db.query(ChatHistory).filter(
                ChatHistory.user_id == user_id
            ).order_by(ChatHistory.created_at.desc()).limit(50).all()
            
            # Processar tarefas
            task_texts = []
            task_metadata = []
            for task in tasks:
                text = f"Tarefa: {task.title}. "
                if task.description:
                    text += f"Descrição: {task.description}. "
                text += f"Status: {task.status}. Prioridade: {task.priority}."
                
                task_texts.append(text)
                task_metadata.append({
                    "id": str(task.id),
                    "title": task.title,
                    "status": task.status,
                    "priority": task.priority,
                    "type": "task"
                })
            
            # Processar projetos
            project_texts = []
            project_metadata = []
            for project in projects:
                text = f"Projeto: {project.title}. "
                if project.description:
                    text += f"Descrição: {project.description}. "
                
                project_texts.append(text)
                project_metadata.append({
                    "id": str(project.id),
                    "name": project.title,
                    "type": "project"
                })
            
            # Processar histórico de chat
            chat_texts = []
            chat_metadata = []
            for chat in chat_history:
                # Combinar pergunta e resposta em um único texto para contexto
                text = f"Pergunta: {chat.user_message} Resposta: {chat.ai_response}"
                
                chat_texts.append(text)
                chat_metadata.append({
                    "id": str(chat.id),
                    "tags": chat.tags,
                    "created_at": chat.created_at.isoformat() if hasattr(chat.created_at, 'isoformat') else str(chat.created_at),
                    "type": "chat"
                })
            
            # Garantir que o modelo de embedding está disponível
            if self.embedding_model is None:
                try:
                    from sentence_transformers import SentenceTransformer
                    self.embedding_model = SentenceTransformer('all-MiniLM-L6-v2')
                    logger.info("Modelo de embedding inicializado com sucesso.")
                except Exception as e:
                    logger.warning(f"Erro ao inicializar modelo de embedding: {str(e)}")
                    self.embedding_model = None
             
            # Processar embeddings com ou sem modelo
            if self.embedding_model:
                # Processar tarefas
                if task_texts:
                    task_vectors = self.embedding_model.encode(task_texts)
                    self.task_embeddings[user_id] = {
                        "vectors": task_vectors,
                        "metadata": task_metadata
                    }
                else:
                    self.task_embeddings[user_id] = {"vectors": np.array([]), "metadata": []}

                # Processar projetos
                if project_texts:
                    project_vectors = self.embedding_model.encode(project_texts)
                    self.project_embeddings[user_id] = {
                        "vectors": project_vectors,
                        "metadata": project_metadata
                    }
                else:
                    self.project_embeddings[user_id] = {"vectors": np.array([]), "metadata": []}
                
                if chat_texts and self.embedding_model is not None:
                    chat_vectors = self.embedding_model.encode(chat_texts)
                    self.chat_embeddings[user_id] = {
                        "vectors": chat_vectors,
                        "metadata": chat_metadata
                    }
                else:
                    self.chat_embeddings[user_id] = {"vectors": np.array([]), "metadata": chat_metadata if chat_metadata else []}
            
            # Atualizar timestamp
            self.last_update[user_id] = current_time
            
            # Salvar cache em disco
            self._save_embeddings_to_disk()
            
            logger.info(f"Vectorstore atualizado para usuário {user_id}. "
                       f"Tarefas: {len(task_texts)}, Projetos: {len(project_texts)}, "
                       f"Chats: {len(chat_texts)}. "
                       f"Tempo: {time.time() - start_time:.2f}s")
                
        except Exception as e:
            logger.error(f"Erro ao atualizar vectorstore: {str(e)}")
            # Garantir que há uma entrada vazia para evitar erros futuros
            self._ensure_user_structures(user_id)
            
    def _ensure_user_structures(self, user_id: str):
        """
        Garante que as estruturas básicas existem para um usuário.
        """
        if user_id not in self.task_embeddings:
            self.task_embeddings[user_id] = {"vectors": np.array([]), "metadata": []}
        
        if user_id not in self.project_embeddings:
            self.project_embeddings[user_id] = {"vectors": np.array([]), "metadata": []}
            
        if user_id not in self.chat_embeddings:
            self.chat_embeddings[user_id] = {"vectors": np.array([]), "metadata": []}
    
    def retrieve_relevant_context(self, user_id: str, query: str, max_results: int = 5) -> List[Dict[str, Any]]:
        """
        Recupera contexto relevante para uma consulta.
        
        Args:
            user_id: ID do usuário
            query: Consulta para buscar contexto relevante
            max_results: Número máximo de resultados a retornar
            
        Returns:
            Lista de metadados de documentos relevantes
        """
        # Garantir que as estruturas existem
        self._ensure_user_structures(user_id)
        
        # Se não temos modelo de embedding, retornar alguns metadados sem vetorização
        if self.embedding_model is None:
            logger.warning("Modelo de embedding não disponível. Retornando contexto limitado sem similaridade.")
            # Retornar alguns metadados sem vetorização (limitado por max_results)
            results = []
            
            # Adicionar tarefas se disponíveis
            if user_id in self.task_embeddings and self.task_embeddings[user_id]["metadata"]:
                results.extend(self.task_embeddings[user_id]["metadata"][:max_results//2])
                
            # Adicionar projetos se disponíveis e ainda há espaço
            if user_id in self.project_embeddings and self.project_embeddings[user_id]["metadata"]:
                remaining = max_results - len(results)
                results.extend(self.project_embeddings[user_id]["metadata"][:remaining])
                
            return results[:max_results]
            
        if user_id not in self.task_embeddings:
            logger.warning(f"Nenhum dado de embedding encontrado para o usuário {user_id}")
            return []
            
        try:
            # Criar embedding para a consulta
            query_vector = self._create_embedding(query)
            
            # Combinar todos os vetores e metadados
            all_vectors = []
            all_metadata = []
            
            if user_id in self.task_embeddings and len(self.task_embeddings[user_id]["vectors"]) > 0:
                all_vectors.append(self.task_embeddings[user_id]["vectors"])
                all_metadata.extend(self.task_embeddings[user_id]["metadata"])
                
            if user_id in self.project_embeddings and len(self.project_embeddings[user_id]["vectors"]) > 0:
                all_vectors.append(self.project_embeddings[user_id]["vectors"])
                all_metadata.extend(self.project_embeddings[user_id]["metadata"])
                
            if user_id in self.chat_embeddings and len(self.chat_embeddings[user_id]["vectors"]) > 0:
                all_vectors.append(self.chat_embeddings[user_id]["vectors"])
                all_metadata.extend(self.chat_embeddings[user_id]["metadata"])
            
            if not all_vectors:
                return []
                
            # Concatenar todos os vetores
            combined_vectors = np.vstack(all_vectors)
            
            # Calcular similaridade de cosseno
            similarity_scores = np.dot(combined_vectors, query_vector) / (
                np.linalg.norm(combined_vectors, axis=1) * np.linalg.norm(query_vector)
            )
            
            # Ordenar por similaridade e pegar os top N
            top_indices = np.argsort(similarity_scores)[::-1][:max_results]
            
            # Criar resultado com metadados e scores
            results = [
                {**all_metadata[idx], "score": float(similarity_scores[idx])}
                for idx in top_indices
                if similarity_scores[idx] > 0.3  # Threshold mínimo de similaridade
            ]
            
            logger.info(f"Consulta '{query[:30]}...': Encontrados {len(results)} resultados relevantes")
            return results
            
        except Exception as e:
            logger.error(f"Erro ao recuperar contexto: {str(e)}")
            return []
    
    def get_formatted_context(self, user_id: str, query: str) -> str:
        """
        Retorna contexto formatado para uso em prompts do LLM.
        
        Args:
            user_id: ID do usuário
            query: Consulta para buscar contexto relevante
            
        Returns:
            String formatada com contexto relevante
        """
        results = self.retrieve_relevant_context(user_id, query)
        
        if not results:
            return ""
            
        context_parts = ["Contexto relevante do seu perfil Orga.AI:"]
        
        for item in results:
            if item["type"] == "task":
                context_parts.append(
                    f"- Tarefa: '{item['title']}' (Status: {item['status']}, Prioridade: {item['priority']})"
                )
            elif item["type"] == "project":
                context_parts.append(
                    f"- Projeto: '{item['name']}'"
                )
            elif item["type"] == "chat":
                tags_str = ", ".join(item["tags"]) if item.get("tags") else "sem tags"
                context_parts.append(
                    f"- Conversa anterior sobre: '{tags_str}'"
                )
        
        return "\n".join(context_parts)
    
    def healthcheck(self) -> bool:
        """Verifica se o serviço está funcionando corretamente."""
        if self.embedding_model is None:
            return False
            
        return True

# Instância global para uso em toda a aplicação
vector_store_service = VectorStoreService()
