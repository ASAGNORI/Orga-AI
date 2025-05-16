# 🛠️ Ambiente de Desenvolvimento (DevContainer) - Orga.AI

Este diretório contém a configuração do DevContainer (ambiente de desenvolvimento baseado em containers) para o projeto Orga.AI. O DevContainer permite que todos os desenvolvedores trabalhem em um ambiente consistente e pré-configurado, independentemente de seu sistema operacional.

## 🔍 O que é um DevContainer?

DevContainers (Development Containers) são ambientes de desenvolvimento isolados e consistentes que rodam em containers Docker. Eles permitem:

- Manter todas as dependências e ferramentas necessárias em um único local
- Garantir que todos os desenvolvedores tenham o mesmo ambiente de trabalho
- Evitar o clássico problema "funciona na minha máquina"
- Simplificar o onboarding de novos desenvolvedores

## 🚀 Como usar o DevContainer do Orga.AI

### Pré-requisitos

Antes de começar, você precisa ter instalado:

1. [Visual Studio Code](https://code.visualstudio.com/)
2. [Docker Desktop](https://www.docker.com/products/docker-desktop)
3. Extensão [Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) no VS Code

### Iniciando o DevContainer

1. Abra o VS Code
2. Abra a pasta do projeto Orga.AI
3. Quando solicitado, clique em "Reopen in Container"
   - Ou use o comando através da paleta de comandos (F1): "Remote-Containers: Reopen in Container"
4. Aguarde enquanto o VS Code cria e configura o ambiente de desenvolvimento

### O que está incluído no DevContainer

O DevContainer do Orga.AI inclui:

#### Ambiente de Desenvolvimento

- **Backend**: Python 3.12 com FastAPI
- **Frontend**: Node.js 18 com Next.js
- **Ferramentas**: Git, Docker CLI, e utilidades de desenvolvimento

#### Extensões VS Code Pré-configuradas

O ambiente já vem com extensões recomendadas para o projeto:

**Python**
- Python, Pylance, Black formatter, MyPy

**JavaScript/TypeScript**
- ESLint, Prettier, Tailwind CSS, Auto Rename Tag

**Docker & Infraestrutura**
- Docker, Remote Containers

**Database**
- PostgreSQL Client

**Utilitários**
- Code Spell Checker, GitLens, GitHub Copilot

**IA**
- LlamaIndex, Rubberduck

#### Configurações Otimizadas

O DevContainer já possui configurações otimizadas para:

- Formatação automática ao salvar
- Linting para Python e TypeScript/JavaScript
- Integração com Tailwind CSS
- Emmet para React e TypeScript

## 📋 Configuração Personalizada

O arquivo `devcontainer.json` contém todas as configurações do ambiente de desenvolvimento. Você pode personalizar:

- Extensões instaladas
- Configurações do VS Code
- Portas encaminhadas
- Scripts pós-criação e pós-inicialização
- Volumes e montagens

### Portas encaminhadas

O DevContainer já está configurado para encaminhar as seguintes portas:

- `3000`: Frontend (Next.js)
- `8000`: Backend API (FastAPI)
- `11435`: Ollama (API de modelo de linguagem)
- `5678`: N8N (Automação)
- `54321`: Supabase API
- `54323`: Supabase Studio

### Volumes e Persistência

Os volumes do DevContainer estão configurados para:

- Persistir as alterações no código do frontend e backend
- Manter os dados do banco de dados e outros serviços

## ⚠️ Solução de Problemas

Se você encontrar problemas com o DevContainer:

1. **Container não inicia**: Verifique se o Docker está em execução e tem recursos suficientes (memória/CPU)
2. **Problemas de permissão**: Execute `sudo chown -R $(id -u):$(id -g) .` na pasta do projeto
3. **Serviços inacessíveis**: Use `./scripts/sh/health-check.sh` dentro do container
4. **Dependências faltando**: Execute o script de pós-criação manualmente (`./scripts/sh/health-check.sh`)

### Reconstruindo o DevContainer

Se necessário, você pode reconstruir o DevContainer:

1. Pressione F1 e selecione "Remote-Containers: Rebuild Container"
2. Aguarde a reconstrução do container

## 🔧 Customização Avançada

### Usando GPU com Ollama

Para habilitar suporte a GPU para o Ollama:

1. Abra o arquivo `.devcontainer/devcontainer.json`
2. Descomente a linha `"--gpus=all"` na seção `runArgs`
3. Reconstrua o DevContainer

### Adicionando novas extensões

Para adicionar extensões personalizadas:

1. Abra o arquivo `.devcontainer/devcontainer.json`
2. Adicione suas extensões à matriz `extensions` na seção `customizations.vscode`
3. Reconstrua o DevContainer

## 📚 Leitura Complementar

- [Documentação oficial do DevContainers](https://code.visualstudio.com/docs/remote/containers)
- [Especificação do devcontainer.json](https://containers.dev/implementors/json_reference/)
- [Melhores práticas para DevContainers](https://code.visualstudio.com/remote/advancedcontainers/overview)

---

Desenvolvido com ❤️ pela equipe Orga.AI