#!/bin/bash
# Script para reconstruir o modelo optimized-gemma3 com as configurações atualizadas

# Definir caminho do Modelfile
MODELFILE_PATH="/Users/angelosagnori/Downloads/orga-ai-v4/cookbooks/models/Modelfile"

echo "🔄 Reconstruindo modelo optimized-gemma3..."

# Verificar se o Ollama está rodando
if ! curl -s http://localhost:11434/api/version > /dev/null; then
    echo "❌ Servidor Ollama não está rodando. Inicie-o primeiro."
    exit 1
fi

# Verificar se o modelo base existe
if ! ollama show gemma3:1b > /dev/null 2>&1; then
    echo "⬇️ Baixando modelo base gemma3:1b..."
    ollama pull gemma3:1b
fi

# Remover modelo existente se houver
if ollama show optimized-gemma3 > /dev/null 2>&1; then
    echo "🗑️ Removendo versão anterior do modelo optimized-gemma3..."
    ollama rm optimized-gemma3
fi

# Criar modelo a partir do Modelfile
echo "🔨 Criando novo modelo optimized-gemma3..."
ollama create optimized-gemma3 -f "$MODELFILE_PATH"

# Verificar se a criação foi bem-sucedida
if ollama show optimized-gemma3 > /dev/null 2>&1; then
    echo "✅ Modelo optimized-gemma3 reconstruído com sucesso!"
    echo "🔍 Informações do modelo:"
    ollama show optimized-gemma3 | grep -v LICENSE
else
    echo "❌ Falha ao criar o modelo."
fi
