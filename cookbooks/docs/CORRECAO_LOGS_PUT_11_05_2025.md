# Correção dos Workflows N8N - 11/05/2025

## Problema Solucionado

Após a atualização dos workflows para usar o envio por Gmail, foi identificado um problema persistente nos nós "Registrar Log de Email" de ambos os workflows (`n8n_email_daily_tasks.json` e `n8n_email_daily_tasks_sem_ia.json`). 

O problema estava relacionado à **falta do parâmetro `bodyParametersJson` nos nós HTTP** que faziam requisições PUT para o endpoint de logs do backend.

## Detalhes do Problema

1. Os nós "Registrar Log de Email" estavam configurados corretamente para usar o método PUT:
   ```json
   "requestMethod": "PUT",
   "url": "http://backend:8000/api/v1/admin/logs"
   ```

2. Porém, estavam faltando os parâmetros do corpo da requisição (bodyParametersJson), o que resultava em:
   - Requisições sem corpo sendo enviadas para o backend
   - Backend rejeitando a solicitação devido à falta de dados necessários

3. O endpoint do backend `/api/v1/admin/logs` espera receber:
   - `level`: nível do log (info, error, etc.)
   - `source`: origem do log
   - `message`: mensagem descritiva
   - `details`: objeto com informações adicionais

## Solução Implementada

Foi criado e executado um script `fix-n8n-workflows.sh` que adicionou o parâmetro `bodyParametersJson` aos nós "Registrar Log de Email" em ambos os workflows:

### Para o workflow com IA (n8n_email_daily_tasks.json):
```json
"bodyParametersJson": "= { 
  \"level\": \"info\", 
  \"source\": \"n8n_workflow\", 
  \"message\": `Email enviado para ${$json[\"email\"]} via Gmail`, 
  \"details\": { 
    \"workflow\": \"n8n_email_daily_tasks\", 
    \"user_id\": $json[\"id\"], 
    \"task_count\": $json[\"totalTarefas\"], 
    \"timestamp\": new Date().toISOString() 
  } 
}"
```

### Para o workflow sem IA (n8n_email_daily_tasks_sem_ia.json):
```json
"bodyParametersJson": "= { 
  \"level\": \"info\", 
  \"source\": \"n8n_workflow\", 
  \"message\": `Email enviado para ${$json[\"email\"]} via Gmail`, 
  \"details\": { 
    \"workflow\": \"n8n_email_daily_tasks_sem_ia\", 
    \"user_id\": $json[\"id\"], 
    \"task_count\": $json[\"totalTarefas\"], 
    \"timestamp\": new Date().toISOString() 
  } 
}"
```

## Como Testar a Correção

1. Acesse a interface do n8n em http://localhost:5678
2. Abra cada workflow:
   - `n8n_email_daily_tasks`
   - `n8n_email_daily_tasks_sem_ia`
3. Verifique se o nó "Registrar Log de Email" tem o parâmetro "Body Parameters" configurado
4. Execute manualmente os workflows para testar
5. Verifique os logs no backend para confirmar que os registros foram salvos

## Script de Correção

Um script foi criado em `/scripts/sh/fix-n8n-workflows.sh` para automatizar esta correção. O script:

1. Cria um backup dos arquivos originais
2. Usa o jq para adicionar o parâmetro bodyParametersJson
3. Salva as alterações nos arquivos originais
4. Exibe instruções para testar as alterações

Os backups dos arquivos originais foram salvos em `/cookbooks/n8n-flows/backup/bodyParams_fix_TIMESTAMP/`.

## Conclusão

Esta correção deve resolver o problema de comunicação entre os workflows n8n e o endpoint de logs do backend, permitindo que os registros de envio de email sejam salvos corretamente no sistema.
