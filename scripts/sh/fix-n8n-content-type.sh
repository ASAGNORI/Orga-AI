#!/bin/zsh
# Script para corrigir o formato dos parâmetros JSON nos workflows n8n
# Data: 12/05/2025
# Autor: GitHub Copilot

# Definir cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

WORKFLOW_DIR="/Users/angelosagnori/Downloads/orga-ai-v4/cookbooks/n8n-flows"
BACKUP_DIR="${WORKFLOW_DIR}/backup/content_type_fix_$(date +%Y%m%d_%H%M%S)"

echo -e "${YELLOW}Corrigindo formato de Body Parameters nos workflows n8n...${NC}"

# Criar diretório de backup
mkdir -p "${BACKUP_DIR}"
echo -e "Backup sendo criado em ${BACKUP_DIR}..."

# Fazer backup dos arquivos originais
cp "${WORKFLOW_DIR}/n8n_email_daily_tasks.json" "${BACKUP_DIR}/"
cp "${WORKFLOW_DIR}/n8n_email_daily_tasks_sem_ia.json" "${BACKUP_DIR}/"

# Temporários
TEMP_FILE_1=$(mktemp)
TEMP_FILE_2=$(mktemp)

# Modificar arquivo 1 - n8n_email_daily_tasks.json
echo -e "Corrigindo n8n_email_daily_tasks.json..."
jq '.nodes = (.nodes | map(
    if .name == "Registrar Log de Email" then
        .parameters += {
            "bodyContentType": "json",
            "jsonParameters": false,
            "body": {
                "level": "info",
                "source": "n8n_workflow",
                "message": "Email enviado via Gmail",
                "details": {
                    "workflow": "n8n_email_daily_tasks",
                    "timestamp": "{{$now.toISOString()}}"
                }
            }
        } | del(.parameters.bodyParametersJson)
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

# Modificar arquivo 2 - n8n_email_daily_tasks_sem_ia.json
echo -e "Corrigindo n8n_email_daily_tasks_sem_ia.json..."
jq '.nodes = (.nodes | map(
    if .name == "Registrar Log de Email" then
        .parameters += {
            "bodyContentType": "json",
            "jsonParameters": false,
            "body": {
                "level": "info",
                "source": "n8n_workflow",
                "message": "Email enviado via Gmail",
                "details": {
                    "workflow": "n8n_email_daily_tasks_sem_ia",
                    "timestamp": "{{$now.toISOString()}}"
                }
            }
        } | del(.parameters.bodyParametersJson)
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
echo -e "2. Abra cada workflow e verifique se o nó 'Registrar Log de Email' está configurado corretamente"
echo -e "3. Execute o nó 'Registrar Log de Email' para testar se não ocorrem mais erros JSON"
