# Guia de Correção do Workflow N8N para Envio de Emails

## Problema Identificado

O workflow n8n `n8n_email_daily_tasks.json` não está enviando emails corretamente porque:

1. O nó HTTP Request usa `bodyParameters` em vez de `jsonParameters` ou `jsonBody`, o que pode causar problemas na formatação do JSON enviado para o backend
2. As variáveis como `{{ $json.id }}` podem não estar sendo corretamente substituídas

## Solução

### 1. Substituir o nó HTTP Request atual

Substitua o nó HTTP Request do workflow por uma versão que use `jsonBody` diretamente. Aqui estão os passos:

1. Abra o workflow `n8n_email_daily_tasks` no n8n
2. Selecione o nó "HTTP Request" que faz a chamada para `/ai/generate-email-admin`
3. Substitua sua configuração por:

```
{
  "parameters": {
    "method": "POST",
    "url": "http://backend:8000/ai/generate-email-admin",
    "authentication": "headerAuth",
    "sendHeaders": true,
    "headerParameters": {
      "parameters": [
        {
          "name": "Content-Type",
          "value": "application/json"
        }
      ]
    },
    "sendBody": true,
    "specifyBody": "json",
    "jsonBody": "={ \
      \"model\": \"optimized-gemma3\", \
      \"prompt\": $json.prompt, \
      \"id\": $json.id, \
      \"email\": $json.email, \
      \"stream\": false, \
      \"force_prompt\": true, \
      \"tarefasHoje\": $json.tarefasHoje || [], \
      \"tarefasAmanha\": $json.tarefasAmanha || [], \
      \"tarefasAtrasadas\": $json.tarefasAtrasadas || [], \
      \"totalTarefas\": $json.totalTarefas || 0, \
      \"tarefasConcluidas\": $json.tarefasConcluidas || 0 \
    }",
    "options": {
      "response": {
        "response": {
          "neverError": true
        }
      },
      "timeout": 600000
    }
  }
}
```

### 2. Atualizar o nó "Formatar Conteúdo do Email"

Verifique se o nó "Formatar Conteúdo do Email" está procurando o campo `response` na resposta da API:

```javascript
// Process the response from backend API
const data = $json;
console.log('Raw IA response:', JSON.stringify(data));

// Extract response from API format
let emailContent = '';

try {
  if (typeof data === 'object') {
    // Handle backend API format (should have response field now)
    if (data.response) {
      emailContent = data.response;
      console.log('✅ Extraído conteúdo do campo response');
    }
    // Fall back to result field
    else if (data.result) {
      emailContent = data.result;
      console.log('✅ Extraído conteúdo do campo result');
    }
    // ... outros formatos
  }
  
  // ... resto do código
}
```

## Workflow de Teste Simplificado

Foi criado um workflow de teste simplificado (`n8n_email_daily_tasks_json_fix.json`) que você pode importar para testar a solução. Este workflow:

1. Usa valores fixos para teste
2. Usa `jsonBody` em vez de `bodyParameters`
3. Exibe o resultado em uma notificação para fácil verificação

## Testando Manualmente

Se você quiser testar o endpoint manualmente, você pode usar este comando curl:

```bash
curl -X POST "http://backend:8000/ai/generate-email-admin" \
  -H "Authorization: Bearer supersecrettoken" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "optimized-gemma3",
    "prompt": "Gere um email curto motivacional resumindo minhas tarefas pendentes",
    "id": "1a3f83b9-89ba-41fb-9d6f-719cac1016dd",
    "email": "angelo.sagnori@gmail.com",
    "stream": false,
    "force_prompt": true
  }'
```

## Importante

Certifique-se de que:

1. O backend esteja rodando e acessível em http://backend:8000 dentro da rede do Docker
2. Os tokens de autorização estejam configurados corretamente
3. Os IDs de usuário sejam válidos no banco de dados

Após realizar estas alterações, o workflow n8n deve funcionar corretamente e enviar emails com o conteúdo gerado pela IA.
