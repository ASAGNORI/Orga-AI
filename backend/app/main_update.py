# Adicionar no início dos imports
from .routers import tasks, auth, chat, chat_stream, projects, events, webui

# No bloco de inclusão dos routers, adicionar:
app.include_router(chat_stream.router, prefix="/api/v1", tags=["chat-stream"])
