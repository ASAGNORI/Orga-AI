#!/bin/bash

# Script para diagnóstico e solução de problemas de conexão entre N8N e Ollama
# Data: 10 de maio de 2025

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Diagnóstico de Conexão N8N-Ollama ===${NC}"

# Verificar se os serviços estão rodando
echo -e "\n${YELLOW}Verificando status dos serviços...${NC}"
n8n_running=$(docker-compose ps | grep "n8n.*Up" | wc -l)
ollama_running=$(docker-compose ps | grep "ollama.*Up" | wc -l)

if [ $n8n_running -eq 0 ]; then
  echo -e "${RED}❌ N8N não está rodando!${NC}"
else
  echo -e "${GREEN}✅ N8N está rodando${NC}"
fi

if [ $ollama_running -eq 0 ]; then
  echo -e "${RED}❌ Ollama não está rodando!${NC}"
else
  echo -e "${GREEN}✅ Ollama está rodando${NC}"
fi

# Verificar se os serviços estão na mesma rede
echo -e "\n${YELLOW}Verificando rede Docker...${NC}"
n8n_network=$(docker network inspect orga-ai-v4_app-network | grep -A 5 "n8n" | wc -l)
ollama_network=$(docker network inspect orga-ai-v4_app-network | grep -A 5 "ollama" | wc -l)

if [ $n8n_network -eq 0 ] || [ $ollama_network -eq 0 ]; then
  echo -e "${RED}❌ Serviços não estão na mesma rede!${NC}"
else
  echo -e "${GREEN}✅ Ambos os serviços estão na rede app-network${NC}"
fi

# Pegar o IP do Ollama
echo -e "\n${YELLOW}Obtendo IP do Ollama...${NC}"
ollama_ip=$(docker network inspect orga-ai-v4_app-network | grep -A 5 "ollama" | grep "IPv4Address" | sed -E 's/.*"([0-9.]+)\/.*$/\1/')

if [ -z "$ollama_ip" ]; then
  echo -e "${RED}❌ Não foi possível obter o IP do Ollama!${NC}"
else
  echo -e "${GREEN}✅ IP do Ollama: $ollama_ip${NC}"
fi

# Testar ping do N8N para o Ollama
echo -e "\n${YELLOW}Testando ping do N8N para o Ollama...${NC}"
ping_result=$(docker-compose exec n8n ping -c 2 ollama 2>&1)
ping_success=$?

if [ $ping_success -eq 0 ]; then
  echo -e "${GREEN}✅ Ping para 'ollama' funcionou!${NC}"
else
  echo -e "${RED}❌ Ping falhou! Detalhes:${NC}\n$ping_result"
fi

# Testar ping direto para o IP
echo -e "\n${YELLOW}Testando ping do N8N para o IP do Ollama...${NC}"
if [ -n "$ollama_ip" ]; then
  ping_ip_result=$(docker-compose exec n8n ping -c 2 $ollama_ip 2>&1)
  ping_ip_success=$?
  
  if [ $ping_ip_success -eq 0 ]; then
    echo -e "${GREEN}✅ Ping para IP '$ollama_ip' funcionou!${NC}"
  else
    echo -e "${RED}❌ Ping para IP falhou! Detalhes:${NC}\n$ping_ip_result"
  fi
else
  echo -e "${RED}❌ Não foi possível testar ping para IP (IP não disponível)${NC}"
fi

# Testar conexão direta via cURL
echo -e "\n${YELLOW}Testando API do Ollama via curl (do N8N)...${NC}"
curl_result=$(docker-compose exec n8n sh -c "wget -qO- http://ollama:11434/api/version 2>&1 || echo 'Falha na conexão'")

if [[ $curl_result == *"Falha"* ]]; then
  echo -e "${RED}❌ Teste de API falhou!${NC}"
else
  echo -e "${GREEN}✅ API do Ollama respondeu: $curl_result${NC}"
fi

# Verificar modelos disponíveis
echo -e "\n${YELLOW}Verificando modelos disponíveis no Ollama...${NC}"
models_result=$(curl -s http://localhost:11434/api/tags | grep -o '"name":"[^"]*' | sed 's/"name":"//' | tr '\n' ', ')

if [ -n "$models_result" ]; then
  echo -e "${GREEN}✅ Modelos disponíveis: $models_result${NC}"
else
  echo -e "${RED}❌ Não foi possível obter a lista de modelos${NC}"
fi

# Recomendações baseadas nos diagnósticos
echo -e "\n${BLUE}=== Recomendações ===============${NC}"
if [ $ping_success -eq 0 ] && [[ $curl_result != *"Falha"* ]]; then
  echo -e "${GREEN}✅ A configuração de rede parece OK. Se ainda houver problemas:${NC}"
  echo -e "   1. No N8N, certifique-se de usar o hostname: http://ollama:11434/api/chat"
  echo -e "   2. Certifique-se de que o corpo da requisição esteja configurado com o modelo correto:"
  echo -e "      - model: \"phi\" (disponível em seu sistema)"
  echo -e "   3. Verifique se há problemas com a resolução IPv6 no N8N"
  echo -e "   4. Verifique se no workflow do N8N a opção 'Usar proxy padrão' está desativada"
else
  echo -e "${RED}❗ Há problemas de conectividade. Tente:${NC}"
  echo -e "   1. Reiniciar os contêineres: docker-compose restart n8n ollama"
  echo -e "   2. Verificar se o hostname 'ollama' está sendo resolvido corretamente"
  echo -e "   3. Verifique os logs: docker-compose logs n8n | grep -i error"
  echo -e "   4. Verifique a configuração de rede no docker-compose.yml"
fi

echo -e "\n${BLUE}===============================${NC}"
