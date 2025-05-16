# Solução Final para Problemas no Workflow do N8N - 15/05/2025

## Problemas Identificados e Resolvidos

1. **Tarefas sem User ID:**
   - O endpoint `/api/v1/admin/tasks/user/{user_id}` retornava array vazio (`[]`)
   - **Causa:** Tarefas existiam no banco de dados, mas com `user_id` NULL
   - **Solução:** Atualizar todas as tarefas para terem o user_id do administrador

2. **Método HTTP Incorreto para Logs:**
   - O workflow usava método PUT, mas o backend só aceitava POST
   - **Solução:** Adicionar suporte ao método PUT no backend e incluir campos necessários no modelo

3. **Modelo Ollama Incorreto:**
   - Resolvido anteriormente: Atualização do workflow para usar `gemma3:1b` em vez de modelos antigos
   - **Solução:** Configuração correta do endpoint `/api/chat` e formato de payload adequado

4. **Endpoint de Tarefas não Retornando Dados:**
   - Resolvido: Garantir que o ID do usuário é passado corretamente para o endpoint

## Soluções Implementadas

### 1. Correção para Tarefas sem User ID

As tarefas existiam no sistema, mas não estavam associadas a nenhum usuário:

1. **Diagnóstico:**
   - Verificamos que o endpoint retornava um array vazio `[]`
   - No banco de dados, havia 4 tarefas com `user_id` NULL

2. **Solução:**
   - Executamos um comando SQL para associar todas as tarefas ao usuário administrador:
   ```sql
   UPDATE tasks 
   SET user_id = 'e7d51dfe-0f3c-45cd-b388-3b5c62ab1265'
   WHERE user_id IS NULL;
   ```
   - Resultado: 4 tarefas atualizadas que agora aparecem na resposta da API

### 2. Correção para o Método HTTP para Logs

O workflow usava método PUT, mas o backend só aceitava POST:

1. **Modificação do Backend:**
   - Adicionamos suporte ao método PUT no endpoint `/api/v1/admin/logs`:
   ```python
   @router.post("/logs", status_code=status.HTTP_201_CREATED)
   @router.put("/logs", status_code=status.HTTP_201_CREATED)
   ```
   - Melhoramos a lógica para extrair dados dos logs

2. **Padronização dos Workflows:**
   - O workflow com IA já usava método PUT
   - Atualizamos o workflow sem IA para também usar PUT

### 3. Correção para o Modelo Ollama

O workflow estava usando modelos antigos em vez do modelo configurado no ambiente:

1. **Atualizações do Workflow:**
   - Alterado o endpoint de `/api/generate` para `/api/chat`
   - Atualizado o formato do payload para usar a estrutura de mensagens adequada
   - Configurado para usar o modelo `gemma3:1b` em vez de `phi` ou `phi4-mini`

2. **Processamento de Respostas:**
   - Melhorado o nó "Formatar Conteúdo do Email" para extrair corretamente o conteúdo da resposta

## Status Atual dos Workflows

1. **`n8n_email_daily_tasks.json`** (Workflow com IA)
   - Usa o modelo `gemma3:1b` do Ollama
   - Endpoint `/api/chat` configurado corretamente
   - Método PUT para registrar logs
   - Associação correta de tarefas aos usuários

2. **`n8n_email_diario_sem_ia.json`** (Workflow sem IA)
   - Gera conteúdo sem dependência do Ollama
   - Também usa método PUT para logs
   - Mesmo fluxo de processamento de tarefas
   - Execute para ver detalhes adicionais sobre o ID e as URLs

## Notas Importantes

- Se os containers Docker forem reiniciados, talvez seja necessário atualizar o IP do Ollama no workflow
- Use o script de diagnóstico para verificar o IP atual: `./scripts/sh/troubleshoot-n8n-ollama.sh`
