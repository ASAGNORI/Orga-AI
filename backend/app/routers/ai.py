from fastapi import APIRouter, HTTPException, status, Request, Depends
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from app.services.ai_service import ai_service
from app.utils.llm_cleaner import clean_llm_response
from app.services.auth_service import get_current_user
from app.models.task_model import Task as TaskModel
from app.models.project_model import Project as ProjectModel
from app.models.user import User
from app.database import get_db
import logging

router = APIRouter(prefix="/ai", tags=["ai"])
logger = logging.getLogger(__name__)

SYSTEM_PROMPT_EMAIL = (
    "Você é um assistente de produtividade. Sempre gere um e-mail motivacional e personalizado em HTML para o usuário, usando listas (<ul>, <li>) e parágrafos (<p>). Evite repetições, seja objetivo, destaque conquistas e próximos passos. Se não houver tarefas, incentive o usuário a planejar o dia. Nunca use classes ou atributos extras nas tags HTML. O resultado deve ser pronto para ser enviado por e-mail."
)

def montar_contexto_personalizado(data):
    # Monta contexto textual e estrutura para IA a partir dos campos do N8N
    tarefas_hoje = data.get("tarefasHoje") or []
    tarefas_amanha = data.get("tarefasAmanha") or []
    tarefas_atrasadas = data.get("tarefasAtrasadas") or []
    total = data.get("totalTarefas")
    concluidas = data.get("tarefasConcluidas")
    partes = []
    if tarefas_hoje:
        partes.append("<b>Tarefas para hoje:</b><ul>" + "".join([f"<li>{t.get('title')} ({t.get('priority','-')})</li>" for t in tarefas_hoje]) + "</ul>")
    else:
        partes.append("<b>Tarefas para hoje:</b> (Nenhuma tarefa)")
    if tarefas_amanha:
        partes.append("<b>Tarefas para amanhã:</b><ul>" + "".join([f"<li>{t.get('title')} ({t.get('priority','-')})</li>" for t in tarefas_amanha]) + "</ul>")
    else:
        partes.append("<b>Tarefas para amanhã:</b> (Nenhuma tarefa)")
    if tarefas_atrasadas:
        partes.append("<b>Tarefas atrasadas:</b><ul>" + "".join([f"<li>{t.get('title')} ({t.get('priority','-')})</li>" for t in tarefas_atrasadas]) + "</ul>")
    else:
        partes.append("<b>Tarefas atrasadas:</b> (Nenhuma tarefa)")
    if total is not None and concluidas is not None:
        partes.append(f"<b>Total de tarefas:</b> {total} | <b>Concluídas:</b> {concluidas}")
    contexto = "\n".join(partes)
    return contexto

@router.post("/generate-email")
async def generate_email(
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Endpoint para geração de e-mail personalizado via IA.
    Busca tarefas e projetos reais do usuário, injeta no contexto do prompt e gera resposta personalizada.
    """
    try:
        data = await request.json()
        prompt = data.get("prompt")
        if not prompt or not prompt.strip():
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Prompt não pode ser vazio.")

        # Se vier contexto customizado do N8N, monta contexto textual
        if any(k in data for k in ["tarefasHoje", "tarefasAmanha", "tarefasAtrasadas", "totalTarefas", "tarefasConcluidas"]):
            contexto = montar_contexto_personalizado(data)
            full_prompt = f"{contexto}\n\nSolicitação: {prompt.strip()}"
            response, _ = ai_service.process_message(full_prompt)
            cleaned = clean_llm_response(response)
            return JSONResponse(content={"response": cleaned, "result": cleaned, "status": "ok"})

        # Buscar tarefas do usuário
        tasks = db.query(TaskModel).filter(TaskModel.user_id == current_user.id).order_by(TaskModel.due_date.asc()).all()
        task_context = [
            {
                "title": t.title,
                "status": t.status,
                "priority": t.priority,
                "due_date": t.due_date.isoformat() if t.due_date else None
            } for t in tasks
        ]

        # Buscar projetos do usuário
        projects = db.query(ProjectModel).filter(ProjectModel.user_id == current_user.id).order_by(ProjectModel.created_at.asc()).all()
        project_context = [
            {
                "title": p.title,
                "status": p.status,
                "description": p.description
            } for p in projects
        ]

        # Montar contexto textual para o modelo
        context_parts = []
        if task_context:
            context_parts.append("Minhas tarefas atuais:\n" + "\n".join([
                f"- {t['title']} (Prioridade: {t['priority']}, Status: {t['status']}, Vencimento: {t['due_date']})" for t in task_context
            ]))
        if project_context:
            context_parts.append("Meus projetos ativos:\n" + "\n".join([
                f"- {p['title']} (Status: {p['status']})" + (f" - {p['description']}" if p['description'] else "") for p in project_context
            ]))
        if not context_parts:
            context_parts.append("Não há tarefas ou projetos cadastrados. Sugira ações úteis para organização pessoal.")

        # Prompt final enriquecido
        full_prompt = "\n\n".join(context_parts) + f"\n\nSolicitação: {prompt.strip()}"

        # Gera resposta usando o modelo padrão/configurado
        response, _ = ai_service.process_message(full_prompt)
        # Limpa a resposta (garantia extra)
        cleaned = clean_llm_response(response)
        # Retorna com formato compatível com n8n (field 'response' em vez de 'result')
        return JSONResponse(content={"response": cleaned, "result": cleaned, "status": "ok"})
    except Exception as e:
        logger.error(f"Erro ao gerar e-mail com IA: {e}")
        return JSONResponse(
            status_code=500,
            content={"status": "error", "response": "Erro interno ao gerar e-mail com IA.", "message": "Erro interno ao gerar e-mail com IA."}
        )

@router.post("/generate-email-admin")
async def generate_email_admin(
    request: Request,
    db: Session = Depends(get_db)
):
    """
    Endpoint admin: gera e-mail personalizado para qualquer usuário (via user_id ou email).
    Permite autenticação via token especial de admin (header 'X-Admin-Token' ou 'Authorization').
    Aceita contexto de tarefas/projetos diretamente no body (tarefasHoje, tarefasAmanha, tarefasAtrasadas, etc).
    """
    import os
    ADMIN_TOKEN = os.environ.get("ADMIN_TOKEN", "supersecrettoken")
    token = request.headers.get("x-admin-token") or request.headers.get("authorization")
    if not token:
        raise HTTPException(status_code=401, detail="Admin token ausente")
    if token.lower().startswith("bearer "):
        token = token[7:]
    if token != ADMIN_TOKEN:
        raise HTTPException(status_code=401, detail="Admin token inválido")
    try:
        data = await request.json()
        
        prompt = data.get("prompt")
        force_prompt = data.get("force_prompt", False)
        user_id = data.get("user_id") or data.get("id")
        email = data.get("email")
        
        if not prompt or not prompt.strip():
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Prompt não pode ser vazio.")
        if not user_id and not email:
            raise HTTPException(status_code=400, detail="Informe user_id ou email do usuário alvo.")
        from app.models.user import User as UserModel
        query = db.query(UserModel)
        
        if user_id:
            user_alvo = query.filter(UserModel.id == user_id).first()
        else:
            user_alvo = query.filter(UserModel.email == email).first()
        
        if not user_alvo:
            raise HTTPException(status_code=404, detail="Usuário alvo não encontrado.")
        # Se vier force_prompt, envie o prompt puro
        if force_prompt:
            response, _ = ai_service.process_message(prompt)
            cleaned = clean_llm_response(response)
            # Retorna com formato compatível com n8n (field 'response' em vez de 'result')
            return JSONResponse(content={"response": cleaned, "result": cleaned, "status": "ok"})
        # Se vier contexto customizado do N8N, monta contexto textual
        if any(k in data for k in ["tarefasHoje", "tarefasAmanha", "tarefasAtrasadas", "totalTarefas", "tarefasConcluidas"]):
            contexto = montar_contexto_personalizado(data)
            full_prompt = f"{SYSTEM_PROMPT_EMAIL}\n\n{contexto}\n\nSolicitação: {prompt.strip()}"
            response, _ = ai_service.process_message(full_prompt)
            cleaned = clean_llm_response(response)
            # Retorna com formato compatível com n8n (field 'response' em vez de 'result')
            return JSONResponse(content={"response": cleaned, "result": cleaned, "status": "ok"})
        # Se não veio contexto customizado, buscar tarefas/projetos do banco
        user_context = None
        tasks = db.query(TaskModel).filter(TaskModel.user_id == user_alvo.id).order_by(TaskModel.due_date.asc()).all()
        user_context = {"tasks": [
            {"title": t.title, "status": t.status, "priority": t.priority, "due_date": t.due_date.isoformat() if t.due_date else None}
            for t in tasks
        ]}
        projects = db.query(ProjectModel).filter(ProjectModel.user_id == user_alvo.id).order_by(ProjectModel.created_at.asc()).all()
        user_context["projects"] = [
            {"title": p.title, "status": p.status, "description": p.description}
            for p in projects
        ]
        full_prompt = f"{SYSTEM_PROMPT_EMAIL}\n\n{montar_contexto_personalizado(data)}\n\nSolicitação: {prompt.strip()}"
        response, _ = ai_service.process_message(full_prompt)
        cleaned = clean_llm_response(response)
        return JSONResponse(content={"response": cleaned, "result": cleaned, "status": "ok"})
    except Exception as e:
        logger.error(f"Erro ao gerar e-mail admin com IA: {e}")
        return JSONResponse(
            status_code=500,
            content={"status": "error", "response": "Erro interno ao gerar e-mail admin com IA.", "message": "Erro interno ao gerar e-mail admin com IA."}
        )
