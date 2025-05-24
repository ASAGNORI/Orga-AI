#!/usr/bin/env python3
"""
Script para analisar e corrigir problemas na saída do modelo Ollama
Este script testa o modelo optimized-gemma3 e verifica problemas conhecidos

Uso:
    python3 check_model_output.py
"""

import subprocess
import re
import sys
import json

def clean_output(text):
    """Limpa a saída do modelo removendo artefatos indesejados."""
    # Remover blocos de código vazios
    text = re.sub(r'```[\s\n]*```', '', text)
    
    # Remover linhas consecutivas de backticks
    text = re.sub(r'(```\n)+', '```\n', text)
    
    # Remover asteriscos
    text = text.replace('*', '')
    
    # Remover todos os blocos de código
    text = re.sub(r'```[\s\S]*?```', '', text)
    
    # Remover linhas em branco consecutivas
    text = re.sub(r'\n\s*\n\s*\n+', '\n\n', text)
    
    # Remover backticks soltos
    text = text.replace('```', '')
    
    return text.strip()

def generate_modelfile_fix():
    """Gera um Modelfile corrigido com base nos problemas identificados."""
    return '''FROM gemma3:1b

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
'''

def test_model():
    """Testa o modelo e verifica se há problemas conhecidos."""
    print("🧪 Testando o modelo optimized-gemma3...")
    
    try:
        # Verificar se o modelo existe
        result = subprocess.run(
            ["ollama", "show", "optimized-gemma3"],
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            print("❌ O modelo optimized-gemma3 não está disponível.")
            return False
        
        test_prompts = [
            "Olá, como você está?",
            "Me ajude a organizar minhas tarefas",
            "Qual é o seu nome?",
            "O que você pode fazer?"
        ]
        
        for i, prompt in enumerate(test_prompts):
            print(f"\n📝 Testando prompt {i+1}: '{prompt}'")
            
            # Enviar o prompt para o modelo
            cmd = ["ollama", "run", "optimized-gemma3", prompt]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            
            if result.returncode != 0:
                print(f"❌ Erro ao executar o modelo: {result.stderr}")
                continue
            
            output = result.stdout
            print("\n🔍 Saída original do modelo:")
            print("-" * 40)
            print(output[:500] + "..." if len(output) > 500 else output)
            print("-" * 40)
            
            # Verificar problemas conhecidos
            has_backticks = "```" in output
            has_asterisks = "*" in output
            has_empty_lines = "\n\n\n" in output
            
            if has_backticks or has_asterisks or has_empty_lines:
                print("\n⚠️ Problemas detectados:")
                if has_backticks:
                    print("   - Contém blocos de código (```)")
                if has_asterisks:
                    print("   - Contém asteriscos (*)")
                if has_empty_lines:
                    print("   - Contém múltiplas linhas em branco")
                
                # Limpar a saída
                cleaned = clean_output(output)
                print("\n🧹 Saída limpa:")
                print("-" * 40)
                print(cleaned[:500] + "..." if len(cleaned) > 500 else cleaned)
                print("-" * 40)
            else:
                print("✅ Nenhum problema detectado nesta resposta.")
        
        return True
    
    except Exception as e:
        print(f"❌ Erro ao testar o modelo: {e}")
        return False

def generate_fix():
    """Gera uma solução para os problemas identificados."""
    print("\n🛠️ Gerando solução para os problemas...")
    
    print("\n1️⃣ Modelfile corrigido:")
    print("-" * 40)
    modelfile = generate_modelfile_fix()
    print(modelfile)
    print("-" * 40)
    
    print("\n2️⃣ Script de limpeza para tratar resposta do modelo:")
    print("-" * 40)
    print('''
def clean_model_response(response):
    """Limpa a resposta do modelo removendo artefatos indesejados."""
    import re
    
    # Remove empty code blocks
    response = re.sub(r\'```[\\s\\n]*```\', \'\', response)
    
    # Remove all code blocks
    response = re.sub(r\'```[\\s\\S]*?```\', \'\', response)
    
    # Remove asterisks
    response = response.replace(\'*\', \'\')
    
    # Remove backticks
    response = response.replace(\'```\', \'\')
    
    # Remove consecutive empty lines
    response = re.sub(r\'\\n\\s*\\n\\s*\\n+\', \'\\n\\n\', response)
    
    return response.strip()
''')
    print("-" * 40)
    
    print("\n3️⃣ Comandos para reconstruir o modelo:")
    print("-" * 40)
    print("# Remover o modelo atual")
    print("ollama rm optimized-gemma3")
    print("\n# Recriar o modelo com o novo Modelfile")
    print("ollama create optimized-gemma3 -f /Users/angelosagnori/Downloads/orga-ai-v4/cookbooks/models/Modelfile")
    print("-" * 40)

if __name__ == "__main__":
    print("🔍 Analisador de saída do modelo optimized-gemma3")
    print("=" * 60)
    
    if test_model():
        generate_fix()
    
    print("\n✨ Análise concluída!")
