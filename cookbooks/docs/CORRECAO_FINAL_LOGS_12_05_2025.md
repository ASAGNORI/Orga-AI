# Documentação Atualizada: Configuração do Registro de Logs nos Workflows N8N - 12/05/2025

## Configuração Final dos Nós de Log

Após diversas iterações e correções, chegamos à configuração correta dos nós "Registrar Log de Email" que funciona em ambos os workflows. Esta documentação registra a implementação final bem-sucedida.

### Configuração Comum

Ambos os workflows compartilham as seguintes configurações base para o nó HTTP:

```json
{
  "authentication": "headerAuth",
  "requestMethod": "PUT",
  "url": "http://backend:8000/api/v1/admin/logs",
  "allowUnauthorizedCerts": true,
  "jsonParameters": true,
  "options": {
    "bodyContentType": "json"
  }
}
```

### Estrutura do Corpo da Requisição

O corpo da requisição (bodyParametersJson) segue este formato em ambos os workflows:

```javascript
={
  "level": "info",
  "source": "n8n_workflow",
  "message": "Email enviado para {{ $('NomeDoNó').item.json.email }} via Gmail",
  "user_id": "{{ $('NomeDoNó').item.json.id }}",
  "details": {
    "workflow": "nome_do_workflow",
    "user_id": "{{ $('NomeDoNó').item.json.id }}",
    "task_count": {{ $('NomeDoNó').item.json.totalTarefas }},
    "task_stats": {
      "total": {{ $('NomeDoNó').item.json.totalTarefas }},
      "completed": {{ $('NomeDoNó').item.json.tarefasConcluidas }}
    },
    "timestamp": "{{ new Date().toISOString() }}"
  }
}
```

### Diferenças Entre os Workflows

1. **Workflow com IA (n8n_email_daily_tasks.json)**:
   - Referencia o nó "Processar Dados do Usuário" para obter dados
   - Nome do workflow nos detalhes: "n8n_email_daily_tasks"

2. **Workflow sem IA (n8n_email_daily_tasks_sem_ia.json)**:
   - Referencia o nó "Gerar Conteúdo do Email" para obter dados
   - Nome do workflow nos detalhes: "n8n_email_daily_tasks_sem_ia"

## Campos e Sua Importância

1. **Campos Obrigatórios**:
   - `level`: nível do log (info, warning, error)
   - `source`: identifica a origem do log
   - `message`: descrição da ação realizada
   - `user_id`: ID do usuário associado ao log (campo obrigatório)

2. **Campos de Detalhes**:
   - `workflow`: identifica qual workflow gerou o log
   - `task_count`: número total de tarefas do usuário
   - `task_stats`: estatísticas detalhadas das tarefas
   - `timestamp`: momento exato do registro

## Sintaxe do N8N

A configuração usa a sintaxe correta do n8n para expressões:
- `{{ $('NomeDoNó').item.json.campo }}` para strings
- `{{ $('NomeDoNó').item.json.campo }}` sem aspas para números
- `{{ new Date().toISOString() }}` para timestamps

## Considerações Importantes

1. **Parâmetros JSON**:
   - `jsonParameters` deve ser `true`
   - O campo `bodyParametersJson` deve começar com `=`
   - As expressões do n8n devem usar a sintaxe `{{ ... }}`

2. **Campos Numéricos**:
   - Números não devem estar entre aspas no JSON
   - Exemplo: `"task_count": {{ $('NomeDoNó').item.json.totalTarefas }}`

3. **Campos de String**:
   - Strings devem estar entre aspas no JSON
   - Exemplo: `"user_id": "{{ $('NomeDoNó').item.json.id }}"`

## Validação

Para verificar se o log está funcionando corretamente:

1. Execute o nó "Registrar Log de Email" isoladamente
2. Verifique a resposta do backend (deve ser 200 OK)
3. Consulte o banco de dados para confirmar o registro:
   ```sql
   SELECT id, level, source, message, user_id, created_at 
   FROM system_logs 
   WHERE source = 'n8n_workflow' 
   ORDER BY created_at DESC 
   LIMIT 1;
   ```

## Resolução de Problemas

Se encontrar erros, verifique:
1. Se todos os campos obrigatórios estão presentes
2. Se a sintaxe das expressões do n8n está correta
3. Se os nós referenciados existem e geram os campos esperados
4. Se os tipos de dados estão corretos (strings entre aspas, números sem aspas)

---

*Última atualização: 12 de maio de 2025*
