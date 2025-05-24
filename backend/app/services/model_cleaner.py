from app.utils.ollama_cleaner import clean_ollama_response

def clean_model_output():
    """
    Função importável para uso direto no serviço de IA
    
    Exemplo de uso:
    ```python
    from app.services.ai_service import AIService
    from app.utils.ollama_cleaner import clean_ollama_response
    
    # Exemplo de integração no método process_message
    def process_message(self, content, system_message=None):
        # Processamento existente
        response = self._get_ollama_response(model=self.ollama_model, prompt=content, system=system_message)
        
        # Limpeza avançada
        cleaned_response = clean_ollama_response(response)
        
        return cleaned_response, {}
    ```
    
    Observações:
    - Esta função remove proativamente asteriscos, backticks e linhas em branco excessivas
    - Funciona independentemente das configurações do modelo
    - Deve ser aplicada em qualquer resposta do modelo antes de enviá-la ao cliente
    """
    return clean_ollama_response
