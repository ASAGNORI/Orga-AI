"""
Serviço para reconhecimento de intenção a partir do texto do usuário.
Usado para responder rapidamente sem chamar o LLM quando possível.
Implementa também extração de entidades e ações associadas às intenções.
"""
import logging
import re
import unicodedata
from typing import Optional, Dict, List, Any, Tuple
import json

logger = logging.getLogger(__name__)

class IntentRecognizer:
    """
    Detecta a intenção do usuário com base em padrões comuns.
    Usado para responder rapidamente sem chamar o LLM quando possível.
    Implementa detecção de intenções específicas e extração de entidades.
    """
    
    def __init__(self):
        # Padrões de intenção e suas respostas correspondentes
        self.intent_patterns = {
            # Saudações
            r"^(oi|olá|hey|e aí|bom dia|boa tarde|boa noite)[\s!]*$": {
                "resposta": "Olá! Como posso ajudar você hoje?",
                "intent": "saudação",
                "ação": None
            },
                
            # Agradecimentos
            r"(obrigad[oa]|valeu|thanks|thank you|agradec)": {
                "resposta": "Disponha! Estou aqui para ajudar sempre que precisar.",
                "intent": "agradecimento",
                "ação": None
            },
                
            # Despedidas
            r"(tchau|até mais|até logo|bye|adeus)": {
                "resposta": "Até logo! Estou sempre aqui quando precisar.",
                "intent": "despedida",
                "ação": None
            },
            
            # Perguntas sobre o sistema
            r"(quem (é|e) voc(ê|e)|o que voc(ê|e) (é|e)|qual (é|e) seu nome)": {
                "resposta": "Sou o assistente do Orga.AI, estou aqui para ajudar você a organizar tarefas, gerenciar projetos e aumentar sua produtividade.",
                "intent": "sobre_sistema",
                "ação": None
            },
                
            # Pedidos de ajuda
            r"(ajuda|como funciona|me ajuda|preciso de ajuda)": {
                "resposta": "Posso ajudar com: criação de tarefas, organização de agenda, lembretes, e-mails, resumos semanais. O que você precisa exatamente?",
                "intent": "ajuda",
                "ação": "help"
            },
            
            # Padrões para criação de tarefas
            r"^(criar|nova|adicionar) tarefa:?\s*(.+)$": {
                "resposta": "Vou criar essa tarefa para você. Por favor me informe: qual é a prioridade (alta, média ou baixa) e prazo para conclusão?",
                "intent": "criar_tarefa",
                "ação": "create_task"
            },
                
            # Padrões para listar tarefas
            r"(listar|mostrar|ver) (minhas)?\s*tarefas": {
                "resposta": "Aqui estão suas tarefas atuais:",
                "intent": "listar_tarefas",
                "ação": "list_tasks"
            },
            
            # Pedidos para listar projetos
            r"(listar|mostrar|ver) (meus)?\s*projetos": {
                "resposta": "Aqui estão seus projetos atuais:",
                "intent": "listar_projetos",
                "ação": "list_projects"
            },
                
            # Perguntas sobre funcionalidades
            r"o que voc(ê|e) (pode|sabe) fazer": {
                "resposta": "Posso criar tarefas, organizar sua agenda, enviar lembretes, ajudar com e-mails e gerar relatórios de produtividade.",
                "intent": "funcionalidades",
                "ação": None
            },
            
            # Agendamentos
            r"(agendar|marcar) (uma)?\s*(reunião|evento|compromisso):?\s*(.+)": {
                "resposta": "Vou agendar esse evento. Qual é a data e horário?",
                "intent": "agendar_evento",
                "ação": "schedule_event"
            },
            
            # Lembretes
            r"(lembrar|lembrete):?\s*(.+)": {
                "resposta": "Vou criar um lembrete sobre isso. Para quando devo configurá-lo?",
                "intent": "criar_lembrete",
                "ação": "create_reminder"
            },
            
            # Resposta de email
            r"(responder|resposta) (ao|para) email:?\s*(.+)": {
                "resposta": "Vou ajudar a elaborar uma resposta para esse email. Qual deve ser o tom da resposta (formal, informal)?",
                "intent": "responder_email",
                "ação": "compose_email"
            },
            
            # Resumo diário
            r"(resumo|resumir) (do|meu) dia": {
                "resposta": "Aqui está um resumo do seu dia:",
                "intent": "resumo_dia",
                "ação": "daily_summary"
            }
        }
        
        self.compiled_patterns = {re.compile(pattern, re.IGNORECASE): info 
                                 for pattern, info in self.intent_patterns.items()}
        
    def _normalize_text(self, text: str) -> str:
        """
        Normaliza texto para comparação mais eficiente.
        Remove acentos e converte para lowercase.
        
        Args:
            text: Texto a ser normalizado
            
        Returns:
            Texto normalizado
        """
        # Normaliza (NFC) e converte para ASCII removendo acentos
        text = unicodedata.normalize('NFKD', text).encode('ascii', 'ignore').decode('ascii')
        # Converte para lowercase
        text = text.lower()
        return text
        
    def detect_intent(self, user_input: str) -> Optional[Dict[str, Any]]:
        """
        Detecta a intenção do usuário e retorna informações sobre ela.
        
        Args:
            user_input: Texto digitado pelo usuário
        
        Returns:
            Dicionário com informações da intenção ou None se nenhuma for encontrada
        """
        # Normalizar input para facilitar comparação
        normalized = user_input.lower().strip()
        
        # Verificar padrões de regex
        for pattern, info in self.compiled_patterns.items():
            match = pattern.search(normalized)
            if match:
                logger.info(f"Padrão de intenção detectado: '{pattern.pattern}' para entrada '{normalized}'")
                
                # Extrair grupos de captura (entidades)
                entities = {}
                if match.groups():
                    for i, group in enumerate(match.groups()):
                        if group:
                            entities[f"entity_{i+1}"] = group
                
                # Caso específico para tarefas
                if info["intent"] == "criar_tarefa" and len(match.groups()) > 1:
                    entities["task_title"] = match.groups()[1]
                    
                    # Buscar prioridade em todo o texto
                    priority_match = re.search(r"prioridade\s*(?:é|:)?\s*(alta|média|media|baixa)", normalized)
                    if priority_match:
                        priority = priority_match.group(1).lower()
                        if priority == "media":
                            priority = "média"
                        entities["priority"] = priority
                
                # Caso específico para agendamento
                if info["intent"] == "agendar_evento" and len(match.groups()) > 3:
                    entities["event_title"] = match.groups()[3]
                    
                    # Buscar data/hora em todo o texto
                    date_match = re.search(r"(?:em|no dia|para o dia)\s+(\d{1,2}(?:\s+de|\/)?\s*(?:jan|fev|mar|abr|mai|jun|jul|ago|set|out|nov|dez|\d{1,2}))", normalized)
                    if date_match:
                        entities["date"] = date_match.group(1)
                    
                    time_match = re.search(r"(?:às|as|para)\s+(\d{1,2}(?::|h)?\d{0,2})", normalized)
                    if time_match:
                        entities["time"] = time_match.group(1)
                
                return {
                    "intent": info["intent"],
                    "response": info["resposta"],
                    "action": info["ação"],
                    "confidence": 0.9,
                    "entities": entities
                }
                
        # Nenhum padrão detectado
        return None
        
    def get_response(self, user_input: str) -> Optional[str]:
        """
        Detecta a intenção e retorna apenas a resposta rápida.
        
        Args:
            user_input: Texto digitado pelo usuário
        
        Returns:
            Resposta rápida se um padrão for detectado, ou None caso contrário
        """
        intent_info = self.detect_intent(user_input)
        if intent_info:
            return intent_info["response"]
        return None
        
    def process_message(self, message: str) -> Tuple[bool, Dict[str, Any]]:
        """
        Processa uma mensagem e detecta intenções.
        
        Args:
            message: Mensagem do usuário
            
        Returns:
            Tupla com (tem_intenção, detalhes_intenção)
        """
        try:
            intent_info = self.detect_intent(message)
            if intent_info:
                logger.info(f"Intenção detectada: {intent_info['intent']} (confiança: {intent_info['confidence']})")
                return True, intent_info
            return False, {}
        except Exception as e:
            logger.error(f"Erro ao processar mensagem para detecção de intenção: {str(e)}")
            return False, {}


# Instância global
intent_recognizer = IntentRecognizer()
