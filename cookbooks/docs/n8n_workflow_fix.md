# N8N Workflow Fix Guide

## Problemas identificados

### 1. Problema com substituição de variáveis
O workflow n8n de envio de emails estava falhando porque:

1. Estava enviando o valor literal `{{$json.id}}` no lugar do ID real do usuário
2. Isso fazia com que o PostgreSQL gerasse um erro ao tentar converter essa string para UUID
3. Como resultado, o backend retornava erro 404 (usuário não encontrado)

### 2. Problema com formato de resposta
Além disso, o backend retornava o conteúdo do email no campo `result`, mas o n8n estava esperando no campo `response`.

## Soluções Implementadas

### 1. Correção do formato de resposta da API
Modificamos o endpoint para retornar o conteúdo em ambos os formatos que o n8n espera:

```python
return JSONResponse(content={
    "response": cleaned,  # Campo que o n8n espera
    "result": cleaned,    # Campo original para compatibilidade
    "status": "ok"
})
```

### 2. Teste bem-sucedido
Nosso teste direto via curl mostrou que quando usamos o ID correto e com a nova estrutura de resposta, o endpoint funciona perfeitamente:

```bash
curl -X POST "http://localhost:8000/ai/generate-email-admin" \
  -H "Authorization: Bearer supersecrettoken" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "optimized-gemma3",
    "prompt": "Gere um email motivacional resumindo minhas tarefas pendentes",
    "id": "1a3f83b9-89ba-41fb-9d6f-719cac1016dd",
    "email": "angelo.sagnori@gmail.com",
    "stream": false,
    "force_prompt": true,
    "options": {
      "temperature": 0.1,
      "num_predict": 512
    }
  }'
```

Este teste retornou uma resposta completa com o conteúdo gerado pela IA.

## Correção do Workflow N8N

Para corrigir o problema no workflow n8n, é necessário ajustar o nó "Gerar Conteúdo do Email com IA" para garantir que os valores das variáveis estão sendo substituídos corretamente:

### Correções no nó HTTP Request

1. Verifique o parâmetro "jsonParameters" - deve estar configurado como `true`
2. No campo "bodyParametersJson", substitua:

```json
{
  "model": "phi",
  "system": "Você é um assistente especializado em produtividade e gestão de tempo que ajuda pessoas a organizarem suas tarefas. Seu tom é motivacional, prático e direto.",
  "prompt": {{$json["prompt"]}},
  "stream": false
}
```

Por:

```json
{
  "model": "optimized-gemma3",
  "prompt": {{$json["prompt"]}},
  "id": "{{$json.id}}",
  "email": "{{$json.email}}",
  "stream": false,
  "force_prompt": true
}
```

### Importante:
- Certifique-se de que o campo usando `{{$json.id}}` está sendo referenciado como string, ou seja, entre aspas: `"{{$json.id}}"`
- Isso garante que n8n substitua o valor corretamente antes de enviar a requisição

## Teste do Workflow

Após fazer as alterações, recomenda-se:

1. Fazer um teste com valores estáticos (hardcoded) para verificar se o endpoint responde corretamente
2. Depois de confirmar o funcionamento, voltar aos valores dinâmicos usando a sintaxe apropriada

## Notas Adicionais

- Os logs do backend mostraram claramente que os valores literais `{{$json.id}}` estão sendo enviados em vez dos valores reais
- O endpoint está funcionando corretamente quando testado diretamente com curl
- O problema está exclusivamente na forma como o n8n está construindo a requisição
