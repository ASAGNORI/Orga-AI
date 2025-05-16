#!/bin/bash

# Script para testar os workflows n8n após as correções
# Data: 15/05/2025

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Teste dos Workflows N8N - 15/05/2025 ===${NC}"

# Verificar se os serviços necessários estão em execução
check_service() {
  SERVICE=$1
  echo -e "Verificando se o serviço $SERVICE está em execução..."
  if docker ps | grep -q "orga-ai-v4-$SERVICE"; then
    echo -e "${GREEN}✅ $SERVICE está em execução${NC}"
    return 0
  else
    echo -e "${RED}❌ $SERVICE não está em execução${NC}"
    return 1
  fi
}

# Verificar as tarefas com user_id
check_user_tasks() {
  USER_ID="e7d51dfe-0f3c-45cd-b388-3b5c62ab1265"
  echo -e "Verificando se há tarefas associadas ao usuário administrador..."
  TASKS_COUNT=$(docker exec orga-ai-v4-db-1 psql -U postgres -t -c "SELECT COUNT(*) FROM tasks WHERE user_id='$USER_ID';" | tr -d ' ')
  
  if [ "$TASKS_COUNT" -gt "0" ]; then
    echo -e "${GREEN}✅ $TASKS_COUNT tarefas encontradas para o usuário administrador${NC}"
  else
    echo -e "${RED}❌ Nenhuma tarefa encontrada para o usuário administrador${NC}"
  fi
}

# Verificar a estrutura da tabela de logs
check_logs_table() {
  echo -e "Verificando a estrutura da tabela system_logs..."
  if docker exec orga-ai-v4-db-1 psql -U postgres -t -c "\d system_logs" | grep -q "level"; then
    echo -e "${GREEN}✅ Tabela system_logs tem os campos necessários${NC}"
  else
    echo -e "${RED}❌ Tabela system_logs não tem todos os campos necessários${NC}"
  fi
}

# Verificar endpoints do backend
check_backend_endpoints() {
  echo -e "Verificando endpoint PUT de logs no backend..."
  RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X OPTIONS http://localhost:8000/api/v1/admin/logs)
  
  if [ "$RESPONSE_CODE" -eq "200" ] || [ "$RESPONSE_CODE" -eq "204" ]; then
    echo -e "${GREEN}✅ Endpoint de logs está respondendo${NC}"
  else
    echo -e "${RED}❌ Endpoint de logs não está respondendo corretamente (código: $RESPONSE_CODE)${NC}"
  fi
}

# Executar as verificações
echo -e "\n${YELLOW}Verificando serviços...${NC}"
check_service "db"
check_service "backend"
check_service "ollama"
check_service "n8n"

echo -e "\n${YELLOW}Verificando dados...${NC}"
check_user_tasks
check_logs_table

echo -e "\n${YELLOW}Verificando backend...${NC}"
check_backend_endpoints

echo -e "\n${YELLOW}=== Instruções para testes manuais ===${NC}"
echo -e "1. Acesse a interface do n8n em http://localhost:5678"
echo -e "2. Ative o workflow 'n8n_email_daily_tasks' e execute-o"
echo -e "3. Verifique nos logs se o email foi gerado corretamente"
echo -e "4. Teste também o workflow 'n8n_email_diario_sem_ia'"

echo -e "\n${GREEN}Script de teste concluído.${NC}"
echo -e "${YELLOW}Para mais detalhes, consulte:${NC}"
echo -e "- cookbooks/n8n-flows/FINAL_SOLUTION.md"
echo -e "- cookbooks/n8n-flows/CORRECAO_TASKS_USER_ID_15_05_2025.md"
echo -e "- cookbooks/n8n-flows/CORRECAO_ENDPOINTS_LOGS_15_05_2025.md"
