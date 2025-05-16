#!/bin/zsh
# Script para disparar um teste nos workflows n8n
# Data: 12/05/2025
# Autor: GitHub Copilot

# Definir cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Testando execução manual dos nós 'Registrar Log de Email' nos workflows n8n...${NC}"

N8N_URL="http://localhost:5678/api/v1"

# Obter lista de workflows
echo -e "\n${YELLOW}Buscando workflows no n8n...${NC}"
workflows=$(curl -s -X GET "${N8N_URL}/workflows")

# Extrair os IDs dos workflows que nos interessam
workflow_com_ia_id=$(echo $workflows | jq -r '.data[] | select(.name=="n8n_email_daily_tasks") | .id')
workflow_sem_ia_id=$(echo $workflows | jq -r '.data[] | select(.name=="n8n_email_daily_tasks_sem_ia") | .id')

echo -e "ID do workflow com IA: ${workflow_com_ia_id:-não encontrado}"
echo -e "ID do workflow sem IA: ${workflow_sem_ia_id:-não encontrado}"

# Funções para testes
test_node() {
  local workflow_id=$1
  local workflow_name=$2
  local node_id=$3
  
  echo -e "\n${YELLOW}Testando nó 'Registrar Log de Email' no workflow $workflow_name...${NC}"
  
  # Executar o nó
  result=$(curl -s -X POST "${N8N_URL}/workflows/${workflow_id}/execute" \
    -H "Content-Type: application/json" \
    -d "{\"startNodes\": [\"${node_id}\"]}")
  
  echo -e "Resposta da API: $result"
  
  # Verificar se houve erro
  error=$(echo $result | jq -r '.error')
  if [[ "$error" == "null" ]]; then
    echo -e "${GREEN}✅ Teste bem-sucedido!${NC}"
  else
    echo -e "${RED}❌ Erro: $error${NC}"
  fi
}

# Buscar IDs dos nós de log
if [[ ! -z "$workflow_com_ia_id" ]]; then
  workflow=$(curl -s -X GET "${N8N_URL}/workflows/${workflow_com_ia_id}")
  node_id=$(echo $workflow | jq -r '.nodes[] | select(.name=="Registrar Log de Email") | .id')
  echo -e "ID do nó 'Registrar Log de Email' no workflow com IA: $node_id"
  
  if [[ ! -z "$node_id" ]]; then
    test_node "$workflow_com_ia_id" "com IA" "$node_id"
  else
    echo -e "${RED}❌ Nó 'Registrar Log de Email' não encontrado no workflow com IA.${NC}"
  fi
else
  echo -e "${RED}❌ Workflow com IA não encontrado.${NC}"
fi

if [[ ! -z "$workflow_sem_ia_id" ]]; then
  workflow=$(curl -s -X GET "${N8N_URL}/workflows/${workflow_sem_ia_id}")
  node_id=$(echo $workflow | jq -r '.nodes[] | select(.name=="Registrar Log de Email") | .id')
  echo -e "ID do nó 'Registrar Log de Email' no workflow sem IA: $node_id"
  
  if [[ ! -z "$node_id" ]]; then
    test_node "$workflow_sem_ia_id" "sem IA" "$node_id"
  else
    echo -e "${RED}❌ Nó 'Registrar Log de Email' não encontrado no workflow sem IA.${NC}"
  fi
else
  echo -e "${RED}❌ Workflow sem IA não encontrado.${NC}"
fi

echo -e "\n${YELLOW}Verificando logs recentes no banco de dados...${NC}"
docker exec orga-ai-v4-db-1 psql -U postgres -d postgres -c "SELECT id, user_id, source, level, created_at FROM system_logs WHERE source = 'n8n_workflow' ORDER BY created_at DESC LIMIT 5;"

echo -e "\n${GREEN}Teste concluído!${NC}"
echo -e "Verifique os resultados acima para confirmar se os logs foram registrados corretamente."
