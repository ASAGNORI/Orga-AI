# Guia de Configuração do N8N para Integração com Orga.AI

## Visão Geral
Este documento descreve como configurar o N8N para enviar automaticamente resumos diários de tarefas por e-mail para os usuários do Orga.AI.

## Pré-requisitos
- N8N rodando em http://localhost:5678
- Backend Orga.AI rodando em http://localhost:8000
- Token de autenticação para acesso à API de administração

## Passo 1: Configurar Credenciais de Autenticação

1. Acesse o N8N em http://localhost:5678
2. Faça login com as credenciais:
   - Usuário: admin
   - Senha: admin123
3. No menu lateral, vá para "Credentials"
4. Clique em "+ Add Credential"
5. Selecione "Header Auth" (uma das opções disponíveis)
6. Configure:
   - Nome: admin-api-key
   - Nome do cabeçalho: Authorization
   - Valor do cabeçalho: `Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhbmdlbG8uc2Fnbm9yaUBnbWFpbC5jb20iLCJlbWFpbCI6ImFuZ2Vsby5zYWdub3JpQGdtYWlsLmNvbSIsImlzX2FkbWluIjp0cnVlLCJleHAiOjE3Nzg0MjI4MDZ9.8Pzu17w_JT2C35WCPvYIKHIow7BcsGAUYm3fBv0Ebf4`
   - Este token é válido por um ano (até maio de 2026)
   - IMPORTANTE: Certifique-se de incluir a palavra "Bearer " (com espaço depois) antes do token JWT
7. Clique em "Save"

## Passo 2: Configurar Credenciais SMTP

1. No menu lateral, vá para "Credentials"
2. Clique em "+ Add Credential"
3. Selecione "SMTP"
4. Configure:
   - Nome: orga-ai-smtp
   - Host: smtp.gmail.com
   - Porta: 587
   - Usuário: angelo.sagnori@gmail.com
   - Senha: xxxx xxxx xxxx xxxx
   - SSL/TLS: STARTTLS
5. Clique em "Save"

## Passo 3: Importar o Workflow

1. No menu lateral, vá para "Workflows"
2. Clique em "+ New"
3. Clique no menu no canto superior direito (três pontos)
4. Selecione "Import from File"
5. Selecione o arquivo de workflow apropriado para seu ambiente:  - **Se você tem o modelo Mistral instalado**: `/Users/angelosagnori/Downloads/orga-ai-v4/cookbooks/n8n-flows/n8n_email_daily_tasks_header_auth.json`
  - **Se você tem o modelo Phi instalado**: `/Users/angelosagnori/Downloads/orga-ai-v4/cookbooks/n8n-flows/n8n_email_daily_tasks_phi.json`
6. Após importar, verifique se as credenciais estão corretamente associadas aos nós:
   - "Obter Lista de Usuários", "Obter Tarefas do Usuário" e "Registrar Log de Email": admin-api-key
   - "Enviar Email": orga-ai-smtp
   
   **NOTA**: Estes arquivos já estão configurados para usar o tipo de credencial `headerAuth`. Se você estiver tendo problemas de autenticação, verifique se está usando o arquivo correto e se configurou a credencial Header Auth conforme descrito no Passo 1.

## Passo 4: Verificar e Ativar o Workflow

1. Verifique se o agendamento está configurado para as 7:30 da manhã
2. Clique em "Execute Workflow" para testar a execução
3. Verifique se o email é enviado corretamente
4. Ative o workflow clicando no botão "Active"

## Observações

- O workflow está configurado para buscar as tarefas de todos os usuários no sistema
- Para cada usuário, ele filtra as tarefas de hoje, amanhã e atrasadas
- Utiliza o Ollama para gerar um email personalizado
- Registra um log no sistema após o envio de cada email
- Se houver erros, verifique os logs no N8N e no backend

## Correção de URLs no Workflow

⚠️ **IMPORTANTE**: O arquivo de workflow pode conter URLs incorretas. Após importar o workflow, certifique-se de verificar e corrigir as seguintes URLs:

1. **Nó "Obter Lista de Usuários"**: Deve ser `http://backend:8000/api/v1/admin/users`
2. **Nó "Obter Tarefas do Usuário"**: Deve ser `http://backend:8000/api/v1/admin/tasks/user/{{$json["id"]}}`
3. **Nó "Registrar Log de Email"**: Deve ser `http://backend:8000/api/v1/admin/logs`
4. **Nó "Gerar Conteúdo do Email com IA"**: Verifique as opções abaixo para o correto endpoint do Ollama

### Configuração de URLs baseada no ambiente

Dependendo de como você está executando o N8N, use estas configurações:

**Se N8N está rodando dentro do Docker (padrão)**:
- Use `http://backend:8000` para acessar o backend
- Use `http://ollama:11434/api/chat` para acessar o Ollama diretamente via IP (recomendado)
- Alternativas para o Ollama:
  - `http://ollama:11434/api/chat` (se resolução DNS estiver funcionando)
  - `http://host.docker.internal:11434/api/chat` (para acessar Ollama no host)
  - `http://localhost:11434/api/chat` (se estiver na mesma rede com host_network)
  
⚠️ **IMPORTANTE**: Se houver problemas de conexão com o Ollama, execute o script de diagnóstico:
```bash
./scripts/sh/troubleshoot-n8n-ollama.sh
```
Este script fornecerá o IP correto do container Ollama e verificará a conectividade.

### Configuração do Modelo Ollama

No nó "Gerar Conteúdo do Email com IA", certifique-se de selecionar o modelo correto. Os modelos disponíveis são:
- `gemma3:1b` (modelo leve e recomendado - 815MB)
- `phi3:mini` (alternativa de backup)

**Configuração correta do body da requisição (importante)**:
```json
{
  "model": "gemma3:1b",
  "messages": [
    {
      "role": "system",
      "content": "Você é um assistente especializado em produtividade e gestão de tempo que ajuda pessoas a organizarem suas tarefas. Seu tom é motivacional, prático e direto."
    },
    {
      "role": "user",
      "content": {{$json["prompt"]}}
    }
  ]
}
```

### Solução de problemas de conexão com o Ollama

Se você estiver recebendo erros de conexão como `ECONNREFUSED ::1:11434`:

1. Certifique-se que o n8n está na mesma rede Docker que o Ollama:
   - Execute `docker network inspect orga-ai-v4_app-network` para verificar
   
2. Teste a conexão com o comando:
   ```bash
   docker-compose exec n8n ping -c 3 ollama
   ```

3. Verifique se o hostname está sendo resolvido corretamente:
   - Se ping funciona, mas HTTP falha, tente usar o IP direto: `http://ollama:11434/api/chat`
   
4. Na interface do n8n, edite o nó e configure a opção "Use different URL for HTTP request" e coloque o endereço IP direto

**Se N8N está rodando fora do Docker**:
- Use `http://localhost:8000` para acessar o backend
- Use `http://localhost:11434/api/chat` para acessar o Ollama

**Se N8N está rodando em outra máquina**:
- Use `http://IP_DO_SERVIDOR:8000` para acessar o backend
- Use `http://IP_DO_SERVIDOR:11434/api/chat` para acessar o Ollama

### Verificando se o Ollama está acessível

Se você continuar tendo problemas com o nó "Gerar Conteúdo do Email com IA", verifique se o Ollama está acessível:

1. Execute este comando para verificar se o Ollama está respondendo:
   ```bash
   curl http://localhost:11434/api/tags
   ```

2. Se estiver no Docker, teste dentro do container n8n:
   ```bash
   docker-compose exec n8n curl ollama:11434/api/tags
   ```

3. Certifique-se de que a porta 11434 do Ollama está exposta corretamente no Docker.

## Solução de Problemas

- Se o token expirar, gere um novo com o comando:
  ```
  docker-compose exec backend python -c "import jwt; from datetime import datetime, timedelta; print(jwt.encode({'sub': 'angelo.sagnori@gmail.com', 'email': 'angelo.sagnori@gmail.com', 'is_admin': True, 'exp': datetime.now() + timedelta(days=365)}, 'nSwUBmLT6/XHzoHHlW3l2AjGWO6+xUlqY/LVjngUEUs=', algorithm='HS256'))"
  ```
- Se o webhook não estiver funcionando, verifique se a URL está acessível do N8N para o backend
