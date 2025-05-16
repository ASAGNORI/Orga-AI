# Orga.AI - Sua vida organizada com inteligência

## 📋 Visão Geral

Orga.AI é uma aplicação moderna de produtividade que combina gerenciamento de tarefas com inteligência artificial para otimizar seu fluxo de trabalho. A plataforma utiliza tecnologias de ponta como Next.js, FastAPI, Supabase e modelos de IA para oferecer uma experiência única de organização e automação.

## ✨ Funcionalidades Principais

### Funcionalidades-Chave (MVP)
- **Painel Kanban com IA**: Criação automática de cards a partir de e-mails, mensagens ou voz
- **To-do List com Prioridade Inteligente**: Organização automática por urgência, energia e tempo
- **Calendário Integrado**: Sincronização com Google Calendar e sugestões de reorganização
- **Alertas Inteligentes**: Notificações via WhatsApp ou e-mail baseadas em hábitos e prazos
- **Assistente IA**:
  - Criação de tarefas por comando de voz ou texto
  - Sugestões de reorganização de agenda
  - Redação/resposta de e-mails e mensagens no WhatsApp com base em contexto
  - Geração de resumos semanais e planos de ação
  - **Prompts Salvos**: Armazenamento e reutilização de prompts frequentes

### Dashboard de Acompanhamento com IA
- **Indicadores principais**:
  - Tarefas cumpridas e não cumpridas
  - Tarefas atrasadas
  - Metas alcançadas e pendentes
  - Tarefas em andamento (por status ou tag)
  - Horas de foco real (calculado via padrão de uso ou timer com IA)
- **Visão Gráfica**:
  - Gráfico da semana (atividades por dia, calor de produtividade)
  - Gráfico de foco (pomodoro, tempo de dedicação, interrupções)

### Funções Avançadas de Replanejamento com IA
- IA detecta sobrecarga, atraso, ou padrões negativos
  - Sugere redistribuição de tarefas
  - Proporcionalmente ajusta prazos com base na rotina
  - Prioriza metas críticas e envia alertas para realinhamento

## 🧠 Sistema Avançado de Chat com IA

### Arquitetura de Chat Inteligente
O sistema de chat utiliza uma combinação sofisticada de tecnologias:

1. **Sistema Híbrido de Processamento**:
   - **Reconhecimento de Intenção**: Processamento rápido de comandos simples
   - **RAG (Retrieval Augmented Generation)**: Enriquecimento de contexto com dados do usuário
   - **LLM (Large Language Model)**: Processamento avançado via Ollama

2. **Funcionalidades do Chat**:
   - **Histórico de Conversas**: Armazenamento e recuperação do histórico de interações
   - **Prompts Salvos**: Biblioteca de prompts frequentes personalizáveis
   - **Sugestão de Tags**: Categorização automática de conversas
   - **Streaming de Respostas**: Feedback em tempo real para melhor experiência

3. **Sugestão de Atributos de Tarefas**:
   - Análise inteligente para sugerir prioridade, tags e tempo estimado
   - Extração automática de elementos chave das tarefas

### Gerenciamento de Prompts Salvos
- Interface dedicada para adicionar, visualizar e reutilizar prompts
- Organização por categorias e tags
- Acesso rápido aos prompts mais utilizados
- Diferentes limites de armazenamento por plano de assinatura

## 🛠 Stack Tecnológica

### Frontend
- Next.js 14
- React 18
- TailwindCSS
- Framer Motion
- Supabase Client
- Zustand (Gerenciamento de estado)

### Backend
- FastAPI
- Python 3.12
- SQLAlchemy
- LlamaIndex
- Transformers
- Torch

### Infraestrutura
- Docker & Docker Compose
- Supabase (PostgreSQL)
- Kong API Gateway
- N8N (Automação)

### IA/Agente
- Ollama (llama3, mistral, neural-chat)
- Langchain
- RAG com dados do usuário
- Modelos de linguagem avançados
- Sentence Transformers para embeddings

## 🚀 Como Executar

### Pré-requisitos
- Docker e Docker Compose
- Git
- Node.js 18+ (para desenvolvimento)
- Python 3.11+ (para desenvolvimento)

### Scripts Principais
- `./scripts/reinstall.sh` – Limpa volumes, rebuild e inicia todos os serviços
- `./scripts/sh/start.sh [--frontend-only] [--backend-only] [--no-docker]` – Inicia o projeto em modo desenvolvimento com Docker
- `./scripts/sh/run-migrations.sh` – Executa todos os scripts em `scripts/sql`
- `./scripts/sh/init-ollama.sh` – Inicializa o servidor Ollama e baixa os modelos necessários
- `./scripts/sh/push-ollama-model.sh` – Gerencia o download de modelos específicos do Ollama
- `./scripts/sh/apply_all_fixes.sh` - Aplica todas as correções de banco de dados e configuração (ver [documentação de correções](docs/FIXES_MAY_13_2025.md))

### Desenvolvimento

#### Frontend
```bash
cd frontend
npm install
npm run dev
```

#### Backend
```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # ou .venv\Scripts\activate no Windows
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### Configuração do Ambiente
1. **Configuração inicial**: 
   ```bash
   cp .env.example .env
   ```
2. **Edite o arquivo .env** com suas configurações específicas:
   - `OLLAMA_MODEL`: Modelo principal (padrão: "gemma3:1b")
   - `OLLAMA_MODEL_CHAT`: Modelo de chat (padrão: "gemma3:1b")
   - Credenciais do banco de dados e serviços

### Acessando os Serviços
- Frontend: http://localhost:3010
- Backend API: http://localhost:8000/api/docs
- Supabase Studio: http://localhost:54323
- N8N: http://localhost:5678
- Open-WebUI (Interface Ollama): http://localhost:3000
- Ollama API: http://localhost:11434

### Acesso via Rede Local
Para acessar a aplicação de outros dispositivos na mesma rede:
1. Use o IP local da máquina host (ex: http://192.168.0.10:3010)
2. As configurações CORS e de rede já estão ajustadas para permitir acesso remoto

## 📦 Estrutura do Projeto
```
orga-ai-v4/
├── frontend/              # Aplicação Next.js
│   ├── app/               # Componentes, serviços e lógica da aplicação
│   │   ├── components/    # Componentes React reutilizáveis
│   │   │   ├── Chat.tsx   # Componente de chat com IA e prompts salvos
│   │   │   ├── SavedPrompts.tsx # Componente para prompts salvos
│   │   ├── services/      # Serviços de API e integração
│   │   │   ├── chatService.ts # Serviço para API de chat
│   │   └── contexts/      # Contextos React (auth, prompt)
├── backend/               # API FastAPI
│   ├── app/               # Código principal da API
│   │   ├── routers/       # Rotas da API (chat, chat_stream, etc.)
│   │   ├── services/      # Serviços (ai_service, vector_store, etc.)
│   │   └── models/        # Modelos de dados
├── cookbooks/             # Configurações e modelos de IA
├── scripts/               # Scripts utilitários
├── supabase/              # Configurações Supabase e migrações
├── volumes/               # Volumes Docker persistentes
├── docker/                # Arquivos Dockerfile adicionais
└── README.md              # Esta documentação
```

## 🧠 Gerenciamento de Modelos Ollama

### Armazenamento de Modelos
Os modelos Ollama são baixados e armazenados em:
- **No Docker**: Os modelos são baixados dentro do container e persistidos no volume `./volumes/ollama_data` mapeado para `/root/.ollama` no container
- **Localmente**: Os modelos ficam disponíveis entre reinicializações graças à persistência do volume

### Comandos para Gerenciar Modelos
- **Listar modelos instalados**:
  ```bash
  ./scripts/sh/push-ollama-model.sh --list
  ```

- **Baixar modelo específico**:
  ```bash
  ./scripts/sh/push-ollama-model.sh --model llama3:8b
  ```

- **Baixar modelo de chat**:
  ```bash
  ./scripts/sh/push-ollama-model.sh --chat-model
  ```

- **Baixar todos os modelos configurados**:
  ```bash
  ./scripts/sh/push-ollama-model.sh --all
  ```

### Modelos Recomendados
- `gemma3:1b`: Modelo principal leve (815MB) com boa performance
- `phi3:mini`: Alternativa compacta para sistemas com recursos limitados
- `llama3:8b`: Opção mais robusta quando há recursos disponíveis

## 💰 Modelo de Negócio
1. **Free Forever**: Tarefas ilimitadas, IA local, 3 gatilhos, Google Calendar, painel básico, até 5 prompts salvos (R$ 0)
2. **Pro (SaaS)**: IA turbinada com RAG, replanejamento automático, alertas dinâmicos, prompts salvos ilimitados (R$ 29/mês)
3. **Business/Team**: Colaboração, metas por grupo, bibliotecas de prompts compartilhados (R$ 69/mês/usuário)

## 🗺 Roadmap
### Fase 1 - MVP (Concluído)
- [x] Autenticação básica
- [x] CRUD de tarefas
- [x] Interface responsiva
- [x] Integração com IA
- [x] Scripts de automação
- [x] Estrutura de logs
- [x] Funcionalidade de chat com IA
- [x] Prompts salvos

### Fase 2 - Melhorias (Em Andamento)
- [x] Sistema de scripts organizado
- [x] Logs com timestamp
- [x] Tratamento de erros robusto
- [x] Acesso remoto via rede local
- [ ] Sistema de tags
- [ ] Filtros avançados
- [ ] Exportação de dados
- [ ] Melhorias na IA

### Fase 3 - Enterprise
- [ ] SSO/SAML
- [ ] API GraphQL
- [ ] White-label
- [ ] Customização avançada

## 🤝 Contribuindo
1. Fork o projeto
2. Crie sua Feature Branch (`git checkout -b feature/NovaFuncionalidade`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova funcionalidade'`)
4. Push para a Branch (`git push origin feature/NovaFuncionalidade`)
5. Abra um Pull Request

## 📝 Licença
Licenciado sob MIT (veja LICENSE)

---

Desenvolvido com ❤️ pela equipe Orga.AI | Atualizado em maio/2025

