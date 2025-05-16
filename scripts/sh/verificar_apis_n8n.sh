#!/bin/bash

# Script para verificar a estrutura de resposta dos endpoints usados pelo N8N
# Data: 11 de maio de 2025
# Autor: Orga.AI Team

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Token de autenticação para a API (substitua pelo seu token)
# Este script assume que você definiu uma variável de ambiente TOKEN com seu token de autenticação
if [ -z "$TOKEN" ]; then
  echo -e "${RED}Erro: Variável de ambiente TOKEN não definida.${NC}"
  echo -e "Execute: ${YELLOW}export TOKEN=\"seu-token-aqui\"${NC}"
  exit 1
fi

# Cabeçalho
echo -e "${BLUE}=== Verificação da Estrutura de APIs para N8N ===${NC}"
echo -e "${BLUE}$(date)${NC}"
echo ""

# 1. Verificar o endpoint de usuários
echo -e "${YELLOW}1. Verificando endpoint de usuários...${NC}"
usuarios_response=$(curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/v1/admin/users | jq '.')
echo -e "${GREEN}Resposta:${NC}"
echo "$usuarios_response" | jq '.' | head -n 20
echo -e "${MAGENTA}* Estrutura para N8N: No nó 'Processar por Usuário', acesse \$json['0'].id para o ID${NC}"
echo ""

# 2. Verificar o endpoint de tarefas (usando um ID de usuário real)
usuario_id=$(echo "$usuarios_response" | jq '.[0].id')
if [ -z "$usuario_id" ] || [ "$usuario_id" == "null" ]; then
  echo -e "${RED}Não foi possível obter um ID de usuário válido.${NC}"
else
  echo -e "${YELLOW}2. Verificando endpoint de tarefas para usuário $usuario_id...${NC}"
  tarefas_response=$(curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8000/api/v1/admin/tasks/user/$usuario_id" | jq '.')
  echo -e "${GREEN}Resposta:${NC}"
  echo "$tarefas_response" | jq '.' | head -n 20
  echo ""
fi

# 3. Verificar o endpoint de logs (método POST)
echo -e "${YELLOW}3. Testando endpoint de logs (POST)...${NC}"
log_data='{
  "level": "info",
  "source": "test_script",
  "message": "Teste de registro de log para N8N",
  "details": {
    "test": true,
    "date": "'$(date)'"
  }
}'

log_response=$(curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d "$log_data" http://localhost:8000/api/v1/admin/logs)
echo -e "${GREEN}Resposta:${NC}"
echo "$log_response" | jq '.' 
echo ""

# Resumo
echo -e "${BLUE}=== Resumo da Análise ===${NC}"
echo -e "1. Endpoint de Usuários: ${GREEN}http://backend:8000/api/v1/admin/users${NC}"
echo -e "   - Método: ${YELLOW}GET${NC}"
echo -e "   - No N8N: Acesse \$json['0'].id, \$json['0'].name, \$json['0'].email"
echo ""
echo -e "2. Endpoint de Tarefas: ${GREEN}http://backend:8000/api/v1/admin/tasks/user/{id}${NC}"
echo -e "   - Método: ${YELLOW}GET${NC}"
echo -e "   - No N8N: Use URL com {{$json['0'].id}}"
echo ""
echo -e "3. Endpoint de Logs: ${GREEN}http://backend:8000/api/v1/admin/logs${NC}"
echo -e "   - Método: ${YELLOW}POST${NC}"
echo -e "   - No N8N: Definir método explicitamente como POST"
echo -e "   - Corpo: JSON com level, source, message e details"
