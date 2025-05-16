#!/bin/bash

set -e

# Função para exibir o uso do script
show_usage() {
  echo "Uso: $0 [--model <nome_modelo>] [--chat-model] [--list] [--lightweight-models] [--help]"
  echo ""
  echo "Opções:"
  echo "  --model gemma3:1b Especifica o modelo a ser baixado (padrão: gemma3:1b)"
  echo "  --chat-model             Baixa o modelo de chat (gemma3:1b)"
  echo "  --all                    Baixa todos os modelos configurados (principal e chat)"
  echo "  --lightweight-models     Baixa modelos leves alternativos para sistemas com memória limitada"
  echo "  --list                   Lista os modelos disponíveis localmente no Ollama"
  echo "  --help                   Mostra este texto de ajuda"
  echo ""
  echo "Exemplos:"
  echo "  $0                       # Baixa o modelo padrão (gemma3:1b)"
  echo "  $0 --model llama3:8b     # Baixa o modelo llama3:8b"
  echo "  $0 --chat-model          # Baixa o modelo de chat (gemma3:1b)"
  echo "  $0 --all                 # Baixa ambos os modelos configurados"
  echo "  $0 --list                # Lista os modelos atualmente instalados"
  echo "  $0 --lightweight-models  # Baixa modelos leves para sistemas com memória limitada"
}

# Obter as variáveis de ambiente
DEFAULT_MODEL=${OLLAMA_MODEL:-"gemma3:1b"}
DEFAULT_CHAT_MODEL=${OLLAMA_MODEL_CHAT:-"gemma3:1b"}

# Lista de modelos leves para sistemas com memória limitada
LIGHTWEIGHT_MODELS=(
  "gemma3:1b"
  "phi3:mini"
)

# Função para fazer log com timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Função para verificar se o servidor Ollama está funcionando
check_ollama_server() {
    log "🔍 Verificando servidor Ollama..."
    if ! curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        log "❌ Servidor Ollama não está respondendo em http://localhost:11434"
        log "💡 Certifique-se de que o servidor Ollama está em execução com 'ollama serve' ou via Docker"
        return 1
    fi
    log "✅ Servidor Ollama está funcionando"
    return 0
}

# Função para baixar um modelo específico
download_model() {
    local model_name=$1
    log "📥 Baixando modelo $model_name..."
    
    if ollama pull "$model_name"; then
        log "✅ Modelo $model_name baixado com sucesso!"
        return 0
    else
        log "❌ Falha ao baixar o modelo $model_name"
        return 1
    fi
}

# Função para baixar modelos leves
download_lightweight_models() {
    log "🔍 Baixando modelos leves para sistemas com memória limitada..."
    
    local success_count=0
    local total=${#LIGHTWEIGHT_MODELS[@]}
    
    for model in "${LIGHTWEIGHT_MODELS[@]}"; do
        log "📥 Tentando baixar modelo leve: $model"
        if ollama pull "$model"; then
            log "✅ Modelo leve $model baixado com sucesso!"
            ((success_count++))
        else
            log "⚠️ Falha ao baixar o modelo leve $model, mas continuando com os próximos..."
        fi
    done
    
    log "📊 Baixados $success_count de $total modelos leves"
    
    if [ $success_count -gt 0 ]; then
        return 0
    else
        log "❌ Não foi possível baixar nenhum modelo leve"
        return 1
    fi
}

# Função para listar modelos disponíveis
list_models() {
    log "📋 Modelos disponíveis no Ollama:"
    ollama list
}

# Inicializar variáveis
MODEL=$DEFAULT_MODEL
CHAT_MODEL=$DEFAULT_CHAT_MODEL
DOWNLOAD_MAIN=false
DOWNLOAD_CHAT=false
DOWNLOAD_ALL=false
DOWNLOAD_LIGHTWEIGHT=false
LIST_MODELS=false

# Processar parâmetros
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --model)
            MODEL="$2"
            DOWNLOAD_MAIN=true
            shift 2
            ;;
        --chat-model)
            DOWNLOAD_CHAT=true
            shift
            ;;
        --all)
            DOWNLOAD_ALL=true
            shift
            ;;
        --lightweight-models)
            DOWNLOAD_LIGHTWEIGHT=true
            shift
            ;;
        --list)
            LIST_MODELS=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo "❌ Opção desconhecida: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Verificar se nenhuma opção foi especificada e definir o comportamento padrão
if [ "$DOWNLOAD_MAIN" = false ] && [ "$DOWNLOAD_CHAT" = false ] && [ "$DOWNLOAD_ALL" = false ] && [ "$LIST_MODELS" = false ] && [ "$DOWNLOAD_LIGHTWEIGHT" = false ]; then
    DOWNLOAD_MAIN=true  # Comportamento padrão: baixar o modelo principal
fi

# Principal lógica de execução
main() {
    log "🚀 Iniciando gerenciador de modelos Ollama"
    
    # Verificar se o servidor está funcionando
    if ! check_ollama_server; then
        exit 1
    fi
    
    # Listar modelos se solicitado
    if [ "$LIST_MODELS" = true ]; then
        list_models
        exit 0
    fi
    
    # Baixar modelos leves se solicitado
    if [ "$DOWNLOAD_LIGHTWEIGHT" = true ]; then
        download_lightweight_models
        exit 0
    fi
    
    # Baixar todos os modelos configurados
    if [ "$DOWNLOAD_ALL" = true ]; then
        download_model "$MODEL"
        download_model "$CHAT_MODEL"
        exit 0
    fi
    
    # Baixar modelo principal se solicitado
    if [ "$DOWNLOAD_MAIN" = true ]; then
        download_model "$MODEL"
    fi
    
    # Baixar modelo de chat se solicitado
    if [ "$DOWNLOAD_CHAT" = true ]; then
        download_model "$CHAT_MODEL"
    fi
    
    log "✅ Operação concluída"
}

# Executar a lógica principal
main