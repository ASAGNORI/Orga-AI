#!/bin/bash

# Script para configurar o n8n para recuperação de senha
# Autor: GitHub Copilot
# Data: 13/05/2025

# Cores para formatação
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sem cor

echo -e "${BLUE}=== Configuração de Recuperação de Senha para n8n ===${NC}"
echo

# Verifica se o arquivo .env existe
if [ ! -f .env ]; then
  echo -e "${RED}Arquivo .env não encontrado. Este script deve ser executado no diretório raiz do projeto.${NC}"
  exit 1
fi

# Menu de configuração de email
echo -e "${YELLOW}Configuração do Serviço de Email${NC}"
echo "Selecione o provedor de email:"
echo "1) Gmail"
echo "2) Outlook/Office 365"
echo "3) Outro (configuração manual)"
read -p "Escolha uma opção (1-3): " email_option

case $email_option in
  1)
    SMTP_HOST="smtp.gmail.com"
    SMTP_PORT="465"
    SMTP_SSL="true"
    echo -e "${YELLOW}Configuração para Gmail selecionada${NC}"
    echo -e "${RED}IMPORTANTE: Para o Gmail, você precisa criar uma senha de aplicativo.${NC}"
    echo -e "Siga as instruções em: https://support.google.com/accounts/answer/185833"
    ;;
  2)
    SMTP_HOST="smtp.office365.com"
    SMTP_PORT="587"
    SMTP_SSL="false"
    echo -e "${YELLOW}Configuração para Outlook/Office 365 selecionada${NC}"
    ;;
  3)
    read -p "SMTP Host (ex: smtp.provider.com): " SMTP_HOST
    read -p "SMTP Port (ex: 587 ou 465): " SMTP_PORT
    read -p "Usar SSL? (true/false): " SMTP_SSL
    echo -e "${YELLOW}Configuração manual inserida${NC}"
    ;;
  *)
    echo -e "${RED}Opção inválida. Usando configuração padrão (Gmail).${NC}"
    SMTP_HOST="smtp.gmail.com"
    SMTP_PORT="465"
    SMTP_SSL="true"
    ;;
esac

# Solicita informações de login
read -p "Email de envio: " SMTP_USER
read -p "Nome de exibição do remetente: " SENDER_NAME
read -s -p "Senha (ou senha de aplicativo): " SMTP_PASS
echo

# Atualiza o arquivo .env
echo -e "${BLUE}Atualizando configurações no arquivo .env...${NC}"

# Backup do arquivo .env
cp .env .env.bak.$(date +"%Y%m%d%H%M%S")
echo -e "${GREEN}Backup do arquivo .env criado${NC}"

# Remove configurações existentes de email se houver
sed -i '' '/N8N_EMAIL_MODE/d' .env
sed -i '' '/N8N_SMTP_HOST/d' .env
sed -i '' '/N8N_SMTP_PORT/d' .env
sed -i '' '/N8N_SMTP_USER/d' .env
sed -i '' '/N8N_SMTP_PASS/d' .env
sed -i '' '/N8N_SMTP_SENDER/d' .env
sed -i '' '/N8N_SMTP_SSL/d' .env

# Adiciona novas configurações
echo "" >> .env
echo "# Configuração de Email para n8n" >> .env
echo "N8N_EMAIL_MODE=smtp" >> .env
echo "N8N_SMTP_HOST=${SMTP_HOST}" >> .env
echo "N8N_SMTP_PORT=${SMTP_PORT}" >> .env
echo "N8N_SMTP_USER=${SMTP_USER}" >> .env
echo "N8N_SMTP_PASS=${SMTP_PASS}" >> .env
echo "N8N_SMTP_SENDER=\"${SENDER_NAME} <${SMTP_USER}>\"" >> .env
echo "N8N_SMTP_SSL=${SMTP_SSL}" >> .env

# Ativa o gerenciamento de usuários
echo -e "${BLUE}Ativando gerenciamento de usuários e autenticação...${NC}"
sed -i '' 's/N8N_USER_MANAGEMENT_DISABLED=true/N8N_USER_MANAGEMENT_DISABLED=false/g' .env
sed -i '' 's/N8N_BASIC_AUTH_ACTIVE=false/N8N_BASIC_AUTH_ACTIVE=true/g' .env

# Reinicia o contêiner n8n
echo -e "${BLUE}Reiniciando o contêiner n8n...${NC}"
docker-compose restart n8n

# Aguarda a reinicialização
echo -e "${YELLOW}Aguardando reinicialização do n8n...${NC}"
sleep 10

echo -e "${GREEN}=== Configuração concluída! ===${NC}"
echo -e "O n8n agora deve estar configurado para enviar emails de recuperação de senha."
echo
echo -e "${YELLOW}IMPORTANTE:${NC}"
echo "1. Se estiver usando Gmail, certifique-se de usar uma senha de aplicativo."
echo "2. Você pode acessar o n8n em: http://localhost:5678"
echo "3. As credenciais padrão são:"
echo "   - Usuário: admin@example.com"
echo "   - Senha: admin123"
echo
echo -e "${BLUE}Para verificar se a configuração está funcionando:${NC}"
echo "1. Acesse o n8n"
echo "2. Clique em 'Forgot your password?'"
echo "3. Digite seu email de administrador e verifique se você recebe o email de recuperação"
echo
