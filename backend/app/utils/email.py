import os
import logging
import aiosmtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

logger = logging.getLogger(__name__)

# Configurações do servidor SMTP
SMTP_HOST = os.getenv("SMTP_HOST", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER = os.getenv("SMTP_USER", "")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
EMAIL_FROM = os.getenv("EMAIL_FROM", "no-reply@orgaai.com")

async def send_email(to_email: str, subject: str, content: str) -> None:
    """
    Envia um email usando as configurações SMTP definidas
    
    Args:
        to_email: Email do destinatário
        subject: Assunto do email
        content: Conteúdo HTML do email
    """
    try:
        # Criar mensagem
        message = MIMEMultipart("alternative")
        message["From"] = EMAIL_FROM
        message["To"] = to_email
        message["Subject"] = subject
        
        # Adicionar corpo HTML
        html_part = MIMEText(content, "html")
        message.attach(html_part)
        
        # Enviar email
        await aiosmtplib.send(
            message,
            hostname=SMTP_HOST,
            port=SMTP_PORT,
            username=SMTP_USER,
            password=SMTP_PASSWORD,
            use_tls=True,
        )
        
        logger.info(f"Email enviado com sucesso para {to_email}")
        
    except Exception as e:
        logger.error(f"Erro ao enviar email para {to_email}: {str(e)}")
        raise