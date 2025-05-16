#!/bin/zsh
# Script para testar a funcionalidade de logs do n8n com o campo user_id
# Data: 12/05/2025
# Autor: GitHub Copilot

# Definir cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Testando funcionalidade de logs do n8n com campo user_id...${NC}"

# Gerar um UUID aleatório para simular um ID de usuário
USER_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
echo -e "Usando UUID gerado para teste: ${USER_UUID}"

# URL e token de autenticação (substitua pelo seu token real de admin)
API_URL="http://localhost:8000/api/v1/admin/logs"
TOKEN="seu-token-de-admin-aqui" # Substitua por um token válido se necessário

echo -e "\n${YELLOW}Testando método PUT com user_id explícito...${NC}"
curl -X PUT \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"level\": \"info\",
    \"source\": \"test_script\",
    \"message\": \"Teste de log com user_id\",
    \"user_id\": \"${USER_UUID}\",
    \"details\": {
      \"workflow\": \"teste_curl\",
      \"user_id\": \"${USER_UUID}\",
      \"task_count\": 5,
      \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
    }
  }" \
  $API_URL

echo -e "\n\n${YELLOW}Verificando logs recentes no banco de dados...${NC}"
docker exec orga-ai-v4-db-1 psql -U postgres -d postgres -c "SELECT id, level, source, message, user_id, created_at FROM system_logs WHERE source = 'test_script' ORDER BY created_at DESC LIMIT 5;"

echo -e "\n${GREEN}Teste concluído!${NC}"
echo -e "Se o teste foi bem-sucedido, você deve ver um log com o UUID: ${USER_UUID}"
