# Correção da Funcionalidade de Logs nos Workflows N8N - 12/05/2025

## Resumo do Problema

Foi identificado um problema na integração entre os workflows do n8n e o endpoint de logs do backend da aplicação. Os workflows estavam enviando logs com um parâmetro `level` que estava sendo rejeitado pelo backend com o erro:

```
'level' is an invalid keyword argument for SystemLog
```

## Análise da Causa Raiz

A análise revelou dois problemas distintos:

1. **Problema no Workflow**: Nos arquivos de workflow `n8n_email_daily_tasks.json` e `n8n_email_daily_tasks_sem_ia.json`, os nós "Registrar Log de Email" estavam configurados para usar o método PUT no endpoint `/api/v1/admin/logs`, mas não tinham o parâmetro `bodyParametersJson` configurado, resultando em requisições sem corpo.

2. **Incompatibilidade no Modelo**: Embora o modelo `SystemLog` no arquivo `app/models/log.py` tenha um campo `level` definido, a instância do modelo no runtime não estava aceitando este atributo como parâmetro de inicialização. Isso pode acontecer devido a:
   - Versão do SQLAlchemy usada
   - Diferenças entre a definição do modelo e o esquema do banco de dados
   - Problema na inicialização das tabelas

## Solução Implementada

### 1. Correção dos Workflows

Aplicado em 11/05/2025 via script `fix-n8n-workflows.sh`:
- Adicionado o parâmetro `bodyParametersJson` aos nós HTTP dos workflows, enviando os campos necessários incluindo `level`

### 2. Correção do Backend

Aplicado em 12/05/2025:
- **Modificação na Lógica**: Modificado o arquivo `app/routers/admin.py` para verificar dinamicamente se o modelo `SystemLog` suporta o atributo `level` antes de tentar usá-lo na inicialização
- **Migração de Banco de Dados**: Criado script SQL `add_level_to_systemlog.sql` para garantir que o campo exista no banco de dados
- **Script de Aplicação**: Criado script `apply_systemlog_migration.sh` para aplicar a migração e reiniciar o backend

### 3. Ferramentas de Teste

- **Script de Teste**: Atualizado o script `test-n8n-logs.sh` para testar a funcionalidade tanto via PUT quanto via POST

## Como Verificar a Correção

1. Execute o script de migração:
   ```
   ./scripts/sh/apply_systemlog_migration.sh
   ```

2. Execute o script de teste para validar o endpoint:
   ```
   ./scripts/sh/test-n8n-logs.sh
   ```

3. Teste manual via n8n:
   - Acesse o n8n em http://localhost:5678
   - Abra qualquer um dos workflows (`n8n_email_daily_tasks` ou `n8n_email_daily_tasks_sem_ia`)
   - Execute o nó "Registrar Log de Email" isoladamente
   - Verifique a resposta (deve ser 200 OK com uma resposta JSON contendo `success: true`)

4. Verifique os logs no banco de dados:
   ```
   docker exec orga-ai-v4-postgres-1 psql -U postgres -d postgres -c 'SELECT id, message, source, level, created_at FROM system_logs ORDER BY created_at DESC LIMIT 5;'
   ```

## Notas Técnicas

- A solução implementada é resiliente a diferentes versões do modelo `SystemLog`, usando verificação dinâmica de atributos
- A abordagem mantém compatibilidade com versões anteriores do banco de dados, adicionando a coluna apenas se ela não existir
- Os workflows mantêm seus nomes originais, conforme especificado nos requisitos

## Próximos Passos Recomendados

1. Implementar um mecanismo de validação de schemas para garantir compatibilidade entre o n8n e o backend
2. Considerar a adição de testes de integração específicos para as rotas de administração
3. Documentar melhor o formato esperado dos logs para uso futuro

---

Documentação criada por GitHub Copilot em 12/05/2025
