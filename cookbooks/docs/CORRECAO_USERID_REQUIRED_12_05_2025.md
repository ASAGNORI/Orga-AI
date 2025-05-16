# Correção do Campo Obrigatório user_id nos Workflows N8N - 12/05/2025

## Resumo do Problema

Após corrigir o formato JSON nos workflows do n8n, identificamos um novo erro de validação ao enviar logs para o backend:

```
{
  "errorMessage": "Your request is invalid or could not be processed by the service",
  "errorDetails": {
    "rawErrorMessage": [
      "422 - {\"code\":\"VALIDATION_ERROR\",\"message\":\"Validation error\",\"details\":[{\"field\":\"\",\"message\":\"Field required\"}]}"
    ],
    "httpCode": "422"
  },
  "n8nDetails": {
    "nodeName": "Registrar Log de Email",
    "nodeType": "n8n-nodes-base.httpRequest",
    "nodeVersion": 1
  }
}
```

Este erro indicava um erro de validação 422 com a mensagem "Field required", significando que o backend estava esperando campos obrigatórios que não estavam sendo enviados pelo n8n.

## Causa Raiz

Analisando o código do backend, identificamos que o campo `user_id` é esperado como campo obrigatório pelo endpoint `/api/v1/admin/logs`, mas não estava sendo incluído na requisição dos workflows.

O código do backend tenta extrair o `user_id` das seguintes formas:
1. De `log_data.details.user_id` se existir
2. De `log_data.user_id` se existir
3. Caso contrário, será `null`

Porém, a lógica do backend requer um `user_id` válido para registrar o log corretamente.

## Solução Implementada

1. **Adição do campo `user_id`**: Adicionamos explicitamente o campo `user_id` no corpo da requisição HTTP de ambos os workflows.

2. **Inclusão do campo no objeto `details`**: Também adicionamos o campo dentro do objeto `details` para maior compatibilidade.

3. **Referência dinâmica aos dados do usuário**: Utilizamos variáveis do n8n para referenciar diretamente os dados do usuário processado:
   ```json
   "user_id": "{{$node[\"Processar Dados do Usuário\"].json[\"id\"]}}",
   ```

4. **Adição de outros dados contextuais**: Adicionamos também o campo `task_count` para enriquecer os logs com informações sobre a quantidade de tarefas do usuário.

## Correções por Arquivo

### 1. n8n_email_daily_tasks.json

```json
"body": {
  "level": "info",
  "source": "n8n_workflow",
  "message": "Email enviado via Gmail",
  "user_id": "{{$node[\"Processar Dados do Usuário\"].json[\"id\"]}}",
  "details": {
    "workflow": "n8n_email_daily_tasks",
    "user_id": "{{$node[\"Processar Dados do Usuário\"].json[\"id\"]}}",
    "task_count": "{{$node[\"Processar Dados do Usuário\"].json[\"totalTarefas\"]}}",
    "timestamp": "{{$now.toISOString()}}"
  }
}
```

### 2. n8n_email_daily_tasks_sem_ia.json

```json
"body": {
  "level": "info",
  "source": "n8n_workflow",
  "message": "Email enviado via Gmail",
  "user_id": "{{$node[\"Processar Dados do Usuário\"].json[\"id\"]}}",
  "details": {
    "workflow": "n8n_email_daily_tasks_sem_ia",
    "user_id": "{{$node[\"Processar Dados do Usuário\"].json[\"id\"]}}",
    "task_count": "{{$node[\"Processar Dados do Usuário\"].json[\"totalTarefas\"]}}",
    "timestamp": "{{$now.toISOString()}}"
  }
}
```

## Recomendações para o Futuro

1. **Validação de Schemas**: Implementar validação de schemas (como JSON Schema) no n8n e no backend para garantir que os dados enviados atendam às expectativas do servidor.

2. **Documentação de APIs**: Manter uma documentação clara dos endpoints da API, especificando quais campos são obrigatórios e quais são opcionais.

3. **Testes de Integração**: Desenvolver testes de integração específicos para validar a comunicação entre n8n e backend.

4. **Mensagens de Erro Claras**: Configurar o backend para retornar mensagens de erro mais detalhadas indicando exatamente quais campos estão faltando.

## Verificação da Correção

Para verificar se a correção foi bem-sucedida, execute qualquer um dos workflows no n8n e verifique se o nó "Registrar Log de Email" é executado sem erros de validação.

---

*Documentação criada em 12 de maio de 2025*
