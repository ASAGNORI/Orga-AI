#!/bin/bash

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Testando conexão com Ollama para N8N ===${NC}"

# Verifica se o Ollama está rodando
echo -e "${YELLOW}Verificando status do serviço Ollama...${NC}"
docker-compose ps ollama
echo ""

# Lista modelos disponíveis
echo -e "${YELLOW}Listando modelos disponíveis no Ollama...${NC}"
curl -s http://localhost:11434/api/tags | grep -o '"name":"[^"]*"' | cut -d'"' -f4
echo ""

# Testa acesso do N8N ao Ollama via nome do serviço
echo -e "${YELLOW}Testando acesso do N8N ao Ollama via nome do serviço...${NC}"
docker-compose exec -u root n8n sh -c "apk add --no-cache curl >/dev/null 2>&1 && curl -s ollama:11434/api/tags" | grep -o '"name":"[^"]*"' | cut -d'"' -f4
if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ N8N consegue acessar o Ollama via 'ollama:11434'${NC}"
else
  echo -e "${RED}❌ N8N NÃO consegue acessar o Ollama via 'ollama:11434'${NC}"
fi
echo ""

# Testa acesso do N8N ao Ollama via host.docker.internal
echo -e "${YELLOW}Testando acesso do N8N ao Ollama via host.docker.internal...${NC}"
docker-compose exec -u root n8n sh -c "apk add --no-cache curl >/dev/null 2>&1 && curl -s host.docker.internal:11434/api/tags" | grep -o '"name":"[^"]*"' | cut -d'"' -f4
if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ N8N consegue acessar o Ollama via 'host.docker.internal:11434'${NC}"
else
  echo -e "${RED}❌ N8N NÃO consegue acessar o Ollama via 'host.docker.internal:11434'${NC}"
fi
echo ""

# Testa o modelo específico
echo -e "${YELLOW}Testando modelo mistral no Ollama...${NC}"
MISTRAL_TEST=$(curl -s -X POST -H "Content-Type: application/json" -d '{"model":"mistral","messages":[{"role":"user","content":"olá"}]}' http://localhost:11434/api/chat)
if [[ $MISTRAL_TEST == *"error"* ]]; then
  echo -e "${RED}❌ O modelo 'mistral' não está disponível no Ollama${NC}"
  echo -e "${YELLOW}Mensagem de erro:${NC} $(echo $MISTRAL_TEST | grep -o '"error":"[^"]*"' | cut -d'"' -f4)"
  echo ""
  echo -e "${YELLOW}Tentando baixar o modelo mistral...${NC}"
  echo -e "Isto pode demorar alguns minutos..."
  docker-compose exec ollama ollama pull mistral:7b-instruct
else
  echo -e "${GREEN}✅ O modelo 'mistral' está disponível e funcional${NC}"
fi
echo ""

echo -e "${GREEN}=== Recomendações ===${NC}"
echo -e "1. Edite o nó 'Gerar Conteúdo do Email com IA' no N8N:"
echo -e "   - URL: ${YELLOW}http://ollama:11434/api/chat${NC}"
echo -e "   - Método: ${YELLOW}POST${NC}"
echo -e "   - Body JSON: ${YELLOW}{\n  \"model\": \"mistral\",\n  \"messages\": [\n    {\n      \"role\": \"system\",\n      \"content\": \"Você é um assistente especializado em produtividade...\"\n    },\n    {\n      \"role\": \"user\",\n      \"content\": {{prompt}}\n    }\n  ]\n}${NC}"
echo ""
echo -e "2. Certifique-se de que o modelo 'mistral' está disponível no Ollama:"
echo -e "   - Execute: ${YELLOW}docker-compose exec ollama ollama pull mistral:7b-instruct${NC}"
echo ""
echo -e "3. Se o erro persistir, edite docker-compose.yml para expor a porta do Ollama:"
echo -e "   Adicione na seção do n8n sob 'extra_hosts':"
echo -e "   ${YELLOW}extra_hosts:\n      - \"host.docker.internal:host-gateway\"${NC}"
echo ""

echo -e "${GREEN}Testes concluídos!${NC}"
