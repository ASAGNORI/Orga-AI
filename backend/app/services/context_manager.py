"""
Módulo para gerenciar o contexto das mensagens de chat.
Implementa estratégias de limitação e resumo de contexto.
"""
import logging
from typing import List, Dict, Any, Tuple

logger = logging.getLogger(__name__)

class ContextManager:
    """
    Gerencia o contexto das mensagens enviadas para o LLM.
    Implementa estratégias para otimizar o desempenho:
    1. Limitação do contexto (número máximo de mensagens)
    2. Resumo de conversas longas
    """
    
    def __init__(self, max_messages: int = 0):
        """
        Inicializa o gerenciador de contexto.
        
        Args:
            max_messages: Número máximo de pares mensagem/resposta a incluir no contexto
                          (0 para modo turbo sem contexto)
        """
        self.max_messages = max_messages  # 0 = modo turbo (sem histórico)
    
    def optimize_context(self, history: List[Tuple[str, str]]) -> List[Dict[str, str]]:
        """
        Otimiza o contexto da conversa para envio ao LLM.
        Modo turbo (max_messages=0): retorna lista vazia para máxima performance.
        
        Args:
            history: Lista de tuplas (mensagem_usuario, resposta_ai)
            
        Returns:
            Lista formatada de mensagens para o LLM, com contexto otimizado
        """
        # Para desempenho máximo (modo turbo), não usar contexto
        if self.max_messages == 0 or not history:
            logger.info("🚀 Modo TURBO ativado: Ignorando todo histórico para máxima performance")
            return []
            
        optimized_context = []
        
        # Limitar o número de mensagens no histórico
        limited_history = history[:self.max_messages] if history else []
        
        # Converter para o formato esperado pelo LLM
        # Apenas último par de mensagens para máxima performance
        for user_msg, ai_msg in limited_history:
            # Limitar tamanho de cada mensagem para economizar tokens
            user_msg_short = user_msg[:150] + "..." if len(user_msg) > 150 else user_msg
            ai_msg_short = ai_msg[:150] + "..." if len(ai_msg) > 150 else ai_msg
            
            optimized_context.append({"role": "user", "content": user_msg_short})
            optimized_context.append({"role": "assistant", "content": ai_msg_short})
        
        logger.info(f"Contexto otimizado: {len(limited_history)} de {len(history)} mensagens incluídas (truncadas para máx. 150 caracteres)")
        return optimized_context
    
    def summarize_history(self, history: List[Tuple[str, str]]) -> str:
        """
        Cria um resumo do histórico da conversa quando é muito longo.
        Usado para conversas extensas onde enviar todo o histórico seria ineficiente.
        
        Args:
            history: Lista de tuplas (mensagem_usuario, resposta_ai)
            
        Returns:
            Resumo do histórico da conversa
        """
        # Implementação básica por enquanto - apenas menciona quantas mensagens foram omitidas
        if len(history) <= self.max_messages:
            return ""
            
        omitted_count = len(history) - self.max_messages
        return f"[Contexto: Esta conversa tem {len(history)} mensagens anteriores, mas {omitted_count} foram omitidas para otimização.]"

# Instância global para uso em toda a aplicação
context_manager = ContextManager(max_messages=5)  # Mantém as últimas 5 mensagens para melhor contexto
 