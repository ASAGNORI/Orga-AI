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
  - **Prompts Salvos**: Armazenamento e reutilização de prompts frequentes para interações rápidas

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

### Arquitetura de Processamento de Linguagem
O sistema de chat é construído com uma arquitetura sofisticada de múltiplos níveis:

1. **Sistema Híbrido de Processamento**:
   - **Detector de Intenções**: Módulo de classificação rápida que identifica comandos simples e os processa sem acionar o LLM completo
   - **Sistema RAG (Retrieval Augmented Generation)**: 
     - Armazena dados do usuário em um banco de embeddings
     - Utiliza Sentence Transformers para transformar texto em vetores
     - Recupera contexto relevante para enriquecer as interações
   - **Processador LLM**: Utiliza modelos Ollama para processamento de linguagem avançado

2. **Componentes Principais do Sistema de Chat**:
   - **Histórico de Chat**: Sistema de armazenamento e recuperação do histórico de conversas
   - **Gerenciador de Prompts Salvos**: Biblioteca personalizada de prompts frequentes
   - **Processador de Streaming**: Entrega respostas em tempo real via FastAPI EventSource
   - **Sugestão de Atributos**: Extração inteligente de metadados para tarefas

### Implementação Técnica do Sistema de RAG
- **Armazenamento de Vetores**: Implementado com FAISS para busca eficiente
- **Transformadores de Embeddings**: Modelos leves de Sentence Transformers (all-MiniLM-L6-v2)
- **Contexto Personalizado**: Incorporação de dados do usuário para respostas mais relevantes
- **Processamento Assíncrono**: Sistema de filas para processamento eficiente de solicitações
- **Cache Inteligente**: Armazenamento temporário de embeddings frequentes para reduzir latência

### Sistema de Prompts Salvos
- **Interface de Gerenciamento**: Componente React dedicado para gerenciar prompts
- **Armazenamento**: Prompts salvos no banco Supabase com relação ao usuário
- **Categorização**: Sistema de tags para organização dos prompts por temas
- **Acesso Rápido**: Interface de pesquisa e favoritos para prompts frequentes
- **Limites por Plano**: Diferentes capacidades de armazenamento por assinatura (5 no Free, ilimitados no Pro)

### Fluxo de Processamento de Chat
1. Usuário envia mensagem via componente Chat.tsx
2. Backend processa via rotas chat.py ou chat_stream.py
3. Sistema de detecção de intenção verifica se é um comando simples
4. Se necessário, RAG recupera contexto relevante do histórico e dados do usuário
5. LLM processa a solicitação enriquecida com o contexto
6. Resposta é entregue progressivamente via streaming ou completa

## 🛠 Stack Tecnológica

### Frontend
- Next.js 14
- React 18
- TailwindCSS
- Framer Motion
- Supabase Client
- Zustand (Gerenciamento de estado)
- React Hook Form (Formulários)

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
   - `OLLAMA_BASE_URL`: URL do servidor Ollama
   - Credenciais do banco de dados e serviços

### Acessando
- Frontend: http://localhost:3010
- Backend API: http://localhost:8000/api/docs
- Supabase Studio: http://localhost:54323
- N8N: http://localhost:5678
- Open-WebUI (Interface Ollama): http://localhost:3000
- Ollama API: http://localhost:11434

### Acesso via Rede Local
Para acessar a aplicação de outros dispositivos na mesma rede:
1. Use o IP local da máquina host (ex: http://192.168.0.10:3010)
2. As configurações CORS no back-end já estão configuradas para permitir acesso de qualquer origem
3. As URLs da API no front-end são geradas dinamicamente com base no hostname atual

## 📦 Estrutura do Projeto
```
orga-ai-v4/
├── frontend/              # Aplicação Next.js
│   ├── app/               # Componentes, serviços e lógica da aplicação
│   │   ├── components/    # Componentes React reutilizáveis
│   │   │   ├── Chat.tsx   # Componente de chat com IA e prompts salvos
│   │   │   ├── SavedPrompts.tsx # Componente para gerenciar prompts salvos
│   │   │   └── ...        # Outros componentes
│   │   ├── services/      # Serviços de API e integração
│   │   │   ├── chatService.ts # Serviço para comunicação com a API de chat
│   │   │   ├── api.ts     # Configuração base da API
│   │   │   └── ...        # Outros serviços
│   │   └── contexts/      # Contextos React
│   │       ├── AuthContext.tsx # Contexto de autenticação
│   │       ├── PromptContext.tsx # Contexto para gerenciamento de prompts
│   │       └── ...        # Outros contextos
├── backend/               # API FastAPI
│   ├── app/               # Código principal da API
│   │   ├── routers/       # Rotas da API
│   │   │   ├── chat.py    # Rotas para o chat e prompts salvos
│   │   │   ├── chat_stream.py # Rotas para streaming de respostas
│   │   │   ├── auth.py    # Rotas de autenticação
│   │   │   └── ...        # Outras rotas
│   │   ├── services/      # Serviços 
│   │   │   ├── ai_service.py # Serviço principal de IA
│   │   │   ├── vector_store.py # Gerenciamento de vetores para RAG
│   │   │   ├── intent_recognizer.py # Classificação de intenções
│   │   │   ├── stream_service.py # Serviço de streaming de respostas
│   │   │   ├── auth_service.py # Serviço de autenticação
│   │   │   └── ...        # Outros serviços
│   │   └── models/        # Modelos de dados
│   │       ├── chat.py    # Modelo para histórico de chat e prompts salvos
│   │       ├── user.py    # Modelo de usuário
│   │       └── ...        # Outros modelos
├── cookbooks/             # Configurações e modelos de IA
│   ├── Modelfile          # Configuração dos modelos Ollama
│   └── models/            # Modelos de IA pré-configurados
├── scripts/               # Scripts utilitários
│   ├── sh/                # Shell scripts
│   │   ├── start.sh       # Inicia o projeto
│   │   ├── init-ollama.sh # Inicializa o servidor Ollama
│   │   ├── push-ollama-model.sh # Gerencia modelos do Ollama
│   │   └── ...            # Outros scripts shell
│   └── sql/               # Scripts SQL
│       ├── init.sql       # Inicialização do banco
│       ├── fix_chat_history.sql # Correções para tabela de histórico de chat
│       └── ...            # Outros scripts SQL
├── supabase/              # Configurações Supabase e migrações
│   └── migrations/        # Migrações do banco de dados 
├── volumes/               # Volumes Docker persistentes
│   ├── db/                # Dados do PostgreSQL
│   └── ollama_data/       # Modelos e dados do Ollama
├── docker/                # Arquivos Dockerfile adicionais
├── .github/               # Configurações GitHub
├── docker-compose.yml     # Orquestração dos serviços
└── README.md              # Documentação principal
```

## 🧠 Gerenciamento de Modelos Ollama

### Armazenamento e Configuração
Os modelos Ollama são armazenados no volume `./volumes/ollama_data` mapeado para `/root/.ollama` dentro do container Docker. A persistência é garantida entre reinicializações graças ao mapeamento de volumes.

### Scripts de Gerenciamento
- `init-ollama.sh`: Inicializa o servidor Ollama e baixa os modelos padrão configurados
- `push-ollama-model.sh`: Oferece uma interface para gerenciar modelos

### Comandos Úteis
- Listar modelos instalados: `./scripts/sh/push-ollama-model.sh --list`
- Baixar modelo específico: `./scripts/sh/push-ollama-model.sh --model llama3:8b`
- Baixar modelo de chat: `./scripts/sh/push-ollama-model.sh --chat-model`
- Baixar todos os modelos: `./scripts/sh/push-ollama-model.sh --all`

### Modelos Recomendados e Casos de Uso
- `mistral:7b-instruct`: Ideal para tarefas gerais de processamento de linguagem natural, análise de texto e raciocínio lógico
- `neural-chat:latest`: Especializado em interações conversacionais fluidas e naturais, ótimo para o assistente de chat
- `llama3:8b`: Versão equilibrada entre performance e qualidade, indicada para quando recursos de hardware são limitados
- `phi-3:mini`: Modelo compacto para dispositivos de menor capacidade, com boa performance para tarefas simples 
- `mixtral:instruct`: Modelo mais robusto para tarefas complexas quando recursos de hardware permitem

## 🔧 Padrões e Boas Práticas

### Frontend
- **Componentes**: Seguir padrão de componentes funcionais com hooks
- **Estados**: Usar Zustand para estado global, useState para estado local
- **Formulários**: Utilizar React Hook Form para gerenciamento de formulários
- **API**: Usar os serviços em `/services` para comunicações com o backend
- **Estilização**: TailwindCSS para estilos, componentes do shadcn/ui

### Backend
- **Rotas**: Divididas por recurso (chat, auth, tasks, etc.)
- **Serviços**: Lógica de negócio encapsulada em serviços
- **Modelos**: Definição das tabelas e relacionamentos
- **Schemas**: Validação de dados com Pydantic
- **Injeção de Dependências**: Usar sistema de dependências do FastAPI

### Banco de Dados
- **Migrações**: Arquivos SQL em `/supabase/migrations`
- **Correções**: Scripts SQL específicos em `/scripts/sql`
- **Relações**: Definidas explicitamente nos modelos SQLAlchemy

### IA e Modelos
- **Configuração**: Variáveis de ambiente ou arquivos em `/cookbooks`
- **Prompts**: Centralizar templates de prompts para consistência em `backend/app/templates/prompts`
- **RAG**: Implementações em `backend/app/services/ai_service.py` e `vector_store.py`
- **Embeddings**: Utilizar modelos da biblioteca Sentence Transformers
- **Streaming**: Implementar com SSE (Server-Sent Events) via FastAPI

## 💰 Modelo de Negócio

### Planos de Assinatura

1. **Free Forever**
   - Tarefas ilimitadas
   - IA local (via Ollama)
   - Até 3 gatilhos ativos
   - Integração com Google Calendar
   - Painel básico de produtividade
   - Até 5 prompts salvos
   - Preço: R$ 0

2. **Pro (SaaS)**
   - IA turbinada (com RAG, contexto pessoal e histórico)
   - Replanejamento automático
   - Alertas dinâmicos
   - Painel completo
   - Relatórios e insights personalizados
   - Prompts salvos ilimitados
   - Preço: R$ 29/mês

3. **Business/Team**
   - Colaboração entre times
   - Assistente de IA para gestão de equipe
   - Metas por grupo
   - Relatórios integrados
   - Alertas compartilháveis
   - Bibliotecas de prompts compartilhados
   - Preço: R$ 69/mês/usuário

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
- [x] Acesso via rede local

### Fase 2 - Melhorias (Em Andamento)
- [x] Sistema de scripts organizado
- [x] Logs com timestamp
- [x] Tratamento de erros robusto
- [x] Componente de prompts salvos
- [ ] Sistema de tags
- [ ] Filtros avançados
- [ ] Exportação de dados
- [ ] Melhorias na IA

### Fase 3 - Enterprise
- [ ] SSO/SAML
- [ ] API GraphQL
- [ ] White-label
- [ ] Customização avançada

## 📝 Scripts e Utilitários

### Scripts Shell
- `start.sh`: Inicia todos os serviços
- `reinstall.sh`: Reinstala todo o ambiente
- `init-db.sh`: Inicializa o banco de dados
- `wait-for-postgres.sh`: Aguarda PostgreSQL
- `init-gotrue.sh`: Configura autenticação
- `init-ollama.sh`: Inicializa o servidor Ollama
- `push-ollama-model.sh`: Gerencia modelos Ollama
- `health-check.sh`: Verifica saúde dos serviços

### Scripts SQL
- `init.sql`: Inicialização do banco
- `clean.sql`: Limpeza de dados
- `fix-auth.sql`: Correções de autenticação
- `fix_chat_history.sql`: Correções para tabela de histórico de chat
- `fix_timestamps.sql`: Correções para campos de timestamp

## 🤝 Contribuindo

1. Fork o projeto
2. Crie sua Feature Branch (`git checkout -b feature/NovaFuncionalidade`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova funcionalidade'`)
4. Push para a Branch (`git push origin feature/NovaFuncionalidade`)
5. Abra um Pull Request

### Fluxo de trabalho para contribuidores
1. Clone o repositório: `git clone https://github.com/seu-usuario/orga-ai-v4.git`
2. Instale as dependências (frontend e backend)
3. Crie uma branch para sua feature: `git checkout -b feature/nova-funcionalidade`
4. Implemente suas alterações seguindo os padrões de código
5. Execute os testes: `npm test` (frontend) e `pytest` (backend)
6. Faça commit das alterações: `git commit -m "Implemente nova funcionalidade XYZ"`
7. Envie para o GitHub: `git push origin feature/nova-funcionalidade`
8. Crie um Pull Request no GitHub descrevendo suas alterações

## 📝 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](../LICENSE) para detalhes.

---

Desenvolvido com ❤️ pela equipe Orga.AI | Atualizado em maio/2025

