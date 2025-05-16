#!/bin/bash
#
# Script para testar o workflow corrigido do n8n
# Data: 11/05/2025
# Autor: Orga.AI Team

# Definir cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Iniciando verificação do workflow n8n...${NC}"

# Verifica se o container n8n está em execução
echo -e "Verificando se o container n8n está em execução..."
if docker ps | grep -q "orga-ai-v4-n8n-1"; then
  echo -e "${GREEN}✅ Container n8n está em execução${NC}"
else
  echo -e "${RED}❌ Container n8n não está em execução. Iniciando...${NC}"
  docker-compose up -d n8n
  echo "Aguardando 10 segundos para inicialização completa..."
  sleep 10
fi

# Verifica se o container Ollama está em execução
echo -e "Verificando se o container Ollama está em execução..."
if docker ps | grep -q "orga-ai-v4-ollama-1"; then
  echo -e "${GREEN}✅ Container Ollama está em execução${NC}"
else
  echo -e "${RED}❌ Container Ollama não está em execução. Iniciando...${NC}"
  docker-compose up -d ollama
  echo "Aguardando 30 segundos para inicialização completa..."
  sleep 30
fi

# Verifica se o modelo gemma3:1b está disponível
echo -e "Verificando se o modelo gemma3:1b está disponível..."
MODEL_CHECK=$(curl -s http://localhost:11434/api/tags | grep -o "gemma3:1b")
if [ "$MODEL_CHECK" == "gemma3:1b" ]; then
  echo -e "${GREEN}✅ Modelo gemma3:1b está disponível${NC}"
else
  echo -e "${RED}❌ Modelo gemma3:1b não encontrado. Baixando...${NC}"
  curl -X POST http://localhost:11434/api/pull -d '{"name": "gemma3:1b"}'
  echo "Aguardando download do modelo (pode levar alguns minutos)..."
  sleep 60
fi

# Verifica se há workflows no n8n
echo -e "Verificando se o workflow está importado no n8n..."
# Esta verificação é limitada pois requer acesso à API do n8n com autenticação
echo -e "${YELLOW}⚠️ Não é possível verificar automaticamente se o workflow está importado. Por favor, verifique manualmente na interface do n8n.${NC}"

echo -e "\n${YELLOW}=== INSTRUÇÕES PARA TESTE MANUAL ===${NC}"
echo -e "1. Acesse a interface do n8n em http://localhost:5678"
echo -e "2. Verifique se o workflow 'n8n_email_daily_tasks' existe"
echo -e "3. Ative o workflow (toggle no canto superior direito)"
echo -e "4. Clique em 'Execute Workflow' para testá-lo manualmente"
echo -e "5. Verifique os resultados de cada nó para confirmar o funcionamento correto"

echo -e "\n${YELLOW}=== VERIFICAÇÃO DE CONFIGURAÇÕES ===${NC}"
echo -e "As seguintes correções foram aplicadas ao workflow:"
echo -e "- Endpoint de IA alterado para '/api/chat' (era '/api/generate')"
echo -e "- Formato do payload atualizado para usar 'messages' com 'role' e 'content'"
echo -e "- Método HTTP alterado para PUT no nó 'Registrar Log de Email'"
echo -e "- Adicionada lógica para extrair corretamente o conteúdo da resposta"
echo -e "- Configurado explicitamente o método GET para o nó 'Obter Tarefas do Usuário'"

echo -e "\n${YELLOW}Para mais detalhes, consulte:${NC}"
echo -e "- /cookbooks/n8n-flows/SOLUCAO_WORKFLOW_OLLAMA_15_05_2025.md"
echo -e "- /cookbooks/n8n-flows/GUIA_TESTE_WORKFLOW_N8N.md"

echo -e "\n${GREEN}Script de verificação concluído.${NC}"
