#!/bin/bash
# Script consolidado para aplicar todas as correções no banco de dados
# Data: 13 de maio de 2025

echo "================================================"
echo "Aplicando todas as correções de banco de dados"
echo "Data: $(date)"
echo "================================================"

# Definir diretório base
BASE_DIR="/Users/angelosagnori/Downloads/orga-ai-v4"
cd $BASE_DIR || { echo "Erro ao acessar diretório $BASE_DIR"; exit 1; }

# 1. Copiar todos os scripts SQL para o container
echo "Copiando scripts SQL para o container..."
docker cp ./scripts/sql/fix_user_ids.sql orga-ai-v4-db-1:/tmp/fix_user_ids.sql
docker cp ./scripts/sql/fix_admin_password.sql orga-ai-v4-db-1:/tmp/fix_admin_password.sql
docker cp ./scripts/sql/fix_user_timestamps.sql orga-ai-v4-db-1:/tmp/fix_user_timestamps.sql

# 2. Executar os scripts em ordem
echo "Executando scripts de correção..."
echo "1/3: Corrigindo IDs de usuário..."
docker-compose exec -T db psql -U postgres -d postgres -f /tmp/fix_user_ids.sql

echo "2/3: Configurando senha do administrador..."
docker-compose exec -T db psql -U postgres -d postgres -f /tmp/fix_admin_password.sql

echo "3/3: Corrigindo campos de timestamp..."
docker-compose exec -T db psql -U postgres -d postgres -f /tmp/fix_user_timestamps.sql

echo "================================================"
echo "Todas as correções SQL foram aplicadas com sucesso!"
echo "================================================"

# 3. Verificar status dos modelos Ollama
echo "Verificando status dos modelos Ollama..."
docker-compose exec ollama ollama list

echo "================================================"
echo "Verificando conexão com a API de autenticação..."
echo "================================================"
# Testando o login com o usuário admin
curl -s -X POST "http://localhost:8000/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&username=admin@example.com&password=admin123" | jq .

echo "================================================"
echo "Script de correções concluído!"
echo "================================================"
