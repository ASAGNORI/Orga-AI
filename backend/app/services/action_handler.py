"""
Serviço para manipular ações a serem executadas a partir das intenções detectadas.
Este serviço executa as ações correspondentes às intenções identificadas pelo intent_recognizer.
"""

import logging
from typing import Dict, Any, Optional
from datetime import datetime, timedelta
import pytz
from sqlalchemy.orm import Session
from app.models.task_model import Task as TaskModel

logger = logging.getLogger(__name__)

class ActionHandler:
    """
    Manipula a execução de ações com base nas intenções detectadas.
    """
    
    def execute_action(self, action: str, entities: Dict[str, Any], user_id: str, db: Session) -> Dict[str, Any]:
        """
        Executa uma ação específica com base na intenção detectada.
        
        Args:
            action: Nome da ação a ser executada
            entities: Entidades extraídas da intenção
            user_id: ID do usuário atual
            db: Sessão do banco de dados
            
        Returns:
            Resultado da ação executada
        """
        # Mapeia o nome da ação para o método correspondente
        action_map = {
            "create_task": self._create_task,
            "create_task_complete": self._create_task_complete,
            "list_tasks": self._list_tasks,
            "list_tasks_by_date": self._list_tasks_by_date,
        }
        
        # Executa a ação se ela existir no mapeamento
        if action in action_map:
            logger.info(f"Executando ação: {action}")
            return action_map[action](entities, user_id, db)
        else:
            logger.warning(f"Ação não implementada: {action}")
            return {"success": False, "message": "Ação não implementada"}
    
    def _create_task(self, entities: Dict[str, Any], user_id: str, db: Session) -> Dict[str, Any]:
        """
        Cria uma tarefa básica.
        """
        try:
            # Extrair informações da tarefa
            title = entities.get("task_title")
            if not title:
                return {"success": False, "message": "Título da tarefa não fornecido"}
            
            # Criar nova tarefa com informações mínimas
            task = TaskModel(
                title=title,
                user_id=user_id,
                priority=entities.get("priority", "medium"),
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
                status="todo"
            )
            
            # Salvar no banco de dados
            db.add(task)
            db.commit()
            db.refresh(task)
            
            return {
                "success": True,
                "message": f"Tarefa '{title}' criada com sucesso!",
                "task_id": str(task.id)
            }
            
        except Exception as e:
            logger.error(f"Erro ao criar tarefa: {str(e)}")
            db.rollback()
            return {"success": False, "message": f"Erro ao criar tarefa: {str(e)}"}
    
    def _create_task_complete(self, entities: Dict[str, Any], user_id: str, db: Session) -> Dict[str, Any]:
        """
        Cria uma tarefa com todos os parâmetros especificados.
        """
        try:
            # Extrair informações da tarefa
            title = entities.get("task_title")
            if not title:
                return {"success": False, "message": "Título da tarefa não fornecido"}
            
            # Configurar a data de vencimento
            due_date = None
            due_date_str = entities.get("due_date")
            
            if due_date_str:
                # Define um timezone local (Brasil - São Paulo)
                local_tz = pytz.timezone('America/Sao_Paulo')
                now = datetime.now(local_tz)
                
                if due_date_str.lower() == "hoje":
                    # Hoje às 12:00
                    due_date = datetime(
                        year=now.year,
                        month=now.month,
                        day=now.day,
                        hour=12, minute=0, second=0,
                        tzinfo=local_tz
                    )
                elif due_date_str.lower() in ["amanhã", "amanha"]:
                    # Amanhã às 12:00
                    tomorrow = now + timedelta(days=1)
                    due_date = datetime(
                        year=tomorrow.year,
                        month=tomorrow.month,
                        day=tomorrow.day,
                        hour=12, minute=0, second=0,
                        tzinfo=local_tz
                    )
                else:
                    # Tentar parsing de data específica
                    try:
                        # Formatos possíveis: dd/mm/yyyy, dd/mm/yy, dd/mm
                        parts = due_date_str.split('/')
                        day = int(parts[0])
                        month = int(parts[1])
                        year = int(parts[2]) if len(parts) > 2 else now.year
                        
                        # Ajustar ano de 2 dígitos
                        if year < 100:
                            year += 2000
                            
                        due_date = datetime(
                            year=year,
                            month=month,
                            day=day,
                            hour=12, minute=0, second=0,
                            tzinfo=local_tz
                        )
                    except (ValueError, IndexError):
                        logger.warning(f"Formato de data não reconhecido: {due_date_str}")
            
            # Converter para UTC
            if due_date:
                due_date = due_date.astimezone(pytz.UTC)
            
            # Determinar prioridade (prioridade padrão é "medium")
            priority = entities.get("priority", "medium")
            # Mapear nomes de prioridade para valores do sistema
            priority_map = {
                "alta": "high",
                "média": "medium",
                "media": "medium",
                "baixa": "low"
            }
            priority = priority_map.get(priority, priority)
            
            # Determinar status (status padrão é "todo")
            status = entities.get("status", "todo")
            
            # Determinar projeto (opcional)
            project_id = None
            if "project" in entities:
                # Aqui, idealmente, você buscaria o ID do projeto pelo nome
                # Por enquanto, só registramos para log
                logger.info(f"Projeto especificado: {entities['project']} (implementação completa necessária)")
            
            # Criar nova tarefa
            task = TaskModel(
                title=title,
                user_id=user_id,
                priority=priority,
                due_date=due_date,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
                status=status,
                project_id=project_id  # Vai ser None por enquanto
            )
            
            # Salvar no banco de dados
            db.add(task)
            db.commit()
            db.refresh(task)
            
            # Preparar mensagem de confirmação detalhada
            due_date_info = ""
            if due_date:
                due_date_local = due_date.astimezone(pytz.timezone('America/Sao_Paulo'))
                due_date_info = f", com prazo para {due_date_local.strftime('%d/%m/%Y')}"
            
            # Mapear prioridade para texto amigável
            priority_text = {
                "high": "alta",
                "medium": "média",
                "low": "baixa"
            }.get(priority, priority)
            
            # Mapear status para texto amigável
            status_text = {
                "todo": "pendente",
                "doing": "em andamento",
                "done": "concluída"
            }.get(status, status)
            
            # Informações do projeto
            project_info = ""
            if "project" in entities:
                project_info = f", no projeto '{entities['project']}'"
            
            return {
                "success": True,
                "message": f"Tarefa '{title}' criada com sucesso com prioridade {priority_text}{due_date_info}{project_info}, status {status_text}!",
                "task_id": str(task.id),
                "task_details": {
                    "title": title,
                    "priority": priority,
                    "due_date": due_date.isoformat() if due_date else None,
                    "status": status,
                    "project": entities.get("project")
                }
            }
            
        except Exception as e:
            logger.error(f"Erro ao criar tarefa completa: {str(e)}")
            db.rollback()
            return {"success": False, "message": f"Erro ao criar tarefa: {str(e)}"}
    
    def _list_tasks(self, entities: Dict[str, Any], user_id: str, db: Session) -> Dict[str, Any]:
        """
        Lista as tarefas do usuário.
        """
        try:
            # Buscar tarefas não concluídas
            tasks = db.query(TaskModel).filter(
                TaskModel.user_id == user_id,
                TaskModel.status != 'done'
            ).order_by(TaskModel.due_date.desc()).all()
            
            # Formatar saída
            task_list = [
                {
                    "id": str(t.id),
                    "title": t.title,
                    "status": t.status,
                    "priority": t.priority,
                    "due_date": t.due_date.isoformat() if t.due_date else None
                } for t in tasks
            ]
            
            return {
                "success": True,
                "message": f"Encontradas {len(task_list)} tarefas.",
                "tasks": task_list
            }
            
        except Exception as e:
            logger.error(f"Erro ao listar tarefas: {str(e)}")
            return {"success": False, "message": f"Erro ao listar tarefas: {str(e)}"}
            
    def _list_tasks_by_date(self, entities: Dict[str, Any], user_id: str, db: Session) -> Dict[str, Any]:
        """
        Lista as tarefas do usuário filtradas por data.
        """
        try:
            # Obter a data de filtro
            filter_date_str = entities.get("filter_date", "hoje")
            
            # Converter a string de data em um objeto datetime
            filter_date = None
            local_tz = pytz.timezone('America/Sao_Paulo')
            now = datetime.now(local_tz)
            
            if filter_date_str == "hoje":
                # Início e fim do dia atual no fuso horário local
                start_date = datetime(
                    year=now.year,
                    month=now.month,
                    day=now.day,
                    hour=0, minute=0, second=0,
                    tzinfo=local_tz
                )
                end_date = datetime(
                    year=now.year,
                    month=now.month,
                    day=now.day,
                    hour=23, minute=59, second=59,
                    tzinfo=local_tz
                )
                date_description = "hoje"
                
            elif filter_date_str in ["amanhã", "amanha"]:
                # Início e fim do dia seguinte no fuso horário local
                tomorrow = now + timedelta(days=1)
                start_date = datetime(
                    year=tomorrow.year,
                    month=tomorrow.month,
                    day=tomorrow.day,
                    hour=0, minute=0, second=0,
                    tzinfo=local_tz
                )
                end_date = datetime(
                    year=tomorrow.year,
                    month=tomorrow.month,
                    day=tomorrow.day,
                    hour=23, minute=59, second=59,
                    tzinfo=local_tz
                )
                date_description = "amanhã"
                
            else:
                # Tentar parsing de data específica (formato dd/mm/yyyy ou dd/mm)
                try:
                    parts = filter_date_str.split('/')
                    day = int(parts[0])
                    month = int(parts[1])
                    year = int(parts[2]) if len(parts) > 2 else now.year
                    
                    # Ajustar ano de 2 dígitos
                    if year < 100:
                        year += 2000
                    
                    start_date = datetime(
                        year=year, month=month, day=day,
                        hour=0, minute=0, second=0,
                        tzinfo=local_tz
                    )
                    end_date = datetime(
                        year=year, month=month, day=day,
                        hour=23, minute=59, second=59,
                        tzinfo=local_tz
                    )
                    date_description = f"{day}/{month}/{year}"
                except (ValueError, IndexError):
                    logger.warning(f"Formato de data não reconhecido: {filter_date_str}")
                    # Usar o dia atual como fallback
                    start_date = datetime(
                        year=now.year, month=now.month, day=now.day,
                        hour=0, minute=0, second=0, tzinfo=local_tz
                    )
                    end_date = datetime(
                        year=now.year, month=now.month, day=now.day,
                        hour=23, minute=59, second=59, tzinfo=local_tz
                    )
                    date_description = "hoje"
            
            # Converter para UTC para busca no banco
            start_date_utc = start_date.astimezone(pytz.UTC)
            end_date_utc = end_date.astimezone(pytz.UTC)
            
            # Buscar tarefas com a data de vencimento no intervalo especificado
            tasks = db.query(TaskModel).filter(
                TaskModel.user_id == user_id,
                TaskModel.due_date >= start_date_utc,
                TaskModel.due_date <= end_date_utc
            ).order_by(TaskModel.priority.desc()).all()
            
            # Formatar a lista de tarefas para exibição
            task_list = []
            for t in tasks:
                # Mapear prioridade para texto amigável
                priority_text = {
                    "high": "alta",
                    "medium": "média",
                    "low": "baixa"
                }.get(t.priority, t.priority)
                
                # Mapear status para texto amigável
                status_text = {
                    "todo": "pendente",
                    "doing": "em andamento",
                    "done": "concluída"
                }.get(t.status, t.status)
                
                task_list.append({
                    "id": str(t.id),
                    "title": t.title,
                    "status": t.status,
                    "status_text": status_text,
                    "priority": t.priority,
                    "priority_text": priority_text,
                    "due_date": t.due_date.isoformat() if t.due_date else None
                })
            
            # Formatação da resposta para exibição ao usuário
            if not task_list:
                message = f"<p>Não encontrei nenhuma tarefa para {date_description}.</p>"
            else:
                message = f"<p>Encontrei {len(task_list)} tarefa(s) para {date_description}:</p><ul>"
                for task in task_list:
                    message += f"<li><strong>{task['title']}</strong> (Prioridade: {task['priority_text']}, Status: {task['status_text']})</li>"
                message += "</ul>"
            
            return {
                "success": True,
                "message": message,
                "tasks": task_list,
                "date_filter": {
                    "description": date_description,
                    "start_date": start_date.isoformat(),
                    "end_date": end_date.isoformat()
                }
            }
            
        except Exception as e:
            logger.error(f"Erro ao listar tarefas por data: {str(e)}")
            return {"success": False, "message": f"Erro ao listar tarefas para a data especificada: {str(e)}"}

# Instância global
action_handler = ActionHandler()
