#!/bin/bash

# Exit on error
set -e

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

# Defaults
START_BACKEND=true
START_FRONTEND=true
USE_DOCKER=true

# Parse arguments
for arg in "$@"
do
    case $arg in
        --frontend-only)
            START_BACKEND=false
            shift
            ;;
        --backend-only)
            START_FRONTEND=false
            shift
            ;;
        --no-docker)
            USE_DOCKER=false
            shift
            ;;
        --help)
            echo ""
            echo "✨ Orga AI Project Startup Script"
            echo ""
            echo "Options:"
            echo "  --frontend-only    Start only the frontend"
            echo "  --backend-only     Start only the backend"
            echo "  --no-docker        Run services without Docker"
            echo ""
            exit 0
            ;;
    esac
done

log "🚀 Starting Orga AI Project..."
log "============================="

# Check for required environment variables
if [ ! -f .env ]; then
    log "❌ .env file not found. Please create one from .env.example"
    exit 1
fi

# Load environment variables
source .env

# Check for required API keys
if [ -z "$HUGGINGFACE_API_KEY" ]; then
    log "⚠️ HUGGINGFACE_API_KEY not set in .env"
fi

if [ -z "$HANA_HOST" ] || [ -z "$HANA_USER" ] || [ -z "$HANA_PASSWORD" ]; then
    log "⚠️ HANA database credentials not fully configured in .env"
fi

# Start services with Docker Compose
if [ "$USE_DOCKER" = true ]; then
    log "📦 Starting services with Docker Compose..."

    # Stop any running containers
    log "🛑 Stopping any running containers..."
    docker compose down || log "⚠️ No containers were running"

    # Clean up Next.js cache
    log "🧹 Cleaning up Next.js cache..."
    rm -rf frontend/.next

    # Primeiro iniciamos apenas o Ollama para garantir que ele esteja pronto
    log "🧠 Starting Ollama service first..."
    docker compose up -d --build ollama

    # Aguarda explicitamente até que o Ollama esteja pronto
    log "⏳ Waiting for Ollama service to be fully initialized..."
    max_attempts=30
    attempt=1
    ollama_ready=false

    while [ $attempt -le $max_attempts ] && [ "$ollama_ready" = false ]
    do
        log "🔄 Checking Ollama status (attempt $attempt of $max_attempts)..."
        if docker compose exec ollama curl -s -f http://localhost:11435/api/tags > /dev/null 2>&1; then
            ollama_ready=true
            log "✅ Ollama is now ready!"
        else
            log "⏳ Ollama not ready yet, waiting 10 seconds..."
            sleep 10
            attempt=$((attempt+1))
        fi
    done

    if [ "$ollama_ready" = false ]; then
        log "❌ Timed out waiting for Ollama. Check the Ollama service logs for issues."
        docker compose logs ollama
        exit 1
    fi

    # Agora iniciamos o banco de dados
    log "🛢️ Starting database service..."
    docker compose up -d --build db

    # Aguarde até que o banco de dados esteja pronto
    log "⏳ Waiting for database to be ready..."
    max_attempts=15
    attempt=1
    db_ready=false

    while [ $attempt -le $max_attempts ] && [ "$db_ready" = false ]
    do
        log "🔄 Checking database status (attempt $attempt of $max_attempts)..."
        if docker compose exec db pg_isready -U postgres > /dev/null 2>&1; then
            db_ready=true
            log "✅ Database is now ready!"
        else
            log "⏳ Database not ready yet, waiting 5 seconds..."
            sleep 5
            attempt=$((attempt+1))
        fi
    done

    if [ "$db_ready" = false ]; then
        log "❌ Timed out waiting for database. Check the database logs for issues."
        docker compose logs db
        exit 1
    fi

    # Agora podemos iniciar o backend
    if [ "$START_BACKEND" = true ]; then
        log "🔧 Starting Backend API..."
        docker compose up -d --build backend

        # Aguarda até que o backend esteja pronto
        log "⏳ Waiting for Backend API to be ready..."
        max_attempts=15
        attempt=1
        backend_ready=false

        while [ $attempt -le $max_attempts ] && [ "$backend_ready" = false ]
        do
            log "🔄 Checking Backend API status (attempt $attempt of $max_attempts)..."
            if curl -s -f http://localhost:8000/api/v1/health > /dev/null 2>&1; then
                backend_ready=true
                log "✅ Backend API is now ready!"
            else
                log "⏳ Backend API not ready yet, waiting 5 seconds..."
                sleep 5
                attempt=$((attempt+1))
            fi
        done

        if [ "$backend_ready" = false ]; then
            log "❌ Timed out waiting for Backend API. Check the backend logs for issues."
            docker compose logs backend
            # Continuamos mesmo que o backend não esteja respondendo
        fi
    fi

    # Finalmente iniciamos o frontend e os demais serviços
    if [ "$START_FRONTEND" = true ]; then
        log "🖥️ Starting frontend and remaining services..."
        docker compose up -d --build

        log "⏳ Waiting for frontend to be ready..."
        max_attempts=10
        attempt=1
        frontend_ready=false

        while [ $attempt -le $max_attempts ] && [ "$frontend_ready" = false ]
        do
            log "🔄 Checking frontend status (attempt $attempt of $max_attempts)..."
            if curl -s -f http://localhost:3000 > /dev/null 2>&1; then
                frontend_ready=true
                log "✅ Frontend is now ready!"
            else
                log "⏳ Frontend not ready yet, waiting 5 seconds..."
                sleep 5
                attempt=$((attempt+1))
            fi
        done

        if [ "$frontend_ready" = false ]; then
            log "⚠️ Frontend might not be fully ready yet. Check the frontend logs for issues."
            docker compose logs frontend
        fi
    fi

    # Adjust permissions for N8N configuration file if it exists
    if [ -f "/home/node/.n8n/config" ]; then
        log "🔧 Adjusting permissions for N8N configuration file..."
        chmod 600 /home/node/.n8n/config
    fi

    # Check if services are running
    log "🔍 Checking service status..."
    
    services=(
        "frontend:3000:Frontend"
        "backend:8000:Backend"
        "studio:54323:Supabase Studio"
        "kong:54321:Supabase API Gateway"
        "db:54322:PostgreSQL database"
        "n8n:5678:N8N"
    )

    for service in "${services[@]}"; do
        IFS=: read -r name port desc <<< "$service"
        if docker compose ps | grep -q "$name.*Up"; then
            log "✅ $desc is running at http://localhost:$port"
        else
            log "⚠️ $desc is not running"
        fi
    done
else
    log "⚙️ Non-Docker mode not implemented yet"
    exit 1
fi

log ""
log "✅ Orga AI Project is running! 🚀"
log ""
log "📚 Documentation:"
log "  - Frontend: http://localhost:3000"
log "  - Backend API: http://localhost:8000/docs"
log "  - Supabase Studio: http://localhost:54323"
log "  - Supabase API: http://localhost:54321"
log "  - PostgreSQL: localhost:54322"
log "  - N8N Dashboard: http://localhost:5678"
log ""
log "🔐 Supabase Configuration:"
log "  - API URL: http://localhost:54321"
log "  - Studio URL: http://localhost:54323"
log "  - Database URL: postgresql://postgres:postgres@localhost:54322/postgres"
