"""
Serviço para integração com Open WebUI.
Este serviço provê funcionalidades para autenticação integrada entre o backend e Open WebUI.
"""
import os
import logging
import secrets
import jwt
import time
from typing import Dict, Optional, Any
from fastapi import HTTPException

logger = logging.getLogger(__name__)

class WebUIService:
    def __init__(self):
        """
        Inicializa o serviço WebUI com configurações do ambiente.
        """
        self.webui_url = os.getenv("WEBUI_API_URL", "http://open-webui:8080")
        self.webui_base_url = os.getenv("WEBUI_BASE_URL", "http://localhost:3000")
        self.secret_key = os.getenv("WEBUI_SECRET_KEY")
        if not self.secret_key:
            logger.warning("WEBUI_SECRET_KEY não definida, gerando chave aleatória...")
            self.secret_key = secrets.token_urlsafe(32)

    def generate_sso_token(self, email: str, name: str) -> Dict[str, Any]:
        """
        Gera um token SSO para autenticação no Open WebUI.
        
        Args:
            email: Email do usuário
            name: Nome completo do usuário
            
        Returns:
            Dict: Contendo token de acesso ou mensagem de erro
        """
        try:
            # Gerar token JWT para SSO
            payload = {
                "email": email,
                "name": name,
                "iat": int(time.time()),
                "exp": int(time.time()) + 3600,  # Token válido por 1 hora
                "iss": "orga-ai-backend"
            }
            
            token = jwt.encode(payload, self.secret_key, algorithm="HS256")
            
            return {
                "success": True,
                "data": {
                    "access_token": token,
                    "token_type": "bearer",
                    "expires_in": 3600
                }
            }
            
        except Exception as e:
            logger.error(f"Erro em generate_sso_token: {str(e)}")
            return {"success": False, "error": str(e)}

    def validate_sso_token(self, token: str) -> Dict[str, Any]:
        """
        Valida um token SSO.
        
        Args:
            token: Token SSO a ser validado
            
        Returns:
            Dict: Status da validação e dados do usuário se válido
        """
        try:
            # Decodificar e validar o token
            payload = jwt.decode(token, self.secret_key, algorithms=["HS256"])
            
            return {
                "success": True,
                "data": {
                    "email": payload["email"],
                    "name": payload["name"]
                }
            }
            
        except jwt.ExpiredSignatureError:
            return {"success": False, "error": "Token expirado"}
        except jwt.InvalidTokenError:
            return {"success": False, "error": "Token inválido"}
        except Exception as e:
            logger.error(f"Erro em validate_sso_token: {str(e)}")
            return {"success": False, "error": str(e)}

# Instância global do serviço
webui_service = WebUIService()

