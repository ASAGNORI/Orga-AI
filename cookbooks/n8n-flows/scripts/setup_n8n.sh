#!/bin/bash

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Título
echo -e "${GREEN}=== Script de Configuração do N8N para Orga.AI ===${NC}"

# Verifica se o N8N está rodando
echo -e "${YELLOW}Verificando se o N8N está acessível...${NC}"
if ! curl -s -o /dev/null http://localhost:5678; then
  echo -e "${RED}Erro: N8N não está acessível em http://localhost:5678${NC}"
  echo -e "${YELLOW}Certifique-se de que o N8N está rodando e tente novamente.${NC}"
  exit 1
fi

echo -e "${GREEN}✅ N8N está rodando.${NC}"

# Instruções para o usuário
echo ""
echo -e "${GREEN}==== CONFIGURAÇÃO DO FLUXO DE EMAILS DIÁRIOS ====${NC}"
echo ""
echo "Para configurar corretamente o fluxo de emails diários, siga estas etapas:"
echo ""
echo -e "${YELLOW}1. Acesse o N8N em http://localhost:5678${NC}"
echo "2. Faça login como 'admin' (senha: 'admin123')"
echo -e "${YELLOW}3. Configure as credenciais para autenticação de API:${NC}"
echo "   - No N8N, vá até 'Credentials'"
echo "   - Crie nova credencial do tipo 'Header Auth'"
echo "   - Nome: admin-api-key"
echo "   - Nome do cabeçalho: Authorization"
echo "   - Valor do cabeçalho: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhbmdlbG8uc2Fnbm9yaUBnbWFpbC5jb20iLCJlbWFpbCI6ImFuZ2Vsby5zYWdub3JpQGdtYWlsLmNvbSIsImlzX2FkbWluIjp0cnVlLCJleHAiOjE3Nzg0MjI4MDZ9.8Pzu17w_JT2C35WCPvYIKHIow7BcsGAUYm3fBv0Ebf4"
echo "   - IMPORTANTE: Certifique-se de incluir a palavra 'Bearer ' (com espaço depois) antes do token JWT"
echo ""
echo -e "${YELLOW}4. Configure as credenciais SMTP para envio de emails:${NC}"
echo "   - Crie nova credencial do tipo 'SMTP'"
echo "   - Nome: orga-ai-smtp"
echo "   - Configure com os dados do seu servidor SMTP"
echo ""
echo -e "${YELLOW}5. Importe o arquivo de fluxo de trabalho:${NC}"
echo "   - Vá até 'Workflows'"
echo "   - Clique no botão '+' para criar novo"
echo "   - Clique no menu '⋮' (três pontos) no canto superior direito"
echo "   - Selecione 'Import from File'"
echo "   - Escolha o arquivo 'n8n_email_daily_tasks_header_auth.json'"
echo ""
echo -e "${YELLOW}6. Ative o workflow após verificar a configuração${NC}"
echo ""
echo -e "${GREEN}Para mais detalhes, consulte o arquivo SETUP_GUIDE.md${NC}"
echo ""

# Opções para o usuário
echo -e "${GREEN}=== Escolha uma opção: ===${NC}"
echo "1) Abrir o N8N no navegador"
echo "2) Gerar um novo token JWT de administrador"
echo "3) Sair"
echo

read -p "Opção: " option

case $option in
  1)
    if command -v xdg-open > /dev/null; then
      xdg-open http://localhost:5678
    elif command -v open > /dev/null; then
      open http://localhost:5678
    else
      echo -e "${RED}Não foi possível abrir automaticamente. Por favor, acesse http://localhost:5678 manualmente.${NC}"
    fi
    ;;
  2)
    echo -e "${YELLOW}Gerando um novo token JWT de administrador válido por 1 ano...${NC}"
    token=$(docker-compose exec backend python -c "import jwt; from datetime import datetime, timedelta; print(jwt.encode({'sub': 'angelo.sagnori@gmail.com', 'email': 'angelo.sagnori@gmail.com', 'is_admin': True, 'exp': datetime.now() + timedelta(days=365)}, 'nSwUBmLT6/XHzoHHlW3l2AjGWO6+xUlqY/LVjngUEUs=', algorithm='HS256'))")
    echo -e "${GREEN}Novo token JWT gerado:${NC}"
    echo "$token"
    echo
    echo -e "${YELLOW}Para usar este token, copie o valor completo e configure na credencial 'Header Auth' do N8N.${NC}"
    echo -e "${YELLOW}Lembre-se de adicionar 'Bearer ' (com espaço) antes do token.${NC}"
    ;;
  3)
    echo -e "${GREEN}Saindo...${NC}"
    exit 0
    ;;
  *)
    echo -e "${RED}Opção inválida.${NC}"
    exit 1
    ;;
esac

echo
echo -e "${GREEN}=== Configuração Concluída ===${NC}"
echo -e "${YELLOW}Script concluído. Boa sorte com sua implementação do N8N!${NC}"
