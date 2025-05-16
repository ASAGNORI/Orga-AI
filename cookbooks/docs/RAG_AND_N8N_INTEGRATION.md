# Orga.AI - Documentação do Sistema RAG e Integrações N8N

## Sistema RAG (Retrieval Augmented Generation)

O sistema RAG da Orga.AI melhora as respostas do assistente de IA fornecendo contexto personalizado baseado nos dados do usuário.

### Componentes Principais

1. **VectorStoreService**: Gerencia o armazenamento e recuperação de embeddings vetoriais
   - Localização: `/backend/app/services/vector_store_service.py`
   - Funcionalidade principal: Criar e gerenciar embeddings de tarefas, projetos e histórico de chat

2. **Robustez e Fallback**: O sistema foi melhorado para funcionar mesmo quando o modelo de embeddings não está disponível
   - Implementação de mecanismo de fallback que retorna metadados sem vetorização
   - Inicialização segura de estruturas de dados para evitar erros em tempo de execução

3. **Armazenamento em Cache**: Os embeddings são armazenados em cache para melhorar o desempenho
   - Os embeddings são salvos em disco para persistência entre reinicializações
   - Um TTL (Time-To-Live) é implementado para atualizar automaticamente os embeddings

### Como o RAG Funciona

1. Quando um usuário envia uma mensagem com `use_rag=true`, o sistema:
   - Verifica se os embeddings do usuário estão atualizados
   - Recupera tarefas, projetos e histórico de chat do banco de dados
   - Cria embeddings para esses dados (quando o modelo está disponível)
   - Compara a consulta do usuário com os embeddings para encontrar informações relevantes
   - Enriquece a solicitação à IA com o contexto relevante

2. Mesmo sem o modelo de embedding:
   - O sistema ainda funciona retornando metadados relevantes
   - As estruturas de dados são mantidas para garantir compatibilidade

## Fluxo N8N para Resumos Diários por Email

A Orga.AI implementa um fluxo automatizado para enviar resumos diários de tarefas por email.

### Componentes do Fluxo

1. **Configuração**: O fluxo está definido em `/cookbooks/n8n-flows/n8n_email_daily_tasks.json`
2. **Documentação de Configuração**: Guia detalhado em `/cookbooks/n8n-flows/SETUP_GUIDE.md`
3. **API de Administração**: Endpoints dedicados para suportar o fluxo N8N em `/backend/app/routers/admin.py`

### Funcionalidade do Fluxo

1. **Agendamento**: Executa automaticamente às 7:30 da manhã todos os dias
2. **Coleta de Dados**: Obtém todos os usuários e suas tarefas através da API admin
3. **Processamento**:
   - Filtra tarefas por vencimento (hoje, amanhã, atrasadas)
   - Organiza as tarefas por prioridade
4. **Geração de Conteúdo**: Utiliza o Ollama para criar um email personalizado e motivacional
5. **Envio**: Envia o email para o usuário através do SMTP configurado
6. **Registro**: Cria um log no sistema para cada email enviado

### Logs do Sistema

Para suportar o fluxo N8N e outras integrações, foi criada uma estrutura de logs:

1. **Modelo de Dados**: 
   - Definido em `/backend/app/models/log.py`
   - Armazena informações sobre ações do sistema, usuário associado e detalhes

2. **API para Logs**:
   - Endpoint para criar logs: `POST /api/v1/admin/logs`
   - Requer autenticação como administrador

## Solução de Problemas

### Sistema RAG

- **Erro no modelo de embedding**: 
  - O sistema continua funcionando com capacidade reduzida
  - Logs indicam "Modelo de embedding não disponível. Usando modo fallback sem vetorização"
  - Para resolver, verifique a instalação de `sentence-transformers` e a disponibilidade do modelo

### Fluxo N8N

- **Tokens expirados**: Se a autenticação falhar, gere um novo token com o comando:
  ```
  docker-compose exec backend python -c "import jwt; from datetime import datetime, timedelta; print(jwt.encode({'sub': 'angelo.sagnori@gmail.com', 'email': 'angelo.sagnori@gmail.com', 'is_admin': True, 'exp': datetime.now() + timedelta(days=365)}, 'nSwUBmLT6/XHzoHHlW3l2AjGWO6+xUlqY/LVjngUEUs=', algorithm='HS256'))"
  ```

- **Problemas com envio de email**: Verifique as configurações SMTP em:
  - Arquivo `.env` (SMTP_HOST, SMTP_PORT, etc.)
  - Credenciais no N8N (orga-ai-smtp)

## Próximos Passos

1. **Melhorar o Sistema RAG**: 
   - Implementar suporte para modelos de embedding alternativos
   - Adicionar vetorização assíncrona para não bloquear as respostas

2. **Expandir Integrações N8N**:
   - Adicionar fluxo para integração com WhatsApp
   - Implementar fluxos para importação automática de tarefas de outras plataformas
