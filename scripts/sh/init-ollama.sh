#!/bin/bash
set -e

# Definir modelos padrão se as variáveis não estiverem definidas
DEFAULT_MODEL="optimized-gemma3"
DEFAULT_CHAT_MODEL="optimized-gemma3"

# Usar as variáveis de ambiente se disponíveis, caso contrário usar padrões
MODEL=${OLLAMA_MODEL:-$DEFAULT_MODEL}
CHAT_MODEL=${OLLAMA_MODEL_CHAT:-$DEFAULT_CHAT_MODEL}

# Modelos customizados para criar: "nome_customizado:caminho_do_modelfile:modelo_base_necessario"
CUSTOM_MODELS_TO_CREATE=(
    "optimized-gemma3:/models/Modelfile:gemma3:1b"
)

echo "🚀 Iniciando servidor Ollama ($(date))"
echo "📋 Configuração de modelos:"
echo "   - Modelo principal: $MODEL"
echo "   - Modelo de chat: $CHAT_MODEL"

# Função para fazer log com timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Iniciar o servidor Ollama em segundo plano
ollama serve &
OLLAMA_PID=$!

# Função para verificar endpoints específicos
check_endpoint() {
    local endpoint=$1
    local method=${2:-GET}
    local data=${3:-""}
    
    if [ "$method" = "GET" ]; then
        curl -s -X GET "http://localhost:11434$endpoint" >/dev/null 2>&1
    else
        curl -s -X "$method" "http://localhost:11434$endpoint" -d "$data" >/dev/null 2>&1
    fi
    return $?
}

# Função para verificar se o servidor está pronto
wait_for_ollama() {
    log "⏳ Aguardando o servidor Ollama iniciar..."
    local required_endpoints=("/api/tags" "/health")
    
    for i in {1..60}; do  # 60 tentativas (1 minuto)
        local all_ready=true
        
        for endpoint in "${required_endpoints[@]}"; do
            if ! check_endpoint "$endpoint"; then
                all_ready=false
                break
            fi
        done
        
        # Verificar o endpoint /api/show com POST
        if [ "$all_ready" = true ]; then
            if ! check_endpoint "/api/show" "POST" '{"name":"'$MODEL'"}'; then
                all_ready=false
            fi
        fi
        
        if [ "$all_ready" = true ]; then
            log "✅ Servidor Ollama está pronto! Todos os endpoints respondendo."
            return 0
        fi
        
        if [ $((i % 10)) -eq 0 ]; then
            log "⏳ Tentativa $i: Aguardando endpoints ficarem disponíveis..."
        fi
        sleep 1
    done
    
    log "❌ Timeout ao aguardar o servidor Ollama"
    return 1
}

# Função para baixar um modelo com tentativas (pull do hub)
download_model() {
    local model_name=$1
    local max_attempts=3
    local attempt=1
    
    # Verificar se o modelo já existe localmente
    if ollama show "$model_name" >/dev/null 2>&1; then
        log "✅ Modelo $model_name já existe localmente."
        return 0
    fi

    while [ $attempt -le $max_attempts ]; do
        log "📥 Tentativa $attempt: Baixando modelo $model_name do hub Ollama..."
        
        if ollama pull "$model_name"; then
            log "✅ Modelo $model_name baixado com sucesso!"
            return 0
        fi
        
        log "⚠️ Falha ao baixar o modelo $model_name (tentativa $attempt/$max_attempts)"
        attempt=$((attempt + 1))
        
        if [ $attempt -le $max_attempts ]; then
            log "⏳ Aguardando 5 segundos antes de tentar novamente..."
            sleep 5
        fi
    done
    
    log "❌ Falha ao baixar o modelo $model_name após $max_attempts tentativas"
    return 1
}

# Função para criar um modelo a partir de um Modelfile
create_model_from_file() {
    local model_name=$1
    local modelfile_path=$2
    local base_model_needed=$3
    local max_attempts=3
    local attempt=1

    log "ℹ️ Verificando modelo base $base_model_needed para $model_name..."
    # Tenta baixar/confirmar o modelo base primeiro
    if ! download_model "$base_model_needed"; then
        log "❌ Falha ao obter o modelo base $base_model_needed para $model_name. Não é possível criar o modelo customizado."
        return 1
    fi
    log "✅ Modelo base $base_model_needed está disponível."

    log "🛠️ Tentando criar modelo customizado $model_name a partir de $modelfile_path..."
    while [ $attempt -le $max_attempts ]; do
        log "💡 Tentativa $attempt: Criando $model_name..."
        # shellcheck disable=SC2086
        if ollama create "$model_name" -f "$modelfile_path"; then
            log "✅ Modelo customizado $model_name criado com sucesso a partir de $modelfile_path!"
            return 0
        fi
        
        log "⚠️ Falha ao criar o modelo $model_name (tentativa $attempt/$max_attempts)"
        attempt=$((attempt + 1))
        
        if [ $attempt -le $max_attempts ]; then
            log "⏳ Aguardando 5 segundos antes de tentar novamente..."
            sleep 5
        fi
    done
    
    log "❌ Falha ao criar o modelo $model_name após $max_attempts tentativas. Verifique $modelfile_path e logs do Ollama."
    return 1
}

# Esperar o servidor iniciar
if ! wait_for_ollama; then
    log "❌ Falha ao iniciar o servidor Ollama"
    exit 1
fi

# Criar modelos customizados definidos em CUSTOM_MODELS_TO_CREATE
log "✨ Processando modelos customizados..."
for entry in "${CUSTOM_MODELS_TO_CREATE[@]}"; do
    IFS=':' read -r custom_name modelfile base_model <<< "$entry"
    if ! create_model_from_file "$custom_name" "$modelfile" "$base_model"; then
        log "❌ Falha crítica ao criar modelo customizado $custom_name."
        # Considerar se deve sair em caso de falha
        # exit 1 
    fi
done
log "✨ Processamento de modelos customizados concluído."

# Verificar se os modelos definidos em .env (MODEL e CHAT_MODEL) existem
# Se não existirem e não forem os customizados, tentar baixá-los.
# Esta etapa é mais uma garantia, pois o ideal é que MODEL e CHAT_MODEL
# sejam os nomes dos modelos customizados criados.

log "Verificando modelo principal: $MODEL"
if ! ollama show "$MODEL" >/dev/null 2>&1; then
    log "Modelo principal $MODEL não encontrado. Tentando baixar..."
    if ! download_model "$MODEL"; then
        log "❌ Falha ao baixar/confirmar modelo principal $MODEL. Verifique as configurações."
    fi
else
    log "✅ Modelo principal $MODEL já existe."
fi

if [ "$MODEL" != "$CHAT_MODEL" ]; then
    log "Verificando modelo de chat: $CHAT_MODEL"
    if ! ollama show "$CHAT_MODEL" >/dev/null 2>&1; then
        log "Modelo de chat $CHAT_MODEL não encontrado. Tentando baixar..."
        if ! download_model "$CHAT_MODEL"; then
            log "❌ Falha ao baixar/confirmar modelo de chat $CHAT_MODEL. Verifique as configurações."
        fi
    else
        log "✅ Modelo de chat $CHAT_MODEL já existe."
    fi
fi

log "✨ Inicialização completa! Servidor pronto para uso."

# Manter o processo em execução
wait $OLLAMA_PID