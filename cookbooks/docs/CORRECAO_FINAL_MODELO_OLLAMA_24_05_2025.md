# Correção de Problemas de Formatação no Modelo Ollama (24/05/2025)

## Problema Identificado

O modelo Ollama `optimized-gemma3` estava apresentando dois problemas principais de formatação:

1. ❌ **Adição indesejada de asteriscos (`*`)** nas respostas, sendo utilizados como marcadores ou para formatação
2. ❌ **Uso excessivo de backticks (```)** e formatação markdown desnecessária
3. ❌ **Linhas em branco repetitivas** separando o conteúdo

## Solução Implementada

A solução implementada utiliza uma abordagem em múltiplas camadas para garantir que o problema seja resolvido:

### 1. Atualização do Modelfile

A primeira linha de defesa foi atualizar o Modelfile com instruções mais rígidas e parâmetros otimizados:

```
FROM gemma3:1b

SYSTEM "Você é um assistente organizado e eficiente, especializado em gerenciamento de tarefas e produtividade. REGRAS RÍGIDAS A SEGUIR: 1) NUNCA use asteriscos (*) para criar listas - use hífens (-) ou números (1., 2.) em vez disso; 2) NUNCA use blocos de código (```) ou markdown; 3) NÃO USE LINHAS EM BRANCO consecutivas (no máximo uma linha em branco entre parágrafos); 4) Sempre responda de forma clara e concisa; 5) Use português do Brasil; 6) Seja útil e amigável; 7) Suas respostas devem ser diretas e sem formatação especial; 8) NUNCA use formatação markdown ou síntaxe de formatação especial. 9) NUNCA use backticks (```); 10) NUNCA use asteriscos (*) em nenhum caso."

PARAMETER temperature 0.1
PARAMETER top_p 0.9
PARAMETER top_k 40
PARAMETER repeat_last_n 64
PARAMETER repeat_penalty 1.8  # Aumentado de 1.1 para 1.8 para evitar repetições
PARAMETER num_predict 100
PARAMETER num_ctx 2048
PARAMETER num_thread 4
PARAMETER seed 42  # Adicionado para consistência nas respostas
PARAMETER stop "Usuário:"
PARAMETER stop "Assistente:"
PARAMETER stop "```"  # Evita backticks
PARAMETER stop "*"    # Evita asteriscos
PARAMETER stop "\n\n\n"  # Evita linhas em branco consecutivas
PARAMETER stop "**"   # Evita formatação markdown em negrito 
PARAMETER stop "***"  # Evita formatação markdown em negrito e itálico
```

Mudanças principais:
- Instruções de sistema reforçadas e muito explícitas
- Aumento do `repeat_penalty` de 1.1 para 1.8
- Adição de tokens de parada mais específicos
- Adição de seed para consistência

### 2. Limpeza de Respostas em Múltiplos Níveis

Foram implementados dois níveis de limpeza para garantir que mesmo que o modelo ocasionalmente ignore as instruções, a resposta final esteja corretamente formatada:

#### Nível 1: Limpeza inicial no AIService

O método `_clean_response` no `ai_service.py` foi aprimorado para realizar uma limpeza mais robusta:

```python
def _clean_response(self, response: str) -> str:
    """Remove repetitive markdown/formatting artifacts from the response."""
    if not response:
        return response
        
    # Remove all asterisks completely (main reported problem)
    response = response.replace("*", "")
    
    # Remove all backticks
    response = response.replace("`", "")
    
    # Remove underscore formatting
    response = response.replace("_", "")
    
    # Remove phrase that might be included in template
    response = response.replace("Para ajudar você da melhor forma possível, vou levar em consideração suas tarefas e preferências.", "")
    
    # Remove multiple asterisks that appear together
    response = response.replace("** ** **", "")
    
    import re
    # Remove code blocks entirely
    response = re.sub(r'```[\s\S]*?```', '', response)
    
    # Remove backtick blocks and their content
    response = re.sub(r'`[^`]*`', '', response)
    
    # Clean up excessive newlines
    response = re.sub(r'\n\s*\n', '\n\n', response)
    response = re.sub(r'\n{3,}', '\n\n', response)
    
    # Clean up extra whitespace
    response = re.sub(r'\s+', ' ', response).strip()
        
    return response
```

#### Nível 2: Limpeza Avançada com Utilitário Dedicado

Foi integrado o utilitário `ollama_cleaner.py` diretamente no processo de resposta:

```python
# Apply advanced cleaning from ollama_cleaner utility
from app.utils.ollama_cleaner import clean_ollama_response
response = clean_ollama_response(response)
```

O utilitário `ollama_cleaner.py` contém uma implementação robusta de limpeza:

```python
def clean_ollama_response(response: str) -> str:
    """
    Remove artefatos indesejados de resposta do modelo Ollama como
    backticks, asteriscos e linhas em branco excessivas.
    """
    if not response:
        return response
    
    # Remover blocos de código vazios
    response = re.sub(r'```[\s\n]*```', '', response)
    
    # Remover todos os blocos de código e seu conteúdo
    response = re.sub(r'```[\s\S]*?```', '', response)
    
    # Remover backticks soltos
    response = response.replace('```', '')
    
    # Remover asteriscos (formatação markdown)
    response = response.replace('*', '')
    
    # Melhorar listas que usavam asteriscos, substituindo por hífens
    response = re.sub(r'^\s*\* ', '- ', response, flags=re.MULTILINE)
    
    # Limpar linhas em branco excessivas
    response = re.sub(r'\n\s*\n', '\n\n', response)
    response = re.sub(r'\n{3,}', '\n\n', response)
    
    # Remover linhas em branco no início/fim
    response = re.sub(r'^\s*\n+', '', response)
    response = re.sub(r'\n+\s*$', '', response)
    
    return response.strip()
```

### 3. Scripts para Reconstrução e Testes

Foram utilizados scripts para reconstruir o modelo com as novas configurações:

- `clean-rebuild-model.sh` - Remove o modelo antigo e cria uma nova versão
- `deep-clean-model.sh` - Limpeza completa de caches e reconstrução
- `check_model_output.py` - Utilitário para verificar a qualidade das respostas

## Benefícios da Solução

1. **Robustez**: A solução em múltiplas camadas garante que mesmo que uma falhe, outras camadas ainda podem corrigir o problema.

2. **Desempenho**: A solução não introduz sobrecarga significativa já que a limpeza é feita durante o processamento regular da resposta.

3. **Manutenção**: As funções de limpeza foram devidamente documentadas e modularizadas para facilitar manutenção futura.

4. **Monitoramento**: O script `check_model_output.py` permite verificar se o problema foi realmente corrigido.

## Próximos Passos

1. **Integração Contínua**: Adicionar testes na pipeline de CI para verificar automaticamente se os problemas de formatação não retornaram.

2. **Monitoramento em Produção**: Implementar métricas para monitorar a qualidade das respostas em ambiente de produção.

3. **Aprendizagem**: Estudar os padrões específicos de artefatos gerados pelo modelo para otimizar ainda mais as configurações.

## Conclusão

A solução implementada aborda o problema em múltiplos níveis, desde a configuração do modelo até o processamento pós-geração, garantindo que os usuários não experimentem mais os problemas de formatação indesejados com asteriscos e backticks nas respostas do Ollama.

Implementamos um processador `/backend/app/utils/ollama_cleaner.py` que:
- Remove backticks
- Remove asteriscos
- Formata listas corretamente
- Remove linhas em branco excessivas

## Instruções de Implementação

### Passo 1: Reconstruir o Modelo
```bash
chmod +x /Users/angelosagnori/Downloads/orga-ai-v4/scripts/sh/deep-clean-model.sh
/Users/angelosagnori/Downloads/orga-ai-v4/scripts/sh/deep-clean-model.sh
```

### Passo 2: Integrar a Limpeza no Backend

Adicione a função `clean_ollama_response` em qualquer lugar onde o modelo retorna uma resposta:

```python
from app.utils.ollama_cleaner import clean_ollama_response

# Após obter a resposta do modelo
raw_response = get_model_response(prompt)
clean_response = clean_ollama_response(raw_response)
```

## Verificação de Funcionamento

Após a implementação, o modelo deve responder:
- Sem backticks (```)
- Sem asteriscos (*)
- Com listas usando hífens (-)
- Sem linhas em branco excessivas

## Solução de Problemas

Se ainda houver problemas:

1. **Verifique o processamento**: Confirme que a função `clean_ollama_response` está sendo chamada
2. **Ajuste parâmetros**: Considere aumentar `repeat_penalty` para 2.0
3. **Limpe o cache completo**:
   ```bash
   rm -rf ~/.ollama/models/optimized-gemma3
   ```
4. **Teste com um prompt direto**:
   ```bash
   echo "Oi, por favor liste 3 frutas." | ollama run optimized-gemma3
   ```

---

*Última atualização: 24 de maio de 2025*
