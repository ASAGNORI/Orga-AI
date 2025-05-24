#!/bin/bash
# Script avançado para limpar e reconstruir o modelo optimized-gemma3

# Definir caminho do Modelfile
MODELFILE_PATH="/Users/angelosagnori/Downloads/orga-ai-v4/cookbooks/models/Modelfile"

# Cores para melhor visualização
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 Limpeza avançada e reconstrução do modelo optimized-gemma3${NC}"
echo "============================================================="

# Verificar se o Ollama está rodando
if ! curl -s http://localhost:11434/api/version > /dev/null; then
    echo -e "${RED}❌ Servidor Ollama não está rodando. Inicie-o primeiro.${NC}"
    exit 1
fi

# Verificar diretório home do Ollama
OLLAMA_HOME="$HOME/.ollama"
if [ -d "$OLLAMA_HOME" ]; then
    echo -e "${GREEN}✅ Diretório Ollama encontrado: $OLLAMA_HOME${NC}"
else
    echo -e "${YELLOW}⚠️ Diretório Ollama não encontrado no caminho padrão.${NC}"
    echo -e "${YELLOW}⚠️ Tentando verificar diretórios de dados do Docker...${NC}"
    # Aqui poderia adicionar lógica para Docker
fi

# Limpeza de arquivo de cache do modelo anteriormente criado
echo -e "${BLUE}🔍 Verificando caches do modelo...${NC}"
MODEL_CACHE_PATHS=(
    "$OLLAMA_HOME/models/optimized-gemma3"
    "$OLLAMA_HOME/models/manifests/optimized-gemma3"
    "/Users/angelosagnori/Downloads/orga-ai-v4/volumes/ollama_data/models/optimized-gemma3"
)

for path in "${MODEL_CACHE_PATHS[@]}"; do
    if [ -e "$path" ]; then
        echo -e "${YELLOW}🗑️ Removendo cache em: $path${NC}"
        rm -rf "$path"
    fi
done

# Remover modelo existente se houver
if ollama show optimized-gemma3 > /dev/null 2>&1; then
    echo -e "${YELLOW}🗑️ Removendo versão anterior do modelo optimized-gemma3...${NC}"
    ollama rm optimized-gemma3
    # Confirmar remoção
    if ollama show optimized-gemma3 > /dev/null 2>&1; then
        echo -e "${RED}❌ Falha ao remover o modelo. Tentando novamente com força...${NC}"
        ollama rm optimized-gemma3 --force
    else
        echo -e "${GREEN}✅ Modelo removido com sucesso${NC}"
    fi
fi

# Verificar se o modelo base existe
if ! ollama show gemma3:1b > /dev/null 2>&1; then
    echo -e "${YELLOW}⬇️ Baixando modelo base gemma3:1b...${NC}"
    ollama pull gemma3:1b
    
    if ! ollama show gemma3:1b > /dev/null 2>&1; then
        echo -e "${RED}❌ Falha ao baixar o modelo base. Saindo.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Modelo base gemma3:1b já existe${NC}"
fi

# Criar modelo a partir do Modelfile
echo -e "${BLUE}🔨 Criando novo modelo optimized-gemma3...${NC}"
ollama create optimized-gemma3 -f "$MODELFILE_PATH" || {
    echo -e "${RED}❌ Falha ao criar o modelo.${NC}"
    exit 1
}

# Verificar se a criação foi bem-sucedida
if ollama show optimized-gemma3 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Modelo optimized-gemma3 reconstruído com sucesso!${NC}"
    echo -e "${BLUE}🔍 Parâmetros do modelo:${NC}"
    ollama show optimized-gemma3 parameters
    echo
    echo -e "${BLUE}📝 Template do modelo:${NC}"
    ollama show optimized-gemma3 template
    echo
    echo -e "${BLUE}🔧 Sistema do modelo:${NC}"
    ollama show optimized-gemma3 system
else
    echo -e "${RED}❌ O modelo não foi criado corretamente.${NC}"
    exit 1
fi

# Criar função de teste para o modelo
echo -e "${BLUE}🧪 Testando o modelo com uma pergunta simples...${NC}"
TEST_RESPONSE=$(echo "Olá, como vai? Por favor responda sem usar asteriscos ou blocos de código." | ollama run optimized-gemma3 2>/dev/null)

echo -e "${YELLOW}Resposta do teste:${NC}"
echo "$TEST_RESPONSE"

# Verificar se há backticks ou asteriscos na resposta
if echo "$TEST_RESPONSE" | grep -q "\`\`\`"; then
    echo -e "${RED}⚠️ AVISO: Ainda há backticks (```) na resposta!${NC}"
else
    echo -e "${GREEN}✅ Não foram detectados backticks na resposta${NC}"
fi

if echo "$TEST_RESPONSE" | grep -q "\*"; then
    echo -e "${RED}⚠️ AVISO: Ainda há asteriscos (*) na resposta!${NC}"
else
    echo -e "${GREEN}✅ Não foram detectados asteriscos na resposta${NC}"
fi

echo
echo -e "${GREEN}🚀 Processo concluído!${NC}"
echo -e "${YELLOW}💡 Para usar o modelo: ${BLUE}ollama run optimized-gemma3${NC}"
echo -e "${YELLOW}⚠️ Se ainda houver problemas, considere ajustar o parâmetro repeat_penalty ou implementar pós-processamento no backend.${NC}"
