#!/bin/bash

# Script para testar a conectividade entre N8N e Ollama
# Autor: Orga.AI Team
# Data: 11 de maio de 2025

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Cabeçalho
echo -e "${BLUE}=== Test de Conectividade N8N para Ollama ===${NC}"
echo -e "${BLUE}Data: $(date) ${NC}"
echo ""

# Verificar se os containers estão rodando
echo -e "${YELLOW}1. Verificando status dos containers...${NC}"
n8n_status=$(docker-compose ps n8n | grep "Up" || echo "Parado")
ollama_status=$(docker-compose ps ollama | grep "Up" || echo "Parado")

if [[ "$n8n_status" == *"Up"* ]]; then
  echo -e "${GREEN}✓ Container N8N está rodando${NC}"
else
  echo -e "${RED}✗ Container N8N não está rodando!${NC}"
  exit 1
fi

if [[ "$ollama_status" == *"Up"* ]]; then
  echo -e "${GREEN}✓ Container Ollama está rodando${NC}"
else
  echo -e "${RED}✗ Container Ollama não está rodando!${NC}"
  exit 1
fi

echo ""
echo -e "${YELLOW}2. Testando ping do N8N para Ollama...${NC}"
# Testar ping interno do N8N para o Ollama (por nome)
if docker-compose exec n8n ping -c 2 ollama > /dev/null 2>&1; then
  echo -e "${GREEN}✓ Ping de N8N para 'ollama' funciona${NC}"
else
  echo -e "${RED}✗ Ping de N8N para 'ollama' falhou${NC}"
fi

echo ""
echo -e "${YELLOW}3. Obtendo IP interno do Ollama...${NC}"
ollama_ip=$(docker network inspect orga-ai-v4_app-network | grep -A 5 "\"ollama\"" | grep "IPv4Address" | sed -E 's/.*"([0-9.]+)\/.*$/\1/')
echo -e "${GREEN}IP do Ollama: $ollama_ip${NC}"

echo ""
echo -e "${YELLOW}4. Testando ping para o IP do Ollama...${NC}"
if docker-compose exec n8n ping -c 2 $ollama_ip > /dev/null 2>&1; then
  echo -e "${GREEN}✓ Ping de N8N para IP do Ollama funciona${NC}"
else
  echo -e "${RED}✗ Ping de N8N para IP do Ollama falhou${NC}"
fi

echo ""
echo -e "${YELLOW}5. Verificando API do Ollama pelo N8N (usando nome)...${NC}"
if docker-compose exec n8n curl -s http://ollama:11434/api/version > /dev/null; then
  echo -e "${GREEN}✓ N8N consegue acessar a API do Ollama pelo nome${NC}"
  api_version=$(docker-compose exec n8n curl -s http://ollama:11434/api/version)
  echo -e "${GREEN}  Versão da API: $api_version${NC}"
else
  echo -e "${RED}✗ N8N NÃO consegue acessar a API do Ollama pelo nome${NC}"
fi

echo ""
echo -e "${YELLOW}6. Verificando API do Ollama pelo N8N (usando IP)...${NC}"
if docker-compose exec n8n curl -s http://$ollama_ip:11434/api/version > /dev/null; then
  echo -e "${GREEN}✓ N8N consegue acessar a API do Ollama pelo IP${NC}"
  api_version=$(docker-compose exec n8n curl -s http://$ollama_ip:11434/api/version)
  echo -e "${GREEN}  Versão da API: $api_version${NC}"
else
  echo -e "${RED}✗ N8N NÃO consegue acessar a API do Ollama pelo IP${NC}"
fi

echo ""
echo -e "${YELLOW}7. Testando endpoint /api/generate do Ollama...${NC}"
generate_test=$(docker-compose exec n8n curl -s -X POST http://ollama:11434/api/generate -H "Content-Type: application/json" -d '{"model":"phi","prompt":"hello","stream":false}')

if [[ "$generate_test" == *"response"* ]]; then
  echo -e "${GREEN}✓ Endpoint /api/generate está funcionando corretamente${NC}"
else
  echo -e "${RED}✗ Endpoint /api/generate falhou ou retornou erro${NC}"
  echo -e "${RED}  Resposta: $generate_test${NC}"
fi

echo ""
echo -e "${YELLOW}8. Verificando modelos disponíveis...${NC}"
models=$(docker-compose exec ollama curl -s http://localhost:11434/api/tags | grep -o '"name":"[^"]*' | sed 's/"name":"//')
echo -e "${GREEN}Modelos disponíveis:${NC}"
echo "$models"

echo ""
echo -e "${BLUE}=== Conclusão ===${NC}"
echo -e "Para usar no workflow N8N, considere as seguintes opções:"
echo -e "1. Usar nome: ${GREEN}http://ollama:11434/api/generate${NC}"
echo -e "2. Usar IP direto: ${GREEN}http://$ollama_ip:11434/api/generate${NC}"
echo -e "3. Use o modelo: ${GREEN}phi${NC}"
