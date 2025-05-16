#!/bin/bash

# Script para reiniciar o serviço backend
echo "Reiniciando serviço backend..."

# Diretório atual
CURRENT_DIR=$(pwd)
cd "$(dirname "$0")/../.." || exit 1

echo "Parando containers existentes..."
docker-compose stop backend

echo "Iniciando backend novamente..."
docker-compose up -d backend

echo "Verificando logs para confirmar inicialização..."
sleep 3
docker-compose logs --tail=20 backend

echo "Serviço backend reiniciado com sucesso!"

# Retornar ao diretório original
cd "$CURRENT_DIR" || exit 1
