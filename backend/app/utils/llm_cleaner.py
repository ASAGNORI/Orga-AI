"""
Função utilitária para limpeza de respostas de LLM/IA, removendo artefatos de markdown e repetições.
"""
import re

def clean_llm_response(response: str) -> str:
    if not response:
        return response
    # Remove asteriscos, backticks, underscores
    response = response.replace("*", "").replace("`", "").replace("_", "")
    # Remove tags HTML duplicadas
    response = re.sub(r'<(/?)(p|ul|li)>\s*<\1\2>', r'<\1\2>', response)
    # Corrige listas aninhadas erradas
    response = re.sub(r'<ul>\s*<li>', '<ul><li>', response)
    response = re.sub(r'</li>\s*</ul>', '</li></ul>', response)
    # Remove <li> vazio
    response = re.sub(r'<li>\s*</li>', '', response)
    # Garante fechamento de tags
    if response.count('<ul>') > response.count('</ul>'):
        response += '</ul>' * (response.count('<ul>') - response.count('</ul>'))
    if response.count('<p>') > response.count('</p>'):
        response += '</p>' * (response.count('<p>') - response.count('</p>'))
    # Remove espaços extras
    response = re.sub(r'\n+', '\n', response)
    response = re.sub(r'\s{2,}', ' ', response)
    return response.strip()
