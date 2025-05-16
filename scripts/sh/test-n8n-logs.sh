#!/bin/zsh
# Script para testar a funcionalidade de logs do n8n
# Data: 12/05/2025
# Autor: GitHub Copilot

# Definir cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Testando funcionalidade de logs do n8n...${NC}"

# URL e token de autenticação (substitua pelo seu token real de admin)
API_URL="http://localhost:8000/api/v1/admin/logs"
TOKEN="seu-token-de-admin-aqui" # Substitua por um token válido se necessário

# Testar método PUT (usado pelo n8n)
echo -e "\n${YELLOW}Testando método PUT...${NC}"
curl -X PUT \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "level": "info",
    "source": "test_script",
    "message": "Teste de log via PUT",
    "details": {
      "workflow": "teste_curl",
      "timestamp": "'"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"'"
    }
  }' \
  $API_URL

echo -e "\n\n${YELLOW}Testando método POST...${NC}"
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "level": "warning",
    "source": "test_script",
    "message": "Teste de log via POST",
    "details": {
      "workflow": "teste_curl",
      "timestamp": "'"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"'"
    }
  }' \
  $API_URL

echo -e "\n\n${YELLOW}Verificando logs recentes no banco de dados...${NC}"
docker exec orga-ai-v4-db-1 psql -U postgres -d postgres -c "SELECT id, level, source, message, created_at FROM system_logs ORDER BY created_at DESC LIMIT 5;"

echo -e "\n${GREEN}Teste concluído!${NC}"
