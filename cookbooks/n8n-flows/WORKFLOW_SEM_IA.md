# Documentação do Workflow: n8n_email_diario_sem_ia

## Visão Geral
Este workflow é uma versão alternativa do sistema de envio de emails diários, que funciona sem depender do serviço de inteligência artificial (Ollama). Ele envia emails com resumo de tarefas para os usuários usando conteúdo estático pré-definido.

## Problemas Corrigidos

### 1. Método HTTP no Registro de Logs
**Problema:** O nó "Registrar Log de Email" usava método POST enquanto o endpoint `/api/v1/admin/logs` esperava PUT.

**Solução:**
- Alterado o método para PUT
- O backend foi atualizado para aceitar ambos os métodos (POST e PUT) para compatibilidade

### 2. Tarefas sem Associação a Usuário
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

### 3. Formatação do Conteúdo do Email
**Problema:** A formatação HTML dos emails não estava correta em alguns casos.

**Solução:**
- Implementado um template HTML fixo com slots para dados dinâmicos
- Melhorado o tratamento de casos onde não existem tarefas para o usuário

## Fluxo de Execução

1. **Gatilho Temporal:** Executa diariamente em horário configurado
2. **Obter Usuários:** Consulta todos os usuários ativos do sistema
3. **Filtrar Usuários com Email:** Remove usuários sem email válido
4. **Loop Por Usuário:** Para cada usuário:
   - **Obter Tarefas do Usuário:** Busca tarefas associadas ao usuário
   - **Preparar Conteúdo do Email:** Gera uma tabela HTML com as tarefas do usuário
   - **Enviar Email:** Envia o email para o usuário
   - **Registrar Log de Email:** Salva log do envio no sistema

## Como Testar

1. Acesse a interface do n8n em http://localhost:5678
2. Abra o workflow "n8n_email_diario_sem_ia"
3. Ative o workflow usando o botão no canto superior direito
4. Para teste manual, clique em "Execute Workflow"

## Dependências

- **Backend Orga.AI:** Endpoints funcionais para consulta de usuários e tarefas
- **Serviço SMTP:** Configurado corretamente para envio de emails

## Considerações Técnicas

- Este workflow foi desenvolvido como alternativa para momentos em que o serviço Ollama não estiver disponível
- A formatação HTML é feita diretamente no workflow, sem dependência de serviços externos
- Os logs são registrados tanto no n8n quanto no sistema Orga.AI
- O workflow foi testado e verificado em 11/05/2025

## Diferenças em Relação ao Workflow Principal

1. **Sem dependência do Ollama:** Este workflow não requer o serviço de IA
2. **Conteúdo estático:** Os emails seguem um formato pré-definido sem personalização por IA
3. **Menor tempo de execução:** Por não precisar esperar pela geração de conteúdo via IA, este workflow é mais rápido
4. **Maior previsibilidade:** O conteúdo dos emails é sempre o mesmo formato, sem variações da IA
