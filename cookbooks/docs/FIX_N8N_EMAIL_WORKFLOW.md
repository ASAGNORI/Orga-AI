# N8N Email Workflow Fix

Este arquivo contém instruções específicas para corrigir o workflow n8n de emails diários que está falhando devido a problemas de formatação nas requisições HTTP.

## Passo 1: Acessar o nó "Gerar Conteúdo do Email com IA"

1. Abra a interface do n8n (http://localhost:5678)
2. Acesse o workflow "n8n_email_daily_tasks"
3. Encontre o nó "Gerar Conteúdo do Email com IA"
4. Clique para editá-lo

## Passo 2: Corrigir parâmetros da requisição HTTP

Substitua o corpo da requisição atual pelo seguinte:

```json
{
  "model": "optimized-gemma3",
  "prompt": {{$json["prompt"]}},
  "id": "1a3f83b9-89ba-41fb-9d6f-719cac1016dd",
  "email": "angelo.sagnori@gmail.com",
  "stream": false,
  "force_prompt": true,
  "options": {
    "temperature": 0.1,
    "num_predict": 512
  }
}
```

> Nota: Este é um teste com valores fixos para garantir o funcionamento. Após confirmar que funciona, você poderá substituir os valores estáticos pelos dinâmicos novamente.

## Passo 3: Testar com valores estáticos

1. Execute o workflow com estes valores fixos
2. Verifique se o email é gerado corretamente
3. Confirme nos logs do backend se a requisição está sendo processada sem erros

## Passo 4: (Opcional) Atualizar para valores dinâmicos

Após confirmar o funcionamento, você pode substituir os valores estáticos pelos dinâmicos, mas certifique-se de usar o formato correto:

```json
{
  "model": "optimized-gemma3",
  "prompt": {{$json["prompt"]}},
  "id": "{{$node[\"Debug ID Usuário\"].json[\"id\"]}}",
  "email": "{{$node[\"Debug ID Usuário\"].json[\"email\"]}}",
  "stream": false,
  "force_prompt": true,
  "options": {
    "temperature": 0.1,
    "num_predict": 512
  }
}
```

> Importante: Note que os valores dinâmicos estão entre aspas duplas, o que garante que o n8n os tratará como strings e substituirá os valores antes de enviar a requisição.

## Passo 5: Salvar e ativar o workflow

1. Salve as alterações no nó
2. Ative o workflow novamente
3. Monitore os logs para garantir que está funcionando corretamente

## Diagnóstico

Os logs do backend mostraram que o erro ocorre porque o n8n está enviando literalmente `{{$json.id}}` como texto, em vez de substituir pelo valor real. Este é um problema comum no n8n quando a sintaxe de expressão não é corretamente delimitada como string nos parâmetros JSON.
