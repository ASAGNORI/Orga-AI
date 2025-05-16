#!/bin/bash

# Cores para melhor visualização
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Orga.AI - Configuração de Ambiente ===${NC}"

echo "🚀 Iniciando setup do ambiente virtual Python..."

# Define nome do venv
VENV_DIR=".venv"

# Verifica se o venv já existe
if [ -d "$VENV_DIR" ]; then
  echo "✅ Ambiente virtual já existe em $VENV_DIR"
else
  echo "🔧 Criando ambiente virtual em $VENV_DIR"
  python3 -m venv $VENV_DIR
fi

# Ativa o ambiente
source "$VENV_DIR/bin/activate"

echo "📦 Atualizando pip..."
pip install --upgrade pip

echo "📚 Instalando dependências do requirements.txt..."
pip install -r requirements.txt --prefer-binary --verbose

echo "✅ Setup do Python finalizado com sucesso!"
echo "💡 Para ativar o ambiente depois, use: source .venv/bin/activate"

echo ""
echo -e "${YELLOW}=== Configuração de Variáveis de Ambiente ===${NC}"
echo -e "${YELLOW}⚠️  AVISO: Nunca cometa arquivos .env no Git!${NC}"
echo ""

# Verificar se os arquivos .env já existem
if [ -f "./backend/.env" ]; then
  echo -e "${YELLOW}Arquivo backend/.env já existe.${NC}"
  read -p "Deseja substituí-lo? (s/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${BLUE}Mantendo o arquivo backend/.env existente.${NC}"
  else
    if [ -f "./backend/.env.example" ]; then
      cp ./backend/.env.example ./backend/.env
      echo -e "${GREEN}Arquivo backend/.env criado com sucesso!${NC}"
    else
      echo -e "${RED}Arquivo backend/.env.example não encontrado!${NC}"
      exit 1
    fi
  fi
else
  if [ -f "./backend/.env.example" ]; then
    cp ./backend/.env.example ./backend/.env
    echo -e "${GREEN}Arquivo backend/.env criado com sucesso!${NC}"
    echo -e "${YELLOW}⚠️  Lembre-se de editar o arquivo com suas credenciais reais.${NC}"
  else
    echo -e "${RED}Arquivo backend/.env.example não encontrado!${NC}"
    exit 1
  fi
fi

# Verificar se o arquivo frontend/.env.example existe e criar frontend/.env
if [ -f "./frontend/.env.example" ]; then
  if [ -f "./frontend/.env" ]; then
    echo -e "${YELLOW}Arquivo frontend/.env já existe.${NC}"
    read -p "Deseja substituí-lo? (s/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
      echo -e "${BLUE}Mantendo o arquivo frontend/.env existente.${NC}"
    else
      cp ./frontend/.env.example ./frontend/.env
      echo -e "${GREEN}Arquivo frontend/.env criado com sucesso!${NC}"
    fi
  else
    cp ./frontend/.env.example ./frontend/.env
    echo -e "${GREEN}Arquivo frontend/.env criado com sucesso!${NC}"
    echo -e "${YELLOW}⚠️  Lembre-se de editar o arquivo com suas credenciais reais.${NC}"
  fi
fi

echo ""
echo -e "${YELLOW}Você precisa editar os arquivos .env para adicionar suas credenciais.${NC}"
echo -e "${RED}IMPORTANTE: NUNCA cometa os arquivos .env no Git para proteger suas credenciais!${NC}"
echo ""

# Perguntar se o usuário quer editar os arquivos agora
read -p "Deseja editar o arquivo backend/.env agora? (s/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
  if command -v nano > /dev/null; then
    nano ./backend/.env
  elif command -v vim > /dev/null; then
    vim ./backend/.env
  else
    echo -e "${YELLOW}Por favor, edite o arquivo backend/.env manualmente.${NC}"
  fi
fi

echo ""
echo -e "${GREEN}=== Configuração de ambiente concluída! ===${NC}"
echo -e "${BLUE}Você pode iniciar o projeto agora com: ./scripts/sh/start.sh${NC}"
echo ""
