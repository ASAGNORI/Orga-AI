# Índice de Documentação dos Workflows N8N

Este arquivo serve como índice para toda a documentação relacionada aos workflows do N8N no projeto Orga.AI.

## Documentos Principais

| Documento | Descrição |
|-----------|-----------|
| [WORKFLOW_COM_IA.md](./WORKFLOW_COM_IA.md) | Documentação completa do workflow que utiliza o Ollama (gemma3:1b) para gerar conteúdo de emails |
| [WORKFLOW_SEM_IA.md](./WORKFLOW_SEM_IA.md) | Documentação completa do workflow alternativo que não depende do serviço de IA |
| [REGISTRO_CONSOLIDACAO_11_05_2025.md](./REGISTRO_CONSOLIDACAO_11_05_2025.md) | Registro do processo de consolidação da documentação |
| [SETUP_GUIDE.md](./SETUP_GUIDE.md) | Guia de configuração do ambiente N8N |
| [CORRECAO_LOGS_PUT_11_05_2025.md](./CORRECAO_LOGS_PUT_11_05_2025.md) | Detalhes sobre a correção do parâmetro bodyParametersJson nos nós de logs |
| [CORRECAO_SYSTEMLOG_12_05_2025.md](./CORRECAO_SYSTEMLOG_12_05_2025.md) | Correção da compatibilidade do modelo SystemLog com os parâmetros enviados pelo n8n |
| [CORRECAO_JSON_FORMAT_12_05_2025.md](./CORRECAO_JSON_FORMAT_12_05_2025.md) | Detalhes sobre a correção do formato JSON nos workflows n8n |
| [CORRECAO_USERID_REQUIRED_12_05_2025.md](./CORRECAO_USERID_REQUIRED_12_05_2025.md) | Detalhes sobre a adição do campo obrigatório user_id nos workflows n8n |
| [CORRECAO_FINAL_LOGS_12_05_2025.md](./CORRECAO_FINAL_LOGS_12_05_2025.md) | Documentação final da implementação correta do registro de logs nos workflows n8n |

## Arquivos de Workflow

| Arquivo | Descrição |
|---------|-----------|
| [n8n_email_daily_tasks.json](./n8n_email_daily_tasks.json) | Workflow que utiliza IA para gerar conteúdo de emails |
| [n8n_email_diario_sem_ia.json](./n8n_email_diario_sem_ia.json) | Workflow alternativo sem dependência de IA |
| [n8n_scrape_summarize_webpages.json](./n8n_scrape_summarize_webpages.json) | Workflow auxiliar para scraping de páginas web |

## Scripts

| Arquivo | Descrição |
|---------|-----------|
| [setup_n8n.sh](./setup_n8n.sh) | Script de configuração inicial do N8N |

## Documentação Histórica

A documentação anterior foi consolidada e movida para o diretório [deprecated_docs_11_05_2025/](./deprecated_docs_11_05_2025/) para referência histórica.

---

*Última atualização: 12 de maio de 2025*
