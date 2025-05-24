#!/usr/bin/env python3
"""
Função de processamento para remover marcações indesejadas de respostas do Ollama
Este código pode ser importado e usado no backend para limpar respostas da API
"""

import re


def clean_ollama_response(response: str) -> str:
    """
    Remove artefatos indesejados de resposta do modelo Ollama como
    backticks, asteriscos e linhas em branco excessivas.
    
    Args:
        response: A resposta original do modelo
        
    Returns:
        Resposta limpa sem artefatos
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
    
    # Limpar linhas em branco excessivas (mais rigoroso)
    # Primeiro, normaliza todas as sequências de linhas em branco para uma única linha em branco
    response = re.sub(r'\n\s*\n', '\n\n', response)
    
    # Depois, remove qualquer sequência de mais de uma linha em branco
    response = re.sub(r'\n{3,}', '\n\n', response)
    
    # Remover linhas em branco no início
    response = re.sub(r'^\s*\n+', '', response)
    
    # Remover linhas em branco no final
    response = re.sub(r'\n+\s*$', '', response)
    
    # Remover espaços em branco extras no início/fim
    response = response.strip()
    
    return response


def format_list_items(response: str) -> str:
    """
    Reformata itens de lista para usar hífens uniformemente.
    
    Args:
        response: Resposta limpa do modelo
        
    Returns:
        Resposta com listas padronizadas
    """
    # Substitui listas com asteriscos por hífens
    response = re.sub(r'^\s*\*\s+', '- ', response, flags=re.MULTILINE)
    
    # Garantir que os hífens tenham espaço
    response = re.sub(r'^\s*-([^\s])', r'- \1', response, flags=re.MULTILINE)
    
    return response


# Exemplo de uso
if __name__ == "__main__":
    # Testar com exemplo problema 
    test_response = """Olá! Como posso ajudar você hoje?



* Esta é uma lista com um item
* Este é outro item

```
código desnecessário
```

```
```
```
```
"""
    
    cleaned = clean_ollama_response(test_response)
    formatted = format_list_items(cleaned)
    
    print("=== Resposta Original ===")
    print(repr(test_response))
    print("\n=== Resposta Limpa ===")
    print(repr(cleaned))
    print("\n=== Resposta Formatada ===")
    print(repr(formatted))
