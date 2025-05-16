#!/bin/bash
set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Orga.AI: N8N Password Reset Script ===${NC}"
echo -e "${YELLOW}Este script vai resetar as credenciais do n8n no arquivo .env${NC}"
echo

# Default credentials
DEFAULT_USER="admin"
DEFAULT_PASSWORD="admin123"
DEFAULT_EMAIL="admin@example.com"

# Ask for credentials
read -p "Digite o nome de usuário (ou deixe em branco para usar '$DEFAULT_USER'): " username
username=${username:-$DEFAULT_USER}

read -p "Digite a senha (ou deixe em branco para usar '$DEFAULT_PASSWORD'): " password
password=${password:-$DEFAULT_PASSWORD}

read -p "Digite o email (ou deixe em branco para usar '$DEFAULT_EMAIL'): " email
email=${email:-$DEFAULT_EMAIL}

echo
echo -e "${YELLOW}As seguintes credenciais serão definidas:${NC}"
echo -e "Usuário: ${username}"
echo -e "Senha: ${password}"
echo -e "Email: ${email}"
echo

read -p "Confirma? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo -e "${RED}Operação cancelada${NC}"
    exit 0
fi

# Update .env file
echo -e "${BLUE}Atualizando arquivo .env...${NC}"
sed -i '' "s/N8N_BASIC_AUTH_USER=.*/N8N_BASIC_AUTH_USER=${username}/g" .env
sed -i '' "s/N8N_BASIC_AUTH_PASSWORD=.*/N8N_BASIC_AUTH_PASSWORD=${password}/g" .env
sed -i '' "s/N8N_BASIC_AUTH_EMAIL=.*/N8N_BASIC_AUTH_EMAIL=${email}/g" .env

# Ensure auth is active
if grep -q "N8N_BASIC_AUTH_ACTIVE=false" .env; then
  echo -e "${YELLOW}Autenticação básica está desativada. Ativando...${NC}"
  sed -i '' "s/N8N_BASIC_AUTH_ACTIVE=false/N8N_BASIC_AUTH_ACTIVE=true/g" .env
fi

# Update dashboard credentials
sed -i '' "s/DASHBOARD_USERNAME=.*/DASHBOARD_USERNAME=${username}/g" .env
sed -i '' "s/DASHBOARD_PASSWORD=.*/DASHBOARD_PASSWORD=${password}/g" .env
sed -i '' "s/DASHBOARD_EMAIL=.*/DASHBOARD_EMAIL=${email}/g" .env
sed -i '' "s/DASHBOARD_ADMIN_USERNAME=.*/DASHBOARD_ADMIN_USERNAME=${username}/g" .env
sed -i '' "s/DASHBOARD_ADMIN_PASSWORD=.*/DASHBOARD_ADMIN_PASSWORD=${password}/g" .env
sed -i '' "s/DASHBOARD_ADMIN_EMAIL=.*/DASHBOARD_ADMIN_EMAIL=${email}/g" .env

echo -e "${GREEN}✓ Credenciais atualizadas no arquivo .env${NC}"
echo

# Restart n8n
echo -e "${BLUE}Reiniciando n8n para aplicar as alterações...${NC}"
docker-compose restart n8n
echo -e "${GREEN}✓ n8n reiniciado!${NC}"
echo

echo -e "${BLUE}=== Novas credenciais do n8n ===${NC}"
echo -e "${YELLOW}URL:${NC} http://localhost:5678"
echo -e "${YELLOW}Usuário:${NC} ${username}"
echo -e "${YELLOW}Senha:${NC} ${password}"
echo
echo -e "${GREEN}=== Reset de senha concluído! ===${NC}"
