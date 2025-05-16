# Correção da Formatação JSON nos Workflows N8N - 12/05/2025

## Resumo do Problema

Foi identificado um problema específico nos workflows n8n que impedia o registro correto de logs. O erro reportado foi:

```
Body Parameters: "message": 'Email enviado para ${$json["email"]} via Gmail',  Unexpected token ''', ..."message": 'Email env"... is not valid JSON
```

Este problema estava ocorrendo devido a dois fatores principais:

1. **Formato Incorreto de JSON**: A utilização de backticks (`) e aspas simples (') na expressão JavaScript que define o corpo da requisição.
2. **Uso de Interpolação de Variáveis**: O uso de expressões como `${$json["email"]}` que são válidas em JavaScript, mas não no formato JSON esperado pelo n8n.

## Solução Implementada

### 1. Alteração do Formato de Parâmetros do Body

Foi modificada a abordagem de definição do corpo da requisição, substituindo:

- De: `bodyParametersJson` (que aceita expressões JavaScript)
- Para: `bodyContentType: "json"` + `body` (que aceita apenas JSON válido)

### 2. Simplificação da Mensagem

Para evitar os problemas com interpolação de variáveis, simplificamos a mensagem para um texto estático e usamos a notação padrão do n8n para inserir valores dinâmicos:

```json
{
  "bodyContentType": "json",
  "jsonParameters": false,
  "body": {
    "level": "info",
    "source": "n8n_workflow",
    "message": "Email enviado via Gmail",
    "details": {
      "workflow": "n8n_email_daily_tasks",
      "timestamp": "{{$now.toISOString()}}"
    }
  }
}
```

### 3. Aplicação da Migração do SystemLog

Foi verificado que a tabela `system_logs` já possuía o campo `level`, o que resolveu o segundo problema: `'level' is an invalid keyword argument for SystemLog`.

## Scripts Criados/Modificados

1. **fix-n8n-content-type.sh**
   - Script que corrige automaticamente o formato dos parâmetros JSON nos workflows
   - Cria backups dos arquivos originais para referência

2. **apply_systemlog_migration.sh**
   - Verifica e aplica a migração para garantir a existência do campo `level` na tabela

3. **test-n8n-workflows.sh**
   - Permite testar os workflows diretamente via API do n8n
   - Verifica se os logs estão sendo registrados corretamente

## Solução para Uso Futuro do N8N

Quando trabalhar com requisições HTTP no n8n que enviam JSON:

1. Use `bodyContentType: "json"` em vez de `jsonParameters: true` + `bodyParametersJson`
2. Defina o corpo da requisição no campo `body` como um objeto JSON puro
3. Para valores dinâmicos, use a sintaxe de Mustache: `{{$node["NomeDoNó"].json["campo"]}}`
4. Para funções como timestamp atual, use: `{{$now.toISOString()}}`

## Verificação da Correção

1. Os workflows agora funcionam sem erros de formatação JSON
2. Os logs são registrados corretamente no banco de dados com os campos apropriados
3. A integração entre n8n e o backend está funcionando conforme esperado

---

*Documentação criada em 12 de maio de 2025*
