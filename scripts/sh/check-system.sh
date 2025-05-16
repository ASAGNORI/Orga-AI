#!/bin/bash

# Script de verificação de status do sistema Orga.AI
# Autor: GitHub Copilot
# Data: 13/05/2025

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

check_service() {
  local service=$1
  local status=$(docker-compose ps $service | grep $service || echo "not running")
  if [[ $status == *"Up"* ]]; then
    echo -e "${GREEN}✅ $service está rodando${NC}"
    return 0
  else
    echo -e "${RED}❌ $service não está rodando${NC}"
    return 1
  fi
}

echo -e "${BLUE}=== Verificação de Status do Sistema Orga.AI ===${NC}"
echo

# Verifica se estamos no diretório correto
if [ ! -f docker-compose.yml ]; then
  echo -e "${RED}Erro: Execute este script no diretório raiz do projeto (onde está o docker-compose.yml)${NC}"
  exit 1
fi

# Verifica o status dos serviços principais
echo -e "${YELLOW}Verificando status dos serviços principais...${NC}"
services=("backend" "frontend" "db" "n8n" "ollama")

all_ok=true

for service in "${services[@]}"; do
  check_service $service || all_ok=false
done

echo

# Verificar n8n sem autenticação
echo -e "${YELLOW}Verificando configuração do n8n...${NC}"

if grep -q "N8N_BASIC_AUTH_ACTIVE=false" .env && grep -q "N8N_USER_MANAGEMENT_DISABLED=true" .env; then
  echo -e "${GREEN}✅ n8n está configurado para acesso sem autenticação${NC}"
else
  echo -e "${RED}❌ n8n não está configurado para acesso sem autenticação${NC}"
  echo -e "${YELLOW}Dica: Execute o script fix-n8n-no-auth.sh para corrigir${NC}"
  all_ok=false
fi

# Verificar backend /api/v1/health
echo -e "${YELLOW}Verificando API de saúde do backend...${NC}"
health_response=$(curl -s http://localhost:8000/api/v1/health || echo "error")

if [[ $health_response == *"status"*"ok"* ]]; then
  echo -e "${GREEN}✅ Backend API está respondendo corretamente${NC}"
else
  echo -e "${RED}❌ Backend API não está respondendo corretamente: $health_response${NC}"
  all_ok=false
fi

echo

# Resumo final
echo -e "${BLUE}=== Resumo da Verificação ===${NC}"
if $all_ok; then
  echo -e "${GREEN}✅ Todos os serviços estão funcionando corretamente!${NC}"
else
  echo -e "${RED}❌ Alguns serviços precisam de atenção.${NC}"
  
  echo -e "${YELLOW}Dicas de solução:${NC}"
  echo "1. Para reiniciar um serviço específico: docker-compose restart <serviço>"
  echo "2. Para corrigir o n8n: ./scripts/sh/fix-n8n-no-auth.sh"
  echo "3. Para ver logs detalhados: docker-compose logs <serviço>"
fi

echo
echo -e "${BLUE}Acessos:${NC}"
echo "• Frontend: http://localhost:3010"
echo "• Backend API: http://localhost:8000/api/docs"
echo "• n8n: http://localhost:5678"
echo "• Ollama WebUI: http://localhost:3000"
