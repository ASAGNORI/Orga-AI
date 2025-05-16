#!/bin/zsh
# Script para testar os workflows n8n diretamente
# Data: 12/05/2025
# Autor: GitHub Copilot

# Definir cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Testando workflows n8n diretamente com a API do N8N...${NC}"

N8N_API="http://localhost:5678/api/v1"
N8N_WORKFLOWS="${N8N_API}/workflows"

# Obter os workflows disponíveis
echo -e "\n${YELLOW}Obtendo lista de workflows...${NC}"
WORKFLOWS=$(curl -s "${N8N_WORKFLOWS}")

# Extrair os IDs dos workflows que queremos testar
echo -e "\n${YELLOW}Verificando IDs dos workflows de email...${NC}"
WORKFLOW_COM_IA=$(echo $WORKFLOWS | jq -r '.data[] | select(.name == "n8n_email_daily_tasks") | .id')
WORKFLOW_SEM_IA=$(echo $WORKFLOWS | jq -r '.data[] | select(.name == "n8n_email_daily_tasks_sem_ia") | .id')

# Mostrar os IDs encontrados
echo -e "Workflow com IA: ${WORKFLOW_COM_IA:-não encontrado}"
echo -e "Workflow sem IA: ${WORKFLOW_SEM_IA:-não encontrado}"

# Verificar se encontrou os workflows
if [[ -z "$WORKFLOW_COM_IA" && -z "$WORKFLOW_SEM_IA" ]]; then
    echo -e "${RED}❌ Nenhum workflow encontrado!${NC}"
    echo -e "Verifique se o n8n está rodando e se os workflows foram importados corretamente."
    exit 1
fi

# Funções de teste
test_workflow() {
    local workflow_id=$1
    local workflow_name=$2
    
    echo -e "\n${YELLOW}Testando workflow: $workflow_name (ID: $workflow_id)...${NC}"
    
    # Executando o workflow
    RESULT=$(curl -s -X POST "${N8N_WORKFLOWS}/${workflow_id}/activate")
    
    if [[ $RESULT == *"true"* ]]; then
        echo -e "${GREEN}✅ Workflow $workflow_name ativado com sucesso!${NC}"
        
        # Aguardar um pouco para o workflow executar
        echo -e "Aguardando 5 segundos para execução..."
        sleep 5
        
        # Verificar logs do sistema
        echo -e "\n${YELLOW}Verificando logs do sistema...${NC}"
        docker exec orga-ai-v4-db-1 psql -U postgres -d postgres -c "SELECT id, level, source, message, created_at FROM system_logs WHERE source = 'n8n_workflow' ORDER BY created_at DESC LIMIT 3;"
        
        return 0
    else
        echo -e "${RED}❌ Falha ao ativar workflow $workflow_name${NC}"
        echo $RESULT
        return 1
    fi
}

# Testar os workflows encontrados
if [[ ! -z "$WORKFLOW_COM_IA" ]]; then
    test_workflow "$WORKFLOW_COM_IA" "n8n_email_daily_tasks"
fi

if [[ ! -z "$WORKFLOW_SEM_IA" ]]; then
    test_workflow "$WORKFLOW_SEM_IA" "n8n_email_daily_tasks_sem_ia"
fi

echo -e "\n${GREEN}Testes concluídos!${NC}"
echo -e "Se os testes foram bem-sucedidos, os logs devem aparecer no banco de dados."
echo -e "Para mais detalhes, consulte a interface web do n8n em http://localhost:5678"
