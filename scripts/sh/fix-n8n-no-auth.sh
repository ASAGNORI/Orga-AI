#!/bin/bash

# Script para forçar o n8n a funcionar sem autenticação
# Autor: GitHub Copilot
# Data: 13/05/2025

# Cores para formatação
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sem cor

echo -e "${BLUE}=== Correção de Acesso ao n8n (Modo sem autenticação) ===${NC}"
echo

# Verifica se estamos no diretório correto
if [ ! -f docker-compose.yml ]; then
  echo -e "${RED}Erro: Execute este script no diretório raiz do projeto (onde está o docker-compose.yml)${NC}"
  exit 1
fi

# Atualiza o arquivo .env com configuração sem autenticação
if [ -f .env ]; then
  echo -e "${BLUE}Configurando n8n para modo sem autenticação...${NC}"
  
  # Faz backup do arquivo .env
  cp .env .env.bak.$(date +"%Y%m%d%H%M%S")
  echo -e "${GREEN}✅ Backup do arquivo .env criado${NC}"
  
  # Desativa todo tipo de autenticação
  sed -i '' 's/N8N_BASIC_AUTH_ACTIVE=true/N8N_BASIC_AUTH_ACTIVE=false/g' .env
  sed -i '' 's/N8N_USER_MANAGEMENT_DISABLED=false/N8N_USER_MANAGEMENT_DISABLED=true/g' .env
  
  echo -e "${GREEN}✅ Autenticação desativada no arquivo .env${NC}"
fi

# Remove o volume e container do n8n para forçar recriação limpa
echo -e "${YELLOW}Removendo container e volume do n8n...${NC}"
docker-compose down n8n
docker volume rm -f orga-ai-v4_n8n_data || true

# Inicia o n8n novamente
echo -e "${BLUE}Iniciando o n8n novamente...${NC}"
docker-compose up -d n8n

# Aguarda o serviço iniciar
echo -e "${YELLOW}Aguardando o serviço n8n iniciar (15 segundos)...${NC}"
sleep 15

echo -e "${GREEN}=== Processo concluído! ===${NC}"
echo -e "${GREEN}O n8n agora deve estar acessível sem necessidade de login em:${NC}"
echo -e "${BLUE}http://localhost:5678${NC}"
echo
echo -e "${YELLOW}NOTA: O n8n está configurado para funcionar sem autenticação.${NC}"
echo -e "${YELLOW}Isso é adequado apenas para ambiente de desenvolvimento local.${NC}"
