#!/bin/bash
# Script para limpar e reconstruir o modelo optimized-gemma3

# Definir caminho do Modelfile
MODELFILE_PATH="/Users/angelosagnori/Downloads/orga-ai-v4/cookbooks/models/Modelfile"

echo "🧹 Limpeza e reconstrução do modelo optimized-gemma3"
echo "----------------------------------------------------"

# Verificar se o Ollama está rodando
if ! curl -s http://localhost:11434/api/version > /dev/null; then
    echo "❌ Servidor Ollama não está rodando. Inicie-o primeiro."
    exit 1
fi

# Remover modelo existente se houver
if ollama show optimized-gemma3 > /dev/null 2>&1; then
    echo "🗑️ Removendo versão anterior do modelo optimized-gemma3..."
    ollama rm optimized-gemma3
fi

# Verificar se o modelo base existe
if ! ollama show gemma3:1b > /dev/null 2>&1; then
    echo "⬇️ Baixando modelo base gemma3:1b..."
    ollama pull gemma3:1b
fi

# Criar modelo a partir do Modelfile
echo "🔨 Criando novo modelo optimized-gemma3..."
ollama create optimized-gemma3 -f "$MODELFILE_PATH"

# Verificar se a criação foi bem-sucedida
if ollama show optimized-gemma3 > /dev/null 2>&1; then
    echo "✅ Modelo optimized-gemma3 reconstruído com sucesso!"
    echo
    echo "🔍 Parâmetros do modelo:"
    ollama show optimized-gemma3 parameters
    echo
    echo "📝 Template do modelo:"
    ollama show optimized-gemma3 template
    echo
    echo "🔧 Sistema do modelo:"
    ollama show optimized-gemma3 system
    echo
    echo "🧪 Teste o modelo com: ollama run optimized-gemma3"
else
    echo "❌ Falha ao criar o modelo."
fi

echo
echo "💡 Se o problema persistir, você pode tentar estas soluções:"
echo "   1. Verificar logs: ollama serve > ollama.log 2>&1"
echo "   2. Reiniciar o serviço Ollama"
echo "   3. Limpar o cache: rm -rf ~/.ollama/models/optimized-gemma3"
echo "   4. Atualizar o Ollama para a versão mais recente"
