#!/bin/bash
set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Orga.AI Project Reinstallation Script (Preserving N8N Data) ===${NC}"
echo -e "${YELLOW}This script will remove most containers and volumes, but preserve n8n data${NC}"
echo

# Stop and remove all containers
echo -e "${BLUE}Step 1: Stopping and removing all containers...${NC}"
docker-compose down --remove-orphans
echo -e "${GREEN}✓ All containers removed${NC}"
echo

# Backup n8n data
echo -e "${BLUE}Step 2: Backing up n8n data...${NC}"
if [ -d "./volumes/n8n" ]; then
  mkdir -p ./volumes/backup
  cp -r ./volumes/n8n ./volumes/backup/n8n_backup_$(date +%Y%m%d_%H%M%S)
  echo -e "${GREEN}✓ N8N data backed up${NC}"
else
  echo -e "${YELLOW}! No n8n data to backup${NC}"
fi
echo

# Clean up docker volumes (preserving n8n)
echo -e "${BLUE}Step 3: Cleaning up Docker volumes (preserving n8n)...${NC}"
rm -rf ./volumes/db/data
rm -rf ./volumes/storage
# NÃO remove o volume do n8n
mkdir -p ./volumes/db/data
mkdir -p ./volumes/storage
mkdir -p ./volumes/n8n
echo -e "${GREEN}✓ Docker volumes cleaned (n8n data preserved)${NC}"
echo

# Clean up frontend build artifacts
echo -e "${BLUE}Step 4: Cleaning frontend build artifacts...${NC}"
if [ -d "./frontend/.next" ]; then
  rm -rf ./frontend/.next
  echo -e "${GREEN}✓ Frontend build artifacts cleaned${NC}"
else
  echo -e "${YELLOW}! No frontend build artifacts found${NC}"
fi
echo

# Rebuild everything
echo -e "${BLUE}Step 5: Rebuilding and starting all services...${NC}"
docker-compose build --no-cache
echo -e "${GREEN}✓ All services rebuilt${NC}"
echo

# Start services
echo -e "${BLUE}Step 6: Starting all services...${NC}"
docker-compose up -d
echo -e "${GREEN}✓ All services started${NC}"
echo

# Aguardar banco de dados estar pronto
echo -e "${BLUE}Step 7: Aguardando banco de dados iniciar...${NC}"
sleep 15  # Dar tempo suficiente para o banco de dados inicializar
echo -e "${GREEN}✓ Banco de dados deve estar pronto${NC}"
echo

# Executar scripts SQL de migração
echo -e "${BLUE}Step 8: Executando migrações SQL...${NC}"
./scripts/sh/run-migrations.sh
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Migrações SQL executadas com sucesso${NC}"
else
    echo -e "${RED}✗ Falha ao executar migrações SQL${NC}"
    echo -e "${YELLOW}Verifique os logs para mais detalhes${NC}"
fi
echo

echo -e "${BLUE}Checking service health...${NC}"
sleep 10
docker-compose ps
echo

echo -e "${GREEN}=== Reinstallation complete! ===${NC}"
echo -e "${YELLOW}Frontend:${NC} http://localhost:3010"
echo -e "${YELLOW}Backend API:${NC} http://localhost:8000/api/docs"
echo -e "${YELLOW}Supabase Studio:${NC} http://localhost:54323"
echo -e "${YELLOW}N8N:${NC} http://localhost:5678"
echo
echo -e "${BLUE}Watch logs with:${NC} docker-compose logs -f [service-name]"
