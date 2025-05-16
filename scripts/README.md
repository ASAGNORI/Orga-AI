# 📜 Scripts de Utilitários do Orga.AI

Este diretório contém scripts e utilitários para gerenciar e manter o projeto Orga.AI. Esta documentação fornece detalhes sobre cada script e como usá-los.

## 📁 Estrutura

```
scripts/
├── sh/                # Scripts Shell
│   ├── start.sh       # Inicialização principal
│   ├── health-check.sh # Verificação de saúde
│   ├── ...
├── sql/               # Scripts SQL
│   ├── init.sql       # Inicialização do banco
│   ├── ...
├── utils/             # Utilitários diversos
└── README.md          # Esta documentação
```

## 🚀 Scripts Shell (`sh/`)

### Scripts de Inicialização

#### `start.sh`
Script principal para iniciar todo o projeto Orga.AI.

**Opções:**
- `--frontend-only`: Inicia apenas o frontend
- `--backend-only`: Inicia apenas o backend
- `--no-docker`: Executa sem Docker (modo desenvolvimento)

**Exemplo:**
```bash
./scripts/sh/start.sh --frontend-only
```

#### `health-check.sh`
Verifica a saúde de todos os serviços do projeto.

**Opções:**
- `ollama`: Verifica apenas o serviço Ollama
- `db`: Verifica apenas o banco de dados
- `backend`: Verifica apenas o backend
- `frontend`: Verifica apenas o frontend
- sem parâmetro: Verifica todos os serviços

**Exemplo:**
```bash
./scripts/sh/health-check.sh backend
```

#### `init-ollama.sh`
Inicializa o serviço Ollama e baixa os modelos necessários (llama3:8b).

**Exemplo:**
```bash
./scripts/sh/init-ollama.sh
```

### Scripts de Configuração

#### `init-db.sh`
Inicializa o banco de dados PostgreSQL do projeto.

**Funcionalidades:**
- Cria o esquema do banco
- Configura extensões e permissões
- Aplica scripts de inicialização

**Exemplo:**
```bash
./scripts/sh/init-db.sh
```

#### `init-gotrue.sh`
Configura o serviço de autenticação GoTrue do Supabase.

**Exemplo:**
```bash
./scripts/sh/init-gotrue.sh
```

#### `run-migrations.sh`
Executa todas as migrações SQL do diretório `scripts/sql/` e `supabase/migrations/`.

**Exemplo:**
```bash
./scripts/sh/run-migrations.sh
```

### Scripts de Manutenção

#### `reinstall.sh`
Reinstala completamente o ambiente do projeto.

**Ações:**
- Remove todos os contêineres
- Remove todos os volumes (perda de dados)
- Reconstrói todas as imagens Docker
- Reinicia todos os serviços

**⚠️ Aviso: Este script apaga todos os dados. Use com cautela.**

**Exemplo:**
```bash
./scripts/sh/reinstall.sh
```

#### `docker-build.sh`
Script para construir apenas as imagens Docker do projeto.

**Exemplo:**
```bash
./scripts/sh/docker-build.sh
```

#### `wait-for-postgres.sh`
Utilitário utilizado nos contêineres para aguardar a inicialização do PostgreSQL.

**Parâmetros:**
- `host`: Host do PostgreSQL
- `port`: Porta do PostgreSQL
- `user`: Usuário do PostgreSQL
- `password`: Senha do PostgreSQL
- `database`: Nome do banco de dados

**Exemplo:**
```bash
./scripts/sh/wait-for-postgres.sh db 5432 postgres postgres postgres
```

## 📊 Scripts SQL (`sql/`)

### Scripts de Inicialização

#### `init.sql`
Script principal de criação do esquema do banco de dados.

**Funcionalidades:**
- Cria tabelas principais
- Configura restrições e relacionamentos
- Define funções e triggers

#### `insert.sql`
Insere dados iniciais no banco de dados.

**Conteúdo:**
- Dados de exemplo para desenvolvimento
- Configurações padrão
- Usuário administrativo

### Scripts de Manutenção

#### `fix-auth.sql`
Correções para tabelas de autenticação do Supabase/GoTrue.

#### `fix-uuid.sql`
Correções para campos UUID e conversões de tipo.

#### `disable-migration.sql`
Desativa as migrações automáticas do Supabase para gerenciamento manual.

## 🔧 Utilitários (`utils/`)

#### `create-user.js`
Script JavaScript para criar usuários via API.

**Uso:**
```bash
node scripts/utils/create-user.js user@example.com password123 "Nome Completo"
```

## 🚀 Processos Comuns

### Inicialização Completa do Ambiente
```bash
# Inicia todos os serviços com saída detalhada
./scripts/sh/start.sh

# Verifica se todos os serviços estão saudáveis
./scripts/sh/health-check.sh
```

### Reconstrução do Ambiente
```bash
# Reinicializa completamente o ambiente (remove volumes e contêineres)
./scripts/sh/reinstall.sh
```

### Resolver Problemas de Inicialização
```bash
# Verifica cada componente individualmente
./scripts/sh/health-check.sh ollama
./scripts/sh/health-check.sh db
./scripts/sh/health-check.sh backend
./scripts/sh/health-check.sh frontend
```

## 🛠️ Melhores Práticas

1. **Backup antes de alterar banco de dados**
   ```bash
   docker compose exec db pg_dump -U postgres postgres > backup_$(date +%Y%m%d).sql
   ```

2. **Monitoramento de logs durante inicialização**
   ```bash
   docker compose logs -f [serviço]
   ```

3. **Verificação de status dos serviços**
   ```bash
   docker compose ps
   ```

4. **Reiniciar um serviço específico**
   ```bash
   docker compose restart [serviço]
   ```

## 📝 Desenvolvimento de Scripts

Ao desenvolver novos scripts para o projeto, siga estas diretrizes:

1. **Documentação** - Inclua cabeçalho de documentação em todos os scripts
2. **Tratamento de Erros** - Use `set -e` e funções de validação
3. **Logs** - Inclua logs claros com timestamp
4. **Permissões** - Defina permissões executáveis (`chmod +x`)
5. **Parâmetros** - Valide parâmetros de entrada
6. **Feedback** - Forneça feedback visual do progresso
7. **Idempotência** - Scripts devem ser seguros para execução repetida

---

Para questões ou contribuições, por favor abra um issue ou pull request no repositório.