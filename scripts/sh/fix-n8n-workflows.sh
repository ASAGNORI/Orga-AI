#!/bin/zsh
# Script para adicionar o parâmetro bodyParametersJson aos nós "Registrar Log de Email"
# Data: 11/05/2025
# Autor: Equipe Orga.AI

# Definir cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

WORKFLOW_DIR="/Users/angelosagnori/Downloads/orga-ai-v4/cookbooks/n8n-flows"
BACKUP_DIR="${WORKFLOW_DIR}/backup/bodyParams_fix_$(date +%Y%m%d_%H%M%S)"

echo -e "${YELLOW}Corrigindo parâmetros de logs nos workflows n8n...${NC}"

# Criar diretório de backup
mkdir -p "${BACKUP_DIR}"
echo -e "Backup sendo criado em ${BACKUP_DIR}..."

# Fazer backup dos arquivos originais
cp "${WORKFLOW_DIR}/n8n_email_daily_tasks.json" "${BACKUP_DIR}/"
cp "${WORKFLOW_DIR}/n8n_email_daily_tasks_sem_ia.json" "${BACKUP_DIR}/"

# Temporários
TEMP_FILE_1=$(mktemp)
TEMP_FILE_2=$(mktemp)

# Adicionar bodyParametersJson ao workflow com IA
echo -e "Corrigindo n8n_email_daily_tasks.json..."
jq '.nodes = (.nodes | map(
    if .name == "Registrar Log de Email" then
        .parameters += {
            "bodyParametersJson": "= { \n  \"level\": \"info\", \n  \"source\": \"n8n_workflow\", \n  \"message\": `Email enviado para ${$json[\"email\"]} via Gmail`, \n  \"details\": { \n    \"workflow\": \"n8n_email_daily_tasks\", \n    \"user_id\": $json[\"id\"], \n    \"task_count\": $json[\"totalTarefas\"], \n    \"timestamp\": new Date().toISOString() \n  } \n}"
        }
    else
        .
    end
))' "${WORKFLOW_DIR}/n8n_email_daily_tasks.json" > "$TEMP_FILE_1"

# Verificar se o jq funcionou corretamente
if [ $? -eq 0 ]; then
    mv "$TEMP_FILE_1" "${WORKFLOW_DIR}/n8n_email_daily_tasks.json"
    echo -e "${GREEN}✅ Arquivo n8n_email_daily_tasks.json corrigido com sucesso${NC}"
else
    echo -e "${RED}❌ Erro ao processar n8n_email_daily_tasks.json${NC}"
    exit 1
fi

# Adicionar bodyParametersJson ao workflow sem IA
echo -e "Corrigindo n8n_email_daily_tasks_sem_ia.json..."
jq '.nodes = (.nodes | map(
    if .name == "Registrar Log de Email" then
        .parameters += {
            "bodyParametersJson": "= { \n  \"level\": \"info\", \n  \"source\": \"n8n_workflow\", \n  \"message\": `Email enviado para ${$json[\"email\"]} via Gmail`, \n  \"details\": { \n    \"workflow\": \"n8n_email_daily_tasks_sem_ia\", \n    \"user_id\": $json[\"id\"], \n    \"task_count\": $json[\"totalTarefas\"], \n    \"timestamp\": new Date().toISOString() \n  } \n}"
        }
    else
        .
    end
))' "${WORKFLOW_DIR}/n8n_email_daily_tasks_sem_ia.json" > "$TEMP_FILE_2"

# Verificar se o jq funcionou corretamente
if [ $? -eq 0 ]; then
    mv "$TEMP_FILE_2" "${WORKFLOW_DIR}/n8n_email_daily_tasks_sem_ia.json"
    echo -e "${GREEN}✅ Arquivo n8n_email_daily_tasks_sem_ia.json corrigido com sucesso${NC}"
else
    echo -e "${RED}❌ Erro ao processar n8n_email_daily_tasks_sem_ia.json${NC}"
    exit 1
fi

echo -e "\n${GREEN}Correção concluída com sucesso!${NC}"
echo -e "Os arquivos originais foram salvos em ${BACKUP_DIR}"
echo -e "\n${YELLOW}Instruções para teste:${NC}"
echo -e "1. Acesse o n8n em http://localhost:5678"
echo -e "2. Abra cada workflow e verifique se o nó 'Registrar Log de Email' tem o parâmetro 'Body Parameters' configurado corretamente"
echo -e "3. Execute os workflows para testar se os logs são registrados sem erros"
