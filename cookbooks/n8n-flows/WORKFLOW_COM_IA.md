# Documentação do Workflow: n8n_email_daily_tasks

## Visão Geral
Este workflow utiliza inteligência artificial (IA) para gerar e enviar emails diários com resumos de tarefas para os usuários da plataforma Orga.AI. O workflow usa o modelo `gemma3:1b` através do serviço Ollama para gerar o conteúdo personalizado dos emails.

## Problemas Corrigidos

### 1. Comunicação com o Modelo Ollama
**Problema:** O workflow estava configurado para usar um endpoint e formato incorretos (`/api/generate` em vez de `/api/chat`) e modelos desatualizados (`phi:latest`, `phi4-mini:latest`).

**Solução:**
- Alterado o endpoint para `/api/chat`
- Atualizado o formato do payload para usar a estrutura correta de mensagens:
  ```json
  {
    "model": "gemma3:1b",
    "messages": [
      {
        "role": "system",
        "content": "Você é um assistente especializado em produtividade..."
      },
      {
        "role": "user",
        "content": "conteúdo do prompt"
      }
    ],
    "stream": false
  }
  ```
- Substituído o modelo para `gemma3:1b`

### 2. Método HTTP no Registro de Logs
**Problema:** O nó "Registrar Log de Email" usava método POST enquanto o endpoint `/api/v1/admin/logs` esperava PUT.

**Solução:**
- Alterado o método para PUT
- O backend foi atualizado para aceitar ambos os métodos (POST e PUT) para compatibilidade

### 3. Extração da Resposta da IA
**Problema:** O nó "Formatar Conteúdo do Email" não extraía corretamente o conteúdo da resposta.

**Solução:**
- Implementada lógica para identificar diferentes formatos de resposta:
  ```javascript
  if (dados.message && dados.message.content) {
    conteudoHTML = dados.message.content;
  } else if (dados.response) {
    conteudoHTML = dados.response;
  } else if (dados.choices && dados.choices.length > 0 && dados.choices[0].message) {
    conteudoHTML = dados.choices[0].message.content;
  }
  ```

### 4. Tarefas sem Associação a Usuário
**Problema:** O nó "Obter Tarefas do Usuário" retornava um array vazio mesmo quando havia tarefas.

**Solução:**
- Associadas todas as tarefas sem user_id ao usuário administrador:
  ```sql
  UPDATE tasks 
  SET user_id = 'e7d51dfe-0f3c-45cd-b388-3b5c62ab1265'
  WHERE user_id IS NULL;
  ```
- Especificado explicitamente o método HTTP GET
- Melhoradas as configurações de timeout e conexão

## Fluxo de Execução

1. **Gatilho Temporal:** Executa diariamente em horário configurado
2. **Obter Usuários:** Consulta todos os usuários ativos do sistema
3. **Filtrar Usuários com Email:** Remove usuários sem email válido
4. **Loop Por Usuário:** Para cada usuário:
   - **Obter Tarefas do Usuário:** Busca tarefas associadas ao usuário
   - **Gerar Prompt para IA:** Cria um prompt contextualizado com as tarefas
   - **Gerar Conteúdo do Email com IA:** Solicita ao Ollama (gemma3:1b) para gerar o conteúdo
   - **Formatar Conteúdo do Email:** Processa a resposta da IA para uso no email
   - **Enviar Email:** Envia o email para o usuário
   - **Registrar Log de Email:** Salva log do envio no sistema

## Como Testar

1. Acesse a interface do n8n em http://localhost:5678
2. Abra o workflow "n8n_email_daily_tasks"
3. Ative o workflow usando o botão no canto superior direito
4. Para teste manual, clique em "Execute Workflow"

## Dependências

- **Backend Orga.AI:** Endpoints funcionais para consulta de usuários e tarefas
- **Serviço Ollama:** Com modelo gemma3:1b carregado
- **Serviço SMTP:** Configurado corretamente para envio de emails

## Considerações Técnicas

- O timeout para requisições ao Ollama foi aumentado para 120 segundos devido ao processamento do modelo
- Os logs são registrados tanto no n8n quanto no sistema Orga.AI
- O workflow foi testado e verificado em 11/05/2025
