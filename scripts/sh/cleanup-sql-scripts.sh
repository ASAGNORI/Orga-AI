#!/bin/bash

# Script para remover arquivos SQL redundantes e manter apenas aqueles necessários
# Este script deve ser executado depois de criar o arquivo 001_fix_auth_consolidated.sql

# Cores para melhor visualização
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Limpeza de Scripts SQL Redundantes ===${NC}"
echo -e "${YELLOW}Este script irá mover arquivos SQL redundantes para um diretório de backup${NC}"
echo

# Criar diretório de backup se não existir
BACKUP_DIR="/Users/angelosagnori/Downloads/orga-ai-v4/scripts/sql/backup"
SCRIPTS_DIR="/Users/angelosagnori/Downloads/orga-ai-v4/scripts/sql"

mkdir -p "$BACKUP_DIR"
echo -e "${GREEN}✓ Diretório de backup criado: $BACKUP_DIR${NC}"
echo

# Lista de arquivos que serão movidos para o backup (redundantes)
# Estes são os arquivos que o script consolidado substitui
REDUNDANT_FILES=(
    "fix-auth.sql"
    "add_full_name_column.sql"
    "fix_user_table_ids.sql"
)

# Mover arquivos redundantes para o diretório de backup
for file in "${REDUNDANT_FILES[@]}"; do
    if [ -f "$SCRIPTS_DIR/$file" ]; then
        # Verificar se o arquivo já existe no backup
        if [ -f "$BACKUP_DIR/$file" ]; then
            # Adicionar timestamp ao nome do arquivo para não sobrescrever
            TIMESTAMP=$(date +%Y%m%d_%H%M%S)
            cp "$SCRIPTS_DIR/$file" "$BACKUP_DIR/${file%.sql}_$TIMESTAMP.sql"
            echo -e "${YELLOW}! Arquivo $file já existe no backup, copiado com timestamp${NC}"
        else
            cp "$SCRIPTS_DIR/$file" "$BACKUP_DIR/"
            echo -e "${GREEN}✓ Arquivo $file copiado para o backup${NC}"
        fi
        
        # Remover o arquivo original
        rm "$SCRIPTS_DIR/$file"
        echo -e "${GREEN}✓ Arquivo $file removido do diretório de scripts${NC}"
    else
        echo -e "${YELLOW}! Arquivo $file não encontrado, pulando...${NC}"
    fi
done

echo
echo -e "${BLUE}=== Verificação de Prioridade de Execução ===${NC}"

# Verificar se o arquivo consolidado existe
if [ -f "$SCRIPTS_DIR/001_fix_auth_consolidated.sql" ]; then
    echo -e "${GREEN}✓ Script consolidado encontrado e será executado primeiro${NC}"
else
    echo -e "${RED}✗ Script consolidado não encontrado. Isso pode causar problemas!${NC}"
fi

# Listar arquivos restantes
echo
echo -e "${BLUE}=== Scripts SQL Restantes ===${NC}"
ls -la "$SCRIPTS_DIR"

echo
echo -e "${GREEN}=== Limpeza Concluída! ===${NC}"
echo -e "${YELLOW}Os seguintes arquivos foram considerados redundantes e movidos para backup:${NC}"
for file in "${REDUNDANT_FILES[@]}"; do
    echo "  - $file"
done
echo
echo -e "${BLUE}Agora você pode executar ./scripts/sh/reinstall.sh para aplicar as correções.${NC}"
