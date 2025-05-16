"""
Rotas para integração com Open WebUI
"""
import logging
from typing import Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import JSONResponse
from ..services.auth_service import get_current_user
from ..services.webui_service import webui_service
from ..schemas.user import UserResponse
from pydantic import BaseModel

router = APIRouter(
    tags=["webui"],
    responses={404: {"description": "Not found"}},
)

logger = logging.getLogger(__name__)

class WebUIAuthResponse(BaseModel):
    success: bool
    url: Optional[str] = None
    message: Optional[str] = None
    token: Optional[Dict[str, Any]] = None

@router.get("/sso", response_model=WebUIAuthResponse)
async def webui_sso(current_user: UserResponse = Depends(get_current_user)):
    """SSO para autenticação no Open WebUI"""
    try:
        if not current_user.email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email do usuário não disponível para SSO"
            )
        
        # Gerar token SSO
        result = webui_service.generate_sso_token(
            email=current_user.email,
            name=current_user.full_name or current_user.email.split('@')[0]
        )
        
        if not result["success"]:
            return WebUIAuthResponse(
                success=False,
                message=f"Erro ao gerar token SSO: {result.get('error', 'Erro desconhecido')}"
            )
        
        # Construir URL para redirecionamento
        webui_url = webui_service.webui_base_url
        token = result["data"]["access_token"]
        redirect_url = f"/auth?token={token}"
        
        return WebUIAuthResponse(
            success=True,
            url=redirect_url,
            token=result["data"]
        )
        
    except Exception as e:
        logger.error(f"Erro na autenticação SSO do WebUI: {str(e)}")
        return WebUIAuthResponse(
            success=False,
            message=f"Erro no servidor: {str(e)}"
        )

@router.get("/validate")
async def validate_sso_token(token: str):
    """Valida um token SSO do Open WebUI"""
    try:
        result = webui_service.validate_sso_token(token)
        
        if not result["success"]:
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={"error": result.get("error", "Token inválido")}
            )
            
        return result["data"]
        
    except Exception as e:
        logger.error(f"Erro na validação do token SSO: {str(e)}")
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"error": str(e)}
        )