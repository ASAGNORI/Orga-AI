#!/bin/bash

# Script para verificar a saúde dos serviços do Orga AI Project

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Error handling
handle_error() {
    log "❌ Error occurred in script at line $1"
    exit 1
}

trap 'handle_error $LINENO' ERR

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check parameters
SERVICE="all"
if [ "$1" != "" ]; then
    SERVICE=$1
fi

log "🔍 Verificando saúde dos serviços: ${SERVICE}"

# Verificar se o Docker está rodando
if ! docker info > /dev/null 2>&1; then
    log "${RED}❌ Docker não está rodando. Por favor, inicie o Docker primeiro.${NC}"
    exit 1
fi

# Check if docker-compose exists
if ! command -v docker compose &> /dev/null; then
    log "${RED}❌ Docker Compose não está instalado ou não está no PATH.${NC}"
    exit 1
fi

# Verificar se o Ollama está rodando e saudável
check_ollama() {
    log "🧠 Verificando serviço Ollama..."
    if ! docker compose ps | grep -q "ollama.*Up"; then
        log "${RED}❌ Ollama não está rodando. Iniciando Ollama...${NC}"
        docker compose up -d ollama
        sleep 5
    fi

    # Verificar se o Ollama está respondendo
    max_attempts=10
    attempt=1
    ollama_ready=false

    while [ $attempt -le $max_attempts ] && [ "$ollama_ready" = false ]; do
        log "🔄 Testando conexão com Ollama (tentativa $attempt de $max_attempts)..."
        if docker compose exec ollama curl -s -f http://localhost:11435/api/tags > /dev/null 2>&1; then
            ollama_ready=true
            log "${GREEN}✅ Ollama está respondendo corretamente!${NC}"
        else
            log "${YELLOW}⏳ Ollama não está pronto ainda. Aguardando 5 segundos...${NC}"
            sleep 5
            attempt=$((attempt+1))
        fi
    done

    if [ "$ollama_ready" = false ]; then
        log "${RED}❌ Ollama não está respondendo após várias tentativas. Verifique os logs:${NC}"
        docker compose logs ollama
        return 1
    fi

    # Verificar se o modelo LLama3 está disponível
    log "🤖 Verificando disponibilidade do modelo llama3:8b..."
    model_output=$(docker compose exec ollama ollama list 2>/dev/null || echo "")
    
    if echo "$model_output" | grep -q "llama3"; then
        log "${GREEN}✅ Modelo llama3:8b está instalado!${NC}"
    else
        log "${YELLOW}⚠️ Modelo llama3:8b não detectado. Iniciando download...${NC}"
        docker compose exec -d ollama ollama pull llama3:8b
        log "${YELLOW}⏳ Download do modelo iniciado em segundo plano. Este processo pode levar alguns minutos.${NC}"
        log "${YELLOW}⏳ Você pode verificar o progresso com 'docker compose logs ollama'.${NC}"
        # Não esperaremos o download terminar, apenas avisamos o usuário
    fi
    
    return 0
}

# Verificar se o Banco de Dados está rodando e saudável
check_database() {
    log "🛢️ Verificando serviço de banco de dados..."
    if ! docker compose ps | grep -q "db.*Up"; then
        log "${RED}❌ Banco de dados não está rodando. Iniciando banco de dados...${NC}"
        docker compose up -d db
        sleep 5
    fi

    # Verificar se o Banco de Dados está respondendo
    max_attempts=5
    attempt=1
    db_ready=false

    while [ $attempt -le $max_attempts ] && [ "$db_ready" = false ]; do
        log "🔄 Testando conexão com banco de dados (tentativa $attempt de $max_attempts)..."
        if docker compose exec db pg_isready -U postgres > /dev/null 2>&1; then
            db_ready=true
            log "${GREEN}✅ Banco de dados está respondendo corretamente!${NC}"
        else
            log "${YELLOW}⏳ Banco de dados não está pronto ainda. Aguardando 3 segundos...${NC}"
            sleep 3
            attempt=$((attempt+1))
        fi
    done

    if [ "$db_ready" = false ]; then
        log "${RED}❌ Banco de dados não está respondendo após várias tentativas. Verifique os logs:${NC}"
        docker compose logs db
        return 1
    fi
    
    return 0
}

# Verificar se o Backend está rodando e saudável
check_backend() {
    log "🔧 Verificando serviço de API Backend..."
    if ! docker compose ps | grep -q "backend.*Up"; then
        log "${RED}❌ Backend não está rodando. Iniciando backend...${NC}"
        docker compose up -d backend
        sleep 5
    fi

    # Verificar se o Backend está respondendo
    max_attempts=5
    attempt=1
    backend_ready=false

    while [ $attempt -le $max_attempts ] && [ "$backend_ready" = false ]; do
        log "🔄 Testando conexão com backend (tentativa $attempt de $max_attempts)..."
        if curl -s -f http://localhost:8000/api/v1/health > /dev/null 2>&1; then
            backend_ready=true
            log "${GREEN}✅ Backend está respondendo corretamente!${NC}"
        else
            log "${YELLOW}⏳ Backend não está pronto ainda. Aguardando 3 segundos...${NC}"
            sleep 3
            attempt=$((attempt+1))
        fi
    done

    if [ "$backend_ready" = false ]; then
        log "${RED}❌ Backend não está respondendo após várias tentativas. Verifique os logs:${NC}"
        docker compose logs backend
        return 1
    fi
    
    return 0
}

# Verificar se o Frontend está rodando e saudável
check_frontend() {
    log "🖥️ Verificando serviço Frontend..."
    if ! docker compose ps | grep -q "frontend.*Up"; then
        log "${RED}❌ Frontend não está rodando. Iniciando frontend...${NC}"
        docker compose up -d frontend
        sleep 5
    fi

    # Verificar se o Frontend está respondendo
    max_attempts=5
    attempt=1
    frontend_ready=false

    while [ $attempt -le $max_attempts ] && [ "$frontend_ready" = false ]; do
        log "🔄 Testando conexão com frontend (tentativa $attempt de $max_attempts)..."
        if curl -s -f http://localhost:3000 > /dev/null 2>&1; then
            frontend_ready=true
            log "${GREEN}✅ Frontend está respondendo corretamente!${NC}"
        else
            log "${YELLOW}⏳ Frontend não está pronto ainda. Aguardando 3 segundos...${NC}"
            sleep 3
            attempt=$((attempt+1))
        fi
    done

    if [ "$frontend_ready" = false ]; then
        log "${YELLOW}⚠️ Frontend pode não estar pronto ainda. Verifique os logs:${NC}"
        docker compose logs frontend
        return 1
    fi
    
    return 0
}

# Testar páginas do Frontend
check_frontend_pages() {
    log "🕸️ Testando rotas do Frontend..."
    local routes=("/" "/login" "/register" "/dashboard")
    local err=0
    for route in "${routes[@]}"; do
        if curl -s -f http://localhost:3000${route} > /dev/null; then
            log "${GREEN}✅ Frontend rota ${route} OK${NC}"
        else
            log "${RED}❌ Frontend rota ${route} falhou${NC}"
            err=1
        fi
    done
    return $err
}

# Função principal de verificação
check_services() {
    status_all=0

    if [ "$SERVICE" = "all" ] || [ "$SERVICE" = "ollama" ]; then
        check_ollama
        status_ollama=$?
        status_all=$((status_all + status_ollama))
    fi

    if [ "$SERVICE" = "all" ] || [ "$SERVICE" = "db" ]; then
        check_database
        status_db=$?
        status_all=$((status_all + status_db))
    fi

    if [ "$SERVICE" = "all" ] || [ "$SERVICE" = "backend" ]; then
        check_backend
        status_backend=$?
        status_all=$((status_all + status_backend))
    fi

    if [ "$SERVICE" = "all" ] || [ "$SERVICE" = "frontend" ]; then
        check_frontend
        status_frontend=$?
        check_frontend_pages
        status_frontend_pages=$?
        status_all=$((status_all + status_frontend + status_frontend_pages))
    fi

    if [ $status_all -eq 0 ]; then
        log "${GREEN}✅ Todos os serviços verificados estão saudáveis!${NC}"
        return 0
    else
        log "${RED}❌ Alguns serviços não estão saudáveis. Verifique os logs acima.${NC}"
        return 1
    fi
}

# Execute a verificação
check_services
exit_code=$?

log "🏁 Verificação de saúde concluída com status: $exit_code"
exit $exit_code
