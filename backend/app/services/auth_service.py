from datetime import datetime, timedelta
from typing import Optional
import logging
import os
from fastapi import HTTPException, status, Depends
from jose import JWTError, jwt, ExpiredSignatureError
from passlib.context import CryptContext
from sqlalchemy.orm import Session
from fastapi.security import OAuth2PasswordBearer

from app.exceptions.exceptions import CREDENTIALS_EXCEPTION, EMAIL_ALREADY_EXISTS
from app.models.user import User
from app.schemas.user import UserCreate
from app.database import get_db
from app.utils.email import send_email

# Configuração
SECRET_KEY = os.environ.get("SECRET_KEY", "your-secret-key-here")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.environ.get("ACCESS_TOKEN_EXPIRE_MINUTES", 30))
RESET_TOKEN_EXPIRE_MINUTES = int(os.environ.get("RESET_TOKEN_EXPIRE_MINUTES", 15))

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
logger = logging.getLogger(__name__)

# Oauth2 scheme para extração do token
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

class AuthService:
    def __init__(self, db: Session):
        self.db = db

    def verify_password(self, plain_password: str, encrypted_password: str) -> bool:
        return pwd_context.verify(plain_password, encrypted_password)

    def get_password_hash(self, password: str) -> str:
        return pwd_context.hash(password)

    def create_access_token(
        self,
        subject: str,
        expires_delta: Optional[timedelta] = None
    ) -> str:
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        
        to_encode = {"exp": expire, "sub": subject}
        encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
        return encoded_jwt

    def authenticate_user(self, email: str, password: str) -> User:
        user = self.db.query(User).filter(User.email == email).first()
        
        if not user:
            logger.warning("Usuário não encontrado: %s", email)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Credenciais inválidas"
            )
            
        if not self.verify_password(password, user.encrypted_password):
            logger.warning("Senha incorreta para usuário: %s", email)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Credenciais inválidas"
            )
            
        return user

    def create_user(self, user_create: UserCreate) -> User:
        existing_user = self.db.query(User).filter(User.email == user_create.email).first()
        if existing_user:
            logger.info("Tentativa de cadastro com email já existente: %s", user_create.email)
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email já cadastrado"
            )

        encrypted = self.get_password_hash(user_create.password)
        from datetime import datetime
        now = datetime.now()
        db_user = User(
            email=user_create.email,
            encrypted_password=encrypted,
            full_name=user_create.full_name,
            created_at=now,
            updated_at=now
        )
        
        try:
            self.db.add(db_user)
            self.db.commit()
            self.db.refresh(db_user)
            logger.info("Novo usuário criado: %s", db_user.email)
            return db_user
        except Exception as e:
            self.db.rollback()
            logger.error("Erro ao criar usuário: %s - %s", user_create.email, str(e))
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Erro ao criar usuário"
            )

    async def send_reset_password_email(self, email: str) -> None:
        """
        Gera um token de reset e envia por email
        """
        user = self.db.query(User).filter(User.email == email).first()
        
        # Mesmo se o usuário não existir, retornamos sucesso por segurança
        if not user:
            logger.info(f"Tentativa de reset de senha para email não existente: {email}")
            return
            
        # Gerar token de reset
        expires = datetime.utcnow() + timedelta(minutes=RESET_TOKEN_EXPIRE_MINUTES)
        token_data = {
            "sub": user.email,
            "exp": expires,
            "type": "reset_password"
        }
        token = jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)
        
        # Encode token for URL safety
        url_safe_token = token.replace("+", "-").replace("/", "_").replace("=", "~")
        
        # Montar link de reset
        reset_url = f"{os.getenv('FRONTEND_URL', 'http://localhost:3010')}/reset-password?token={url_safe_token}"
        
        # Enviar email
        await send_email(
            to_email=user.email,
            subject="Redefinição de Senha - Orga.AI",
            content=f"""
            <h2>Redefinição de Senha</h2>
            <p>Olá {user.full_name},</p>
            <p>Recebemos uma solicitação para redefinir sua senha. Se você não fez essa solicitação, ignore este email.</p>
            <p>Para redefinir sua senha, clique no link abaixo (válido por {RESET_TOKEN_EXPIRE_MINUTES} minutos):</p>
            <p><a href="{reset_url}">Redefinir minha senha</a></p>
            <p>Se o link não funcionar, copie e cole esta URL no seu navegador:</p>
            <p>{reset_url}</p>
            """
        )

    async def update_password_with_token(self, token: str, new_password: str) -> None:
        """
        Atualiza a senha usando um token de reset
        """
        try:
            # Restore original token format from URL safe version
            original_token = token.replace("-", "+").replace("_", "/").replace("~", "=")
            
            # Validar token
            try:
                payload = jwt.decode(original_token, SECRET_KEY, algorithms=[ALGORITHM])
            except jwt.ExpiredSignatureError:
                raise ValueError("Token expirado. Por favor, solicite um novo link de redefinição.")
            except jwt.JWTError:
                raise ValueError("Token inválido ou mal formatado. Por favor, verifique o link ou solicite um novo.")
                
            email = payload.get("sub")
            token_type = payload.get("type")
            
            if not email or token_type != "reset_password":
                raise ValueError("Token inválido ou expirado. Por favor, solicite um novo link.")
                
            # Buscar usuário
            user = self.db.query(User).filter(User.email == email).first()
            if not user:
                raise ValueError("Usuário não encontrado")
                
            # Atualizar senha
            user.encrypted_password = pwd_context.hash(new_password)
            user.updated_at = datetime.utcnow()
            self.db.commit()
            
        except ExpiredSignatureError:
            raise ValueError("Token expirado")
        except JWTError:
            raise ValueError("Token inválido")
        except Exception as e:
            logger.error(f"Erro ao atualizar senha: {str(e)}")
            raise

# Função para obter o usuário atual (pode ser usada como dependência do FastAPI)
async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    """
    Função independente para obter o usuário atual a partir de um token JWT.
    Esta função pode ser usada como dependência em endpoints do FastAPI.
    
    Args:
        token: Token JWT de autenticação
        db: Sessão do banco de dados
        
    Returns:
        User: Objeto do usuário autenticado
        
    Raises:
        HTTPException: Se o token for inválido ou expirado
    """
    try:
        logger.debug("Decodificando token: %s", token)
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        logger.debug("Payload decodificado: %s", payload)
        
        email: str = payload.get("sub")
        if not email:
            logger.warning("Campo 'sub' ausente no payload do token")
            raise CREDENTIALS_EXCEPTION

        user = db.query(User).filter(User.email == email).first()
        if not user:
            logger.warning("Usuário não encontrado para o email: %s", email)
            raise CREDENTIALS_EXCEPTION

        return user
        
    except ExpiredSignatureError:
        logger.info("Token expirado")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sessão expirada"
        )
    except JWTError as e:
        logger.error("Erro ao decodificar token: %s", e)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido"
        )
