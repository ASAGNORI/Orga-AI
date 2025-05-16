#!/bin/bash
set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Orga.AI: N8N Reinstallation Script ===${NC}"
echo -e "${YELLOW}This script will completely reinstall the n8n service${NC}"
echo

# Confirm before proceeding
read -p "This will delete all n8n data including workflows. Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo -e "${RED}Operation cancelled${NC}"
    exit 0
fi

# Stop n8n container
echo -e "${BLUE}Step 1: Stopping n8n container...${NC}"
docker-compose stop n8n
echo -e "${GREEN}✓ n8n container stopped${NC}"
echo

# Remove n8n volumes
echo -e "${BLUE}Step 2: Removing n8n data...${NC}"
docker-compose rm -f n8n
rm -rf ./volumes/n8n
mkdir -p ./volumes/n8n
echo -e "${GREEN}✓ n8n data removed${NC}"
echo

# Rebuild n8n
echo -e "${BLUE}Step 3: Rebuilding n8n container...${NC}"
docker-compose build --no-cache n8n
echo -e "${GREEN}✓ n8n container rebuilt${NC}"
echo

# Start n8n
echo -e "${BLUE}Step 4: Starting n8n container...${NC}"
docker-compose up -d n8n
echo -e "${GREEN}✓ n8n container started${NC}"
echo

# Wait for n8n to be ready
echo -e "${BLUE}Step 5: Waiting for n8n to be ready...${NC}"
echo -e "${YELLOW}This may take 15-30 seconds...${NC}"
for i in {1..15}; do
  if curl -s http://localhost:5678 >/dev/null; then
    echo -e "${GREEN}✓ n8n is ready!${NC}"
    break
  fi
  echo -n "."
  sleep 2
  if [ $i -eq 15 ]; then
    echo -e "${YELLOW}! n8n might not be fully ready yet, but continuing...${NC}"
  fi
done
echo

# Print credentials
echo -e "${BLUE}=== N8N Credentials ===${NC}"
echo -e "${YELLOW}URL:${NC} http://localhost:5678"
echo -e "${YELLOW}Username:${NC} admin"
echo -e "${YELLOW}Password:${NC} admin123"
echo
echo -e "${GREEN}=== N8N Reinstallation Complete! ===${NC}"
echo -e "${YELLOW}Certifique-se que N8N_BASIC_AUTH_ACTIVE=true no .env para usar autenticação${NC}"
echo

# Check if basic auth is enabled
if grep -q "N8N_BASIC_AUTH_ACTIVE=false" .env; then
  echo -e "${YELLOW}⚠️ Autenticação básica está DESATIVADA. Ativar agora? (y/n)${NC} "
  read -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    sed -i '' 's/N8N_BASIC_AUTH_ACTIVE=false/N8N_BASIC_AUTH_ACTIVE=true/g' .env
    echo -e "${GREEN}✓ Autenticação básica ATIVADA${NC}"
    echo -e "${YELLOW}Reiniciando n8n para aplicar a configuração...${NC}"
    docker-compose restart n8n
    echo -e "${GREEN}✓ n8n reiniciado!${NC}"
  fi
fi

echo
echo -e "${BLUE}Para configurar o n8n, use:${NC}"
echo -e "${YELLOW}./cookbooks/n8n-flows/setup_n8n.sh${NC}"
