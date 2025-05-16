#!/bin/bash
#
# Script para atualizar referências a nomes de workflows
# Data: 11/05/2025
# Autor: Orga.AI Team

# Definir cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Atualizando referências a nomes de workflows...${NC}"

# Caminho base dos arquivos
BASE_PATH="/Users/angelosagnori/Downloads/orga-ai-v4"
DOCS_PATH="${BASE_PATH}/cookbooks/n8n-flows"

# Lista de arquivos a serem processados
FILES=(
  "${DOCS_PATH}/SOLUCAO_WORKFLOW_OLLAMA_15_05_2025.md"
  "${DOCS_PATH}/SOLUCAO_WORKFLOWS_11_05_2025.md"
  "${DOCS_PATH}/GUIA_TESTE_WORKFLOW_N8N.md"
  "${DOCS_PATH}/VERIFICACAO_CORRECOES_15_05_2025.md"
  "${BASE_PATH}/scripts/sh/test-n8n-workflow.sh"
)

# Contador de arquivos processados
PROCESSED=0

for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    echo -e "Processando ${file}..."
    
    # Substituir n8n_email_daily_tasks_fixed por n8n_email_daily_tasks
    sed -i '' 's/n8n_email_daily_tasks_fixed/n8n_email_daily_tasks/g' "$file"
    
    # Substituir n8n_email_diario_sem_ollama_fixed por n8n_email_diario_sem_ia
    sed -i '' 's/n8n_email_diario_sem_ollama_fixed/n8n_email_diario_sem_ia/g' "$file"
    
    # Substituir fixed_workflow_with_debug por n8n_email_daily_tasks (ID)
    sed -i '' 's/fixed_workflow_with_debug/n8n_email_daily_tasks/g' "$file"
    
    # Substituir fixed_workflow_sem_ollama por n8n_email_diario_sem_ia (ID)
    sed -i '' 's/fixed_workflow_sem_ollama/n8n_email_diario_sem_ia/g' "$file"
    
    # Substituir versionId fixed-* por novos versionId
    sed -i '' 's/fixed-2025-05-11/2025-05-11/g' "$file"
    sed -i '' 's/fixed-sem-ollama-2025-05-11/sem-ia-2025-05-11/g' "$file"
    
    PROCESSED=$((PROCESSED+1))
    echo -e "${GREEN}✅ Arquivo atualizado com sucesso${NC}"
  else
    echo -e "${RED}❌ Arquivo não encontrado: ${file}${NC}"
  fi
done

echo -e "\n${GREEN}Processamento concluído! ${PROCESSED} arquivos foram atualizados.${NC}"

# Criar um registro da atualização
echo "Atualização de nomes de workflow realizada em $(date)" > "${DOCS_PATH}/ATUALIZACAO_NOMES_WORKFLOWS_$(date +%Y%m%d).log"
echo "Foram atualizados ${PROCESSED} arquivos para refletir os novos nomes dos workflows." >> "${DOCS_PATH}/ATUALIZACAO_NOMES_WORKFLOWS_$(date +%Y%m%d).log"
echo "Workflows renomeados:" >> "${DOCS_PATH}/ATUALIZACAO_NOMES_WORKFLOWS_$(date +%Y%m%d).log"
echo "- n8n_email_daily_tasks_fixed → n8n_email_daily_tasks" >> "${DOCS_PATH}/ATUALIZACAO_NOMES_WORKFLOWS_$(date +%Y%m%d).log"
echo "- n8n_email_diario_sem_ollama_fixed → n8n_email_diario_sem_ia" >> "${DOCS_PATH}/ATUALIZACAO_NOMES_WORKFLOWS_$(date +%Y%m%d).log"

echo -e "\n${YELLOW}Um registro da atualização foi salvo em:${NC}"
echo -e "${DOCS_PATH}/ATUALIZACAO_NOMES_WORKFLOWS_$(date +%Y%m%d).log"
