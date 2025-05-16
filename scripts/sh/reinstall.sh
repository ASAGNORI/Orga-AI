#!/bin/zsh

# Script de reinstalação e migração do banco de dados
# Data: 14 de maio de 2025

# Definir cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] AVISO:${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERRO:${NC} $1"
    exit 1
}

# Diretório do projeto
PROJECT_DIR="/Users/angelosagnori/Downloads/orga-ai-v4"
SQL_DIR="${PROJECT_DIR}/scripts/sql"
BACKUP_DIR="${SQL_DIR}/backup_$(date +%Y%m%d)"

# Verificar se estamos no diretório correto
if [[ ! -d "$PROJECT_DIR" ]]; then
    error "Diretório do projeto não encontrado: $PROJECT_DIR"
fi

# Criar diretório de backup se não existir
mkdir -p "$BACKUP_DIR"

log "Iniciando processo de reinstalação..."

# Parar todos os containers
log "Parando containers..."
docker compose down -v || error "Falha ao parar containers"

# Limpar volumes
log "Limpando volumes..."
rm -rf "${PROJECT_DIR}/volumes/db/*" || warn "Falha ao limpar volumes de DB"
rm -rf "${PROJECT_DIR}/volumes/storage/*" || warn "Falha ao limpar volumes de storage"

# Reconstruir containers
log "Reconstruindo containers..."
docker compose build --no-cache || error "Falha na reconstrução dos containers"

# Iniciar containers
log "Iniciando containers..."
docker compose up -d || error "Falha ao iniciar containers"

# Aguardar PostgreSQL estar pronto
log "Aguardando PostgreSQL inicializar..."
for i in {1..30}; do
    if docker compose exec db pg_isready &>/dev/null; then
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

# Verificar se PostgreSQL está pronto
if ! docker compose exec db pg_isready &>/dev/null; then
    error "PostgreSQL não iniciou corretamente"
fi

# Executar migrações em ordem
log "Executando migrações..."

MIGRATION_FILES=(
    "001_fix_auth_consolidated.sql"
    "002_fix_relations_consolidated.sql"
    "003_add_fields_consolidated.sql"
    "004_update_features_consolidated.sql"
)

for file in "${MIGRATION_FILES[@]}"; do
    if [[ -f "${SQL_DIR}/${file}" ]]; then
        log "Executando migração: ${file}"
        docker compose exec db psql -U postgres -d postgres -f "/docker-entrypoint-initdb.d/${file}" || error "Falha ao executar ${file}"
    else
        error "Arquivo de migração não encontrado: ${file}"
    fi
done

# Backup e limpeza do Ollama
echo -e "${YELLOW}Cleaning Ollama data but preserving downloaded models...${NC}"
if [ -d "./volumes/ollama_data" ]; then
  # Preservar apenas os modelos baixados
  mkdir -p /tmp/ollama_models_backup
  if [ -d "./volumes/ollama_data/models" ]; then
    cp -r ./volumes/ollama_data/models /tmp/ollama_models_backup/
    echo -e "${YELLOW}✓ Ollama models backed up${NC}"
  fi
  
  # Fazer backup do modelo personalizado optimized-gemma3
  if [ -f "./volumes/ollama_data/manifests/registry.ollama.ai/library/optimized-gemma3/latest/manifest.json" ]; then
    mkdir -p /tmp/ollama_models_backup/manifests/registry.ollama.ai/library/optimized-gemma3/latest/
    cp -r ./volumes/ollama_data/manifests/registry.ollama.ai/library/optimized-gemma3 /tmp/ollama_models_backup/manifests/registry.ollama.ai/library/
    echo -e "${YELLOW}✓ Custom model optimized-gemma3 backed up${NC}"
  fi
  
  # Limpar diretório do Ollama
  rm -rf ./volumes/ollama_data
  mkdir -p ./volumes/ollama_data
  
  # Restaurar modelos
  if [ -d "/tmp/ollama_models_backup/models" ]; then
    mkdir -p ./volumes/ollama_data/models
    cp -r /tmp/ollama_models_backup/models ./volumes/ollama_data/
    echo -e "${YELLOW}✓ Ollama models restored${NC}"
  fi
  
  # Restaurar modelo personalizado
  if [ -d "/tmp/ollama_models_backup/manifests" ]; then
    mkdir -p ./volumes/ollama_data/manifests/registry.ollama.ai/library/
    cp -r /tmp/ollama_models_backup/manifests/registry.ollama.ai/library/optimized-gemma3 ./volumes/ollama_data/manifests/registry.ollama.ai/library/
    echo -e "${YELLOW}✓ Custom model optimized-gemma3 restored${NC}"
  fi
  
  rm -rf /tmp/ollama_models_backup
else
  mkdir -p ./volumes/ollama_data
  echo -e "${YELLOW}! No Ollama data found, creating fresh directory${NC}"
fi

# Preservar workflows n8n
log "Preservando dados do n8n..."
mkdir -p "${PROJECT_DIR}/volumes/n8n"

# Limpar e recriar diretórios necessários
log "Recriando diretórios necessários..."
mkdir -p "${PROJECT_DIR}/volumes/db/data"
mkdir -p "${PROJECT_DIR}/volumes/storage"

# Limpar frontend build artifacts
log "Limpando artefatos de build do frontend..."
if [[ -d "${PROJECT_DIR}/frontend/.next" ]]; then
    rm -rf "${PROJECT_DIR}/frontend/.next"
    log "Artefatos de build do frontend limpos"
else
    warn "Nenhum artefato de build encontrado"
fi
echo

# Verificar status final
log "Verificando status final..."
if docker compose ps | grep -q "Exit"; then
    error "Alguns containers não estão rodando corretamente"
fi

log "Reinstalação concluída com sucesso!"
log "Para visualizar os logs, use: docker compose logs -f"

# Mostrar status dos containers
docker compose ps

# Mostrar URLs de acesso
log "URLs de acesso:"
log "Frontend: http://localhost:3010"
log "Backend API: http://localhost:8000/api/docs"
log "Supabase Studio: http://localhost:54323"
log "N8N: http://localhost:5678"
log "Open-WebUI (Interface Ollama): http://localhost:3000"
echo -e "   docker-compose exec ollama ollama list | grep optimized-gemma3"
echo

echo -e "${BLUE}Watch logs with:${NC} docker-compose logs -f [service-name]"