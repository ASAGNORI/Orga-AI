#!/bin/bash
# Script para iniciar o Ollama: pull antes e serve com o modelo

# Define the model to pull
MODEL=${OLLAMA_MODEL:-$MODEL}

# Puxa primeiro o modelo remoto
echo "📥 Puxando modelo $MODEL..."
# Unset API URL/KEY to force local pull (avoid connecting to server)
env -u OLLAMA_API_URL -u OLLAMA_BASE_URL -u OLLAMA_API_KEY ollama pull "$MODEL"

# Inicia o servidor Ollama
echo "🚀 Servindo Ollama..."
exec ollama serve