# Solução para o erro de conexão entre N8N e Ollama

## Problema Encontrado
Ao tentar executar o workflow N8N com o nó "Gerar Conteúdo do Email com IA", ocorre o seguinte erro:
```json
{
  "errorMessage": "The service refused the connection - perhaps it is offline",
  "errorDetails": {
    "rawErrorMessage": [
      "connect ECONNREFUSED 192.168.0.11:80"
    ],
    "httpCode": "rejected"
  }
}
```

## Causa do Problema
O N8N está interpretando o hostname "ollama" e tentando acessar na porta 80 (HTTP padrão) em vez da porta 11434 que é a porta correta do serviço Ollama.

## Solução Implementada
Foi criado um novo arquivo de workflow `n8n_email_daily_tasks_direct_ip.json` com uma modificação na URL do nó "Gerar Conteúdo do Email com IA":

Alteração: De `http://ollama:11434/api/chat` para `http://172.18.0.2:11434/api/chat`

Esta solução usa o IP direto do container Ollama dentro da rede Docker (172.18.0.2) para garantir que a conexão seja feita corretamente.

## Como usar esta solução

1. Importe o arquivo `n8n_email_daily_tasks_direct_ip.json` no seu N8N
2. Configure as credenciais conforme o guia original
3. Execute o workflow para testar

**Observação importante**: Se você reiniciar os containers Docker, o IP do container Ollama pode mudar. Caso isso aconteça, você precisará atualizar o IP no workflow novamente. Você pode obter o IP atual do container Ollama usando o comando:

```bash
docker network inspect orga-ai-v4_app-network | grep -A 5 "ollama" | grep "IPv4Address" | sed -E 's/.*"([0-9.]+)\/.*$/\1/'
```

## Alternativas para resolver o problema permanentemente

1. **Modificar o arquivo hosts dentro do container N8N**:
   ```bash
   docker-compose exec n8n sh -c "echo '172.18.0.2 ollama' >> /etc/hosts"
   ```
   Isto associa o nome 'ollama' diretamente ao IP correto dentro do container

2. **Usar um proxy reverso via Kong**:
   Configurar o Kong para rotear as requisições para o Ollama

3. **Atualizar o arquivo docker-compose.yml**:
   Adicionar configurações de rede específicas para garantir resolução DNS consistente

Este problema é um conhecido comportamento em ambientes Docker quando a resolução DNS não funciona como esperado entre containers.
