#!/bin/bash
# Script para sincronizar usuários entre Supabase e Open WebUI
# Criado em: maio/2025
# Licença: MIT

set -e

# Função de log
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Tratamento de erros
handle_error() {
    log "❌ Erro no script de sincronização na linha $1"
    exit 1
}

trap 'handle_error $LINENO' ERR

# Carregar variáveis de ambiente
if [ ! -f .env ]; then
    log "❌ Arquivo .env não encontrado. Criando a partir do exemplo..."
    cp .env.example .env
fi

source .env

# Verificar se o Open WebUI está em execução
log "🔍 Verificando se o Open WebUI está em execução..."
if ! docker compose ps | grep -q "open-webui.*Up"; then
    log "❌ O serviço Open WebUI não está em execução"
    exit 1
fi

# Verificar se o banco de dados está em execução
log "🔍 Verificando se o banco de dados está em execução..."
if ! docker compose ps | grep -q "db.*Up"; then
    log "❌ O serviço de banco de dados não está em execução"
    exit 1
fi

# Obter token de autenticação do admin do Open WebUI
log "🔑 Obtendo token de autenticação do Open WebUI..."

ADMIN_USERNAME=${WEBUI_ADMIN_USERNAME:-admin}
ADMIN_PASSWORD=${WEBUI_ADMIN_PASSWORD:-orga-admin}

# Função para obter token de admin do Open WebUI
get_webui_token() {
    local response=$(docker compose exec -T open-webui curl -s -X POST \
        http://localhost:8080/api/auth/login \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$ADMIN_USERNAME\",\"password\":\"$ADMIN_PASSWORD\"}")
    
    # Extrair o token da resposta (assumindo formato JSON com campo "access_token")
    echo "$response" | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"\([^"]*\)"/\1/'
}

ADMIN_TOKEN=$(get_webui_token)

if [ -z "$ADMIN_TOKEN" ]; then
    log "❌ Não foi possível obter token de admin do Open WebUI"
    log "⚠️ Verifique se as credenciais admin estão corretas e se o Open WebUI está inicializado"
    exit 1
fi

log "✅ Token de autenticação obtido com sucesso"

# Obter lista de usuários do Supabase
log "👥 Extraindo lista de usuários do Supabase..."
USERS_QUERY="SELECT email, id, raw_user_meta_data->>'full_name' as name FROM auth.users;"
USERS=$(docker compose exec -T db psql -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-postgres} -t -c "$USERS_QUERY")

# Contador de usuários
TOTAL_USERS=0
SYNC_SUCCESS=0

# Para cada usuário, verificar/criar no Open WebUI
echo "$USERS" | while read -r line; do
    if [ -z "$line" ]; then continue; fi
    
    # Extrair informações do usuário
    email=$(echo "$line" | awk '{print $1}')
    user_id=$(echo "$line" | awk '{print $3}')
    name=$(echo "$line" | awk '{$1=$2=""; print $0}' | sed 's/^  //')
    
    # Se o nome estiver vazio, usar o e-mail como nome
    if [ -z "$name" ]; then
        name=$(echo "$email" | cut -d '@' -f 1)
    fi
    
    # Gerar senha temporária aleatória
    temp_pass=$(openssl rand -base64 12)
    
    log "👤 Sincronizando usuário: $email (ID: $user_id, Nome: $name)"
    
    # Verificar se o usuário já existe no Open WebUI
    user_exists=$(docker compose exec -T open-webui curl -s -X GET \
        "http://localhost:8080/api/users/check/$email" \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        -H "Content-Type: application/json")
    
    if echo "$user_exists" | grep -q "true"; then
        log "ℹ️ Usuário $email já existe no Open WebUI, atualizando..."
        
        # Atualizar usuário existente
        update_result=$(docker compose exec -T open-webui curl -s -X PUT \
            "http://localhost:8080/api/users" \
            -H "Authorization: Bearer $ADMIN_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"username\":\"$email\",\"name\":\"$name\",\"user_id\":\"$user_id\"}")
        
        if [ $? -eq 0 ]; then
            log "✅ Usuário $email atualizado com sucesso"
            ((SYNC_SUCCESS++))
        else
            log "⚠️ Falha ao atualizar usuário $email: $update_result"
        fi
    else
        log "➕ Criando novo usuário $email no Open WebUI..."
        
        # Criar novo usuário
        create_result=$(docker compose exec -T open-webui curl -s -X POST \
            "http://localhost:8080/api/users" \
            -H "Authorization: Bearer $ADMIN_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"username\":\"$email\",\"password\":\"$temp_pass\",\"name\":\"$name\",\"user_id\":\"$user_id\",\"role\":\"user\"}")
        
        if [ $? -eq 0 ]; then
            log "✅ Usuário $email criado com sucesso"
            ((SYNC_SUCCESS++))
        else
            log "⚠️ Falha ao criar usuário $email: $create_result"
        fi
    fi
    
    ((TOTAL_USERS++))
done

log "🎯 Sincronização concluída: $SYNC_SUCCESS de $TOTAL_USERS usuários sincronizados"

exit 0