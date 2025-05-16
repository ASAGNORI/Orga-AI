#!/bin/bash

# Script para corrigir a conexão entre o Backend e o Ollama
# Data: 9 de maio de 2025

# Diretório do projeto
PROJECT_DIR=$(pwd)
cd "$PROJECT_DIR"

echo "🔧 Corrigindo conexão entre Backend e Ollama..."

# Verificar status do Ollama
echo "🔍 Verificando status do Ollama..."
if ! docker compose ps | grep -q "ollama.*\(healthy\|Up\)"; then
  echo "❌ O serviço Ollama não está rodando ou não está saudável!"
  echo "🚀 Tentando reiniciar o Ollama..."
  docker compose restart ollama
  echo "⏳ Aguardando Ollama inicializar (30s)..."
  sleep 30
fi

# Verificar se o Ollama está respondendo
echo "🧪 Testando conexão com o Ollama..."
OLLAMA_RESPONSE=$(docker compose exec -T ollama curl -s -o /dev/null -w "%{http_code}" http://localhost:11434/api/version)

if [ "$OLLAMA_RESPONSE" != "200" ]; then
  echo "❌ Ollama não está respondendo corretamente!"
  echo "   Resposta HTTP: $OLLAMA_RESPONSE"
  echo "   Verifique os logs do Ollama: docker compose logs ollama"
  exit 1
fi

echo "✅ Ollama está funcionando corretamente!"

# Verificar modelos disponíveis no Ollama
echo "📋 Modelos disponíveis no Ollama:"
docker compose exec -T ollama ollama list

# Reiniciar o backend para aplicar as alterações
echo "🔄 Reiniciando o backend para aplicar as alterações..."
docker compose restart backend

# Aguardar o backend inicializar
echo "⏳ Aguardando backend inicializar (10s)..."
sleep 10

# Verificar logs do backend
echo "📊 Verificando logs do backend:"
docker compose logs --tail 20 backend

echo ""
echo "🔄 Verificando conexão do backend com o Ollama..."
HEALTH_RESPONSE=$(docker compose exec -T backend curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/v1/health)

if [ "$HEALTH_RESPONSE" = "200" ]; then
  echo "✅ Backend está respondendo corretamente!"
  echo "🚀 A conexão deve estar funcionando agora. Teste o chat na interface."
else
  echo "⚠️ Backend retornou código HTTP: $HEALTH_RESPONSE"
  echo "⚠️ Pode ser necessário verificar os logs para mais detalhes."
fi

echo ""
echo "ℹ️ Se o problema persistir, tente reiniciar toda a stack:"
echo "   docker compose down && docker compose up -d"
