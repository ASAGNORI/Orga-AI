#!/bin/bash

# Script para resolver problemas de autenticação do n8n
# Autor: GitHub Copilot
# Data: 2023/09/01

echo "🔧 Verificando configurações do n8n..."

# Verifica se estamos no diretório correto (com docker-compose.yml)
if [ ! -f docker-compose.yml ]; then
  echo "❌ Erro: Execute este script no diretório raiz do projeto (onde está o docker-compose.yml)"
  exit 1
fi

# Atualiza o arquivo .env para desativar a autenticação básica
if [ -f .env ]; then
  echo "📝 Atualizando configurações de autenticação no .env..."
  sed -i '' 's/N8N_BASIC_AUTH_ACTIVE=true/N8N_BASIC_AUTH_ACTIVE=false/g' .env
  echo "✅ Autenticação básica desativada no .env"
fi

# Reinicia o contêiner n8n
echo "🔄 Reiniciando o contêiner n8n..."
docker-compose down n8n
docker-compose up -d n8n

# Aguarda o serviço iniciar
echo "⏳ Aguardando o serviço n8n iniciar..."
sleep 5

# Verifica se o serviço está rodando
if docker-compose ps | grep -q "n8n.*Up"; then
  echo "✅ O serviço n8n foi reiniciado com sucesso!"
  echo "🌐 Acesse: http://localhost:5678"
else
  echo "❌ Houve um problema ao reiniciar o serviço n8n. Verifique os logs com 'docker-compose logs n8n'"
fi

echo "🔍 Para verificar os logs, execute: docker-compose logs --tail=50 n8n"
