#!/bin/zsh
# Script para aplicar a migração que adiciona o campo level ao modelo SystemLog
# Data: 12/05/2025
# Autor: GitHub Copilot

# Definir cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Aplicando migração para adicionar campo level ao modelo SystemLog...${NC}"

# Caminho para o arquivo SQL
SQL_FILE="/Users/angelosagnori/Downloads/orga-ai-v4/scripts/sql/add_level_to_systemlog.sql"

# Verificar se o arquivo SQL existe
if [ ! -f "$SQL_FILE" ]; then
    echo -e "${RED}❌ Arquivo SQL não encontrado: $SQL_FILE${NC}"
    exit 1
fi

# Executar o script SQL no container Postgres
echo -e "Executando migração via Docker..."
docker exec -i orga-ai-v4-db-1 psql -U postgres -d postgres < "$SQL_FILE"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Migração aplicada com sucesso!${NC}"
else
    echo -e "${RED}❌ Erro ao aplicar migração SQL${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Reiniciando o container backend para aplicar as alterações...${NC}"
docker restart orga-ai-v4-backend-1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Container backend reiniciado com sucesso!${NC}"
    echo -e "Aguardando 10 segundos para o serviço inicializar..."
    sleep 10
else
    echo -e "${RED}❌ Erro ao reiniciar o container backend${NC}"
    exit 1
fi

echo -e "\n${GREEN}Processo de migração concluído!${NC}"
echo -e "Agora os workflows n8n devem conseguir registrar logs com o campo level corretamente."
echo -e "\nPara testar, execute: ${YELLOW}./scripts/sh/test-n8n-logs.sh${NC}"
