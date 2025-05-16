#!/bin/bash
# Script para manutenção automática do Open WebUI
# Este script gerencia sincronização de usuários, backups e manutenção
# Criado em: maio/2025
# Licença: MIT

set -e

# Função de log
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Diretório do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Ir para a raiz do projeto
cd "$PROJECT_ROOT"

# Carregar variáveis de ambiente
if [ ! -f .env ]; then
    log "❌ Arquivo .env não encontrado. Criando a partir do exemplo..."
    cp .env.example .env
fi
source .env

# Verificar containers em execução
log "🔍 Verificando serviços em execução..."
if ! docker compose ps | grep -q "open-webui.*Up"; then
    log "⚠️ O serviço Open WebUI não está em execução. Iniciando..."
    docker compose up -d open-webui
    sleep 10 # Aguardar inicialização
fi

# Realizar backup do banco de dados do WebUI
log "💾 Realizando backup do banco de dados do Open WebUI..."
BACKUP_DIR="./volumes/backups/webui"
mkdir -p "$BACKUP_DIR"

BACKUP_FILE="$BACKUP_DIR/webui-db-$(date +'%Y%m%d-%H%M%S').bak"
docker compose cp open-webui:/app/.ollama-webui/db/database.sqlite "$BACKUP_FILE"
log "✅ Backup concluído: $BACKUP_FILE"

# Limpeza de backups antigos (manter apenas os últimos 5)
log "🧹 Limpando backups antigos..."
ls -t "$BACKUP_DIR"/*.bak | tail -n +6 | xargs -r rm
log "✅ Limpeza de backups concluída"

# Executar sincronização de usuários
log "🔄 Sincronizando usuários..."
./scripts/sh/auth/sync-webui-users.sh

# Verificar problemas de permissão
log "🔒 Verificando permissões dos arquivos do Open WebUI..."
docker compose exec open-webui sh -c "chown -R root:root /app/.ollama-webui/db 2>/dev/null || true"

# Verificar atualizações disponíveis para o Open WebUI
log "🔄 Verificando atualizações para o Open WebUI..."
CURRENT_IMAGE=$(docker inspect --format='{{.Config.Image}}' "$(docker compose ps -q open-webui)")
log "📦 Imagem atual do Open WebUI: $CURRENT_IMAGE"

# Puxar a imagem mais recente sem interromper o serviço
docker pull ghcr.io/ollama-webui/ollama-webui:main

# Verificar se é necessário atualizar
NEW_IMAGE_ID=$(docker images --no-trunc --format '{{.ID}}' ghcr.io/ollama-webui/ollama-webui:main)
CURRENT_IMAGE_ID=$(docker inspect --format='{{.Image}}' "$(docker compose ps -q open-webui)")

if [ "$NEW_IMAGE_ID" != "$CURRENT_IMAGE_ID" ]; then
    log "🆕 Nova versão do Open WebUI disponível. Atualizando..."
    docker compose up -d --no-deps --build open-webui
    log "✅ Open WebUI atualizado com sucesso"
else
    log "✅ Open WebUI já está na versão mais recente"
fi

# Gerar relatório de saúde
log "📊 Gerando relatório de saúde..."
docker compose exec -T open-webui curl -s http://localhost:8080/api/health > ./volumes/logs/webui-health-$(date +'%Y%m%d').json 2>/dev/null || log "⚠️ Não foi possível obter relatório de saúde"

log "✅ Manutenção do Open WebUI concluída com sucesso!"
exit 0