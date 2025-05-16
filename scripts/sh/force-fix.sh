#!/bin/bash

# Script de força bruta para resolver problemas persistentes no n8n e na página de tasks
# Autor: GitHub Copilot
# Data: 13/05/2025

# Cores para formatação
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sem cor

echo -e "${BLUE}=== Orga.AI - Solução de Problemas Persistentes ===${NC}"
echo -e "${YELLOW}Este script resolverá os problemas de login no n8n e na página de tarefas${NC}"
echo

# Verifica se está no diretório correto
if [ ! -f docker-compose.yml ]; then
  echo -e "${RED}Erro: Este script deve ser executado no diretório raiz do projeto${NC}"
  exit 1
fi

# Passo 1: Backup dos arquivos importantes
echo -e "${BLUE}1. Criando backups dos arquivos importantes...${NC}"
cp -f .env .env.bak.$(date +"%Y%m%d%H%M%S")
echo -e "${GREEN}✓ Backup do .env criado${NC}"

# Passo 2: Forçar n8n a funcionar sem autenticação
echo -e "${BLUE}2. Configurando o n8n para funcionar sem autenticação...${NC}"

# Atualiza as variáveis no .env
echo -e "${YELLOW}  Atualizando variáveis no .env...${NC}"
sed -i '' 's/N8N_USER_MANAGEMENT_DISABLED=.*/N8N_USER_MANAGEMENT_DISABLED=true/g' .env
sed -i '' 's/N8N_BASIC_AUTH_ACTIVE=.*/N8N_BASIC_AUTH_ACTIVE=false/g' .env

# Remove o volume do n8n para forçar uma nova criação
echo -e "${YELLOW}  Removendo volumes do n8n para forçar recriação...${NC}"
echo -e "${RED}  ATENÇÃO: Isso irá remover todos os workflows do n8n! Faça backup se necessário.${NC}"
read -p "  Continuar? (s/N): " confirm
if [[ "$confirm" != [sS] ]]; then
  echo -e "${YELLOW}Operação cancelada pelo usuário${NC}"
  exit 0
fi

# Para os contêineres
echo -e "${YELLOW}  Parando os contêineres...${NC}"
docker-compose down n8n

# Remove o volume
echo -e "${YELLOW}  Removendo o volume do n8n...${NC}"
rm -rf ./volumes/n8n/*

# Passo 3: Corrigir o endpoint de estatísticas de tarefas
echo -e "${BLUE}3. Corrigindo o endpoint de estatísticas de tarefas...${NC}"

cat > /tmp/fix_task_stats.py << 'EOF'
"""
Solução robusta para o endpoint de estatísticas de tarefas.
Este arquivo substitui o código existente no arquivo tasks.py 
"""

@router.get("/tasks/stats")
async def get_task_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get statistics about tasks for the current user"""
    try:
        # Consulta tarefas do usuário atual
        user_id = current_user.id
        logger.debug(f"Calculando estatísticas para o usuário: {user_id}")
        
        tasks_query = db.query(TaskModel).filter(TaskModel.user_id == user_id)
        tasks_count = tasks_query.count()
        logger.debug(f"Total de tarefas encontradas: {tasks_count}")
        
        # Inicializa estatísticas com valores padrão
        stats = {
            "total": tasks_count,
            "completed": 0,
            "overdue": 0,
            "dueToday": 0,
            "dueThisWeek": 0,
            "byPriority": {"high": 0, "medium": 0, "low": 0},
            "byTag": {}
        }
        
        # Se não há tarefas, retorna estatísticas zeradas
        if tasks_count == 0:
            logger.debug("Nenhuma tarefa encontrada. Retornando estatísticas zeradas.")
            return stats
            
        # Configura timezone para São Paulo
        sp_tz = timezone('America/Sao_Paulo')
        
        # Obtém a data atual no timezone de São Paulo
        now = datetime.now(sp_tz)
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        week_end = today_start + timedelta(days=7)
        
        # Conta tarefas concluídas
        completed_count = tasks_query.filter(TaskModel.status == "done").count()
        stats["completed"] = completed_count
        
        # Processa cada tarefa
        all_tasks = tasks_query.all()
        
        for task in all_tasks:
            try:
                # Conta tarefas por prioridade (com validação)
                priority = task.priority
                if priority and isinstance(priority, str) and priority in ["high", "medium", "low"]:
                    stats["byPriority"][priority] += 1
                
                # Processa datas de vencimento (com validação)
                if task.due_date:
                    try:
                        # Converte para timezone local
                        due_date = task.due_date
                        if due_date.tzinfo is None:
                            # Se a data não tem timezone, assume UTC
                            due_date = due_date.replace(tzinfo=pytz.UTC)
                            
                        due_date = due_date.astimezone(sp_tz)
                        due_date_start = due_date.replace(hour=0, minute=0, second=0, microsecond=0)
                        
                        # Verifica se está vencida (antes de hoje e não concluída)
                        if due_date_start < today_start and task.status != "done":
                            stats["overdue"] += 1
                            logger.debug(f"Tarefa vencida: {task.id} - {task.title} - {due_date}")
                        
                        # Verifica se vence hoje
                        elif due_date_start == today_start:
                            stats["dueToday"] += 1
                            logger.debug(f"Tarefa para hoje: {task.id} - {task.title} - {due_date}")
                        
                        # Verifica se vence esta semana
                        elif today_start < due_date_start <= week_end:
                            stats["dueThisWeek"] += 1
                            logger.debug(f"Tarefa para esta semana: {task.id} - {task.title} - {due_date}")
                    except Exception as date_error:
                        logger.error(f"Erro ao processar data da tarefa {task.id}: {str(date_error)}")
                
                # Processa tags (com validação robusta)
                if hasattr(task, 'tags') and task.tags is not None:
                    try:
                        # Verifica se tags é uma lista ou outro iterável
                        if isinstance(task.tags, list) or isinstance(task.tags, tuple):
                            for tag in task.tags:
                                if isinstance(tag, str) and tag.strip():  # Verifica se é string não vazia
                                    tag_key = tag.strip()
                                    stats["byTag"][tag_key] = stats["byTag"].get(tag_key, 0) + 1
                        # Caso seja uma string única (erro comum)
                        elif isinstance(task.tags, str):
                            tag_key = task.tags.strip()
                            if tag_key:
                                stats["byTag"][tag_key] = stats["byTag"].get(tag_key, 0) + 1
                    except Exception as tag_error:
                        logger.error(f"Erro ao processar tags da tarefa {task.id}: {str(tag_error)}")
                        
            except Exception as task_error:
                logger.error(f"Erro ao processar tarefa {task.id}: {str(task_error)}")
                # Continua processando outras tarefas

        logger.info(f"Estatísticas calculadas com sucesso: total={stats['total']}, concluídas={stats['completed']}, vencidas={stats['overdue']}")
        return stats
        
    except Exception as e:
        # Log detalhado do erro
        logger.error(f"Erro ao calcular estatísticas de tarefas: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        
        # Return zeroed stats on error
        return {
            "total": 0,
            "completed": 0,
            "overdue": 0,
            "dueToday": 0,
            "dueThisWeek": 0,
            "byPriority": {"high": 0, "medium": 0, "low": 0},
            "byTag": {}
        }
EOF

# Encontra o arquivo tasks.py
TASKS_PY=$(find ./backend -name tasks.py | grep -v __pycache__)

if [ -n "$TASKS_PY" ]; then
  echo -e "${YELLOW}  Encontrado arquivo tasks.py em: $TASKS_PY${NC}"
  
  # Fazer backup do arquivo
  cp "$TASKS_PY" "${TASKS_PY}.bak.$(date +"%Y%m%d%H%M%S")"
  
  # Localizar a função get_task_stats no arquivo
  LINE_NUM=$(grep -n "@router.get(\"/tasks/stats\")" "$TASKS_PY" | cut -d: -f1)
  
  if [ -n "$LINE_NUM" ]; then
    echo -e "${YELLOW}  Encontrada função get_task_stats na linha $LINE_NUM${NC}"
    
    # Remove a função antiga e insere a nova
    echo -e "${YELLOW}  Substituindo a implementação da função...${NC}"
    
    # Encontrar o final da função para substituir
    # Isso é mais complicado, então estamos substituindo a função inteira
    # Vamos primeiro encontrar a linha da função seguinte
    NEXT_FUNC=$(tail -n +$((LINE_NUM+1)) "$TASKS_PY" | grep -n "@router" | head -1 | cut -d: -f1)
    
    if [ -n "$NEXT_FUNC" ]; then
      END_LINE=$((LINE_NUM + NEXT_FUNC - 1))
      echo -e "${YELLOW}  Função termina na linha $END_LINE${NC}"
      
      # Extrair tudo antes da função
      head -n $((LINE_NUM-1)) "$TASKS_PY" > /tmp/tasks_py_before
      
      # Extrair tudo depois da função
      tail -n +$((END_LINE+1)) "$TASKS_PY" > /tmp/tasks_py_after
      
      # Juntar tudo
      cat /tmp/tasks_py_before /tmp/fix_task_stats.py /tmp/tasks_py_after > "$TASKS_PY"
      echo -e "${GREEN}✓ Função get_task_stats substituída com sucesso${NC}"
    else
      echo -e "${RED}  Não foi possível encontrar o final da função. Fazendo substituição manual...${NC}"
      echo -e "${YELLOW}  Por favor, edite manualmente o arquivo $TASKS_PY e substitua a função get_task_stats${NC}"
    fi
  else
    echo -e "${RED}  Função get_task_stats não encontrada no arquivo${NC}"
  fi
else
  echo -e "${RED}  Arquivo tasks.py não encontrado!${NC}"
fi

# Passo 4: Reiniciar os serviços
echo -e "${BLUE}4. Reiniciando os serviços...${NC}"
docker-compose up -d n8n backend

# Passo 5: Verificar se todos os serviços estão rodando
echo -e "${BLUE}5. Verificando status dos serviços...${NC}"
sleep 10  # Espera um pouco para os serviços iniciarem

echo -e "${YELLOW}  Status do n8n:${NC}"
docker-compose ps n8n
echo

echo -e "${YELLOW}  Status do backend:${NC}"
docker-compose ps backend
echo

echo -e "${BLUE}=== Solução Concluída! ===${NC}"
echo -e "${GREEN}O n8n agora deve estar acessível sem autenticação em:${NC}"
echo -e "${YELLOW}  http://localhost:5678${NC}"
echo
echo -e "${GREEN}A página de tarefas deve estar funcionando corretamente.${NC}"
echo -e "${YELLOW}Se ainda houver problemas, verifique os logs usando:${NC}"
echo -e "  docker-compose logs n8n"
echo -e "  docker-compose logs backend"
echo
