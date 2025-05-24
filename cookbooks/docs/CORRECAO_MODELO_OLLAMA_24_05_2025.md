# Instruções para corrigir o problema de formatação do modelo optimized-gemma3

## Problema Identificado

O modelo personalizado `optimized-gemma3` está apresentando problemas na formatação de sua saída:

1. Inicialmente estava inserindo múltiplos **asteriscos** (`** ** **`) no texto
2. Após a primeira correção, passou a exibir múltiplas linhas vazias com marcadores de código (```)

## Solução Implementada

### 1. Modificações no Modelfile

Atualizamos o arquivo `/cookbooks/models/Modelfile` com as seguintes melhorias:

```
FROM gemma3:1b

SYSTEM "Você é um assistente organizado e eficiente, especializado em gerenciamento de tarefas e produtividade. Você tem acesso às tarefas do usuário e pode fornecer respostas personalizadas sobre elas. Sempre responda de forma clara, concisa e direta, sem formatação especial. Não use blocos de código, asteriscos, ou qualquer formatação markdown. Evite linhas em branco desnecessárias. Use português do Brasil."

PARAMETER temperature 0.1
PARAMETER top_p 0.9
PARAMETER top_k 40
PARAMETER repeat_last_n 64
PARAMETER repeat_penalty 1.3
PARAMETER num_predict 100
PARAMETER num_ctx 2048
PARAMETER num_thread 4
PARAMETER seed 42
PARAMETER stop "Usuário:"
PARAMETER stop "Assistente:"
PARAMETER stop "```"

TEMPLATE """{{.System}}

{{.Prompt}}

Assistente:"""
```

### 2. Mudanças Principais

1. **Instrução clara no prompt de sistema**: Instruções explícitas para não usar formatação markdown, asteriscos ou blocos de código
2. **Parâmetro stop adicional**: Adicionado `PARAMETER stop "```"` para evitar que o modelo gere blocos de código
3. **Aumento do repeat_penalty**: Alterado de 1.1 para 1.3 para reduzir repetições
4. **Adição do parâmetro seed**: Definido como 42 para maior consistência nas respostas

### 3. Scripts de Suporte

Criamos dois scripts para auxiliar na manutenção do modelo:

1. **`/scripts/sh/clean-rebuild-model.sh`**: Script shell para remover e reconstruir o modelo limpo
2. **`/scripts/utils/check_model_output.py`**: Ferramenta para testar e validar a saída do modelo

## Como Aplicar a Correção

1. **Reconstruir o modelo**:
   ```bash
   cd /Users/angelosagnori/Downloads/orga-ai-v4
   ./scripts/sh/clean-rebuild-model.sh
   ```

2. **Verificar o resultado**:
   ```bash
   ollama run optimized-gemma3 "Olá, como vai?"
   ```

3. **Testar com a ferramenta de diagnóstico** (opcional):
   ```bash
   python3 /Users/angelosagnori/Downloads/orga-ai-v4/scripts/utils/check_model_output.py
   ```

## Verificação de Funcionamento

Após a reconstrução do modelo, ele deve responder sem:
- Asteriscos (`*`)
- Blocos de código (```)
- Linhas em branco consecutivas

## Solução de Problemas

Se os problemas persistirem:

1. **Verifique os logs** do servidor Ollama:
   ```bash
   ollama serve > ollama.log 2>&1
   ```

2. **Limpe completamente o cache** do modelo:
   ```bash
   rm -rf ~/.ollama/models/optimized-gemma3
   ```

3. **Reinicie o servidor Ollama** após limpar o cache e tente novamente.

---

*Documentação criada em 24/05/2025*
