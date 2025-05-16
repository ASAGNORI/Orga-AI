from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.exceptions import RequestValidationError
from app.routers import tasks, auth, chat, projects, events, webui, tags, admin, ai
from app.core.middleware import error_handler, validation_exception_handler, retry_exception_handler
from app.utils.retry import RetryException
from app.database import Base, engine
from app.models.all_models import *  # This imports all models and ensures they are registered
from typing import Union
import datetime
import logging
import os

# Configuração de logs estruturados
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("Orga.AI")

app = FastAPI(
    title="Orga.AI API",
    description="API for Orga.AI project",
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
)

# CORS configuration
def get_allowed_origins():
    env = os.getenv('ENVIRONMENT', 'development')
    base_origins = [
        "http://localhost:3010",      # Next.js frontend (localhost)
        "http://127.0.0.1:3010",      # Next.js via loopback
        "http://frontend:3010",       # Docker container name
        "http://localhost:8000",      # Backend development
        "http://0.0.0.0:3010",        # External access
    ]
    
    # Allow all origins in development mode
    if env == 'development':
        base_origins = ["*"]
    
    # Get any additional origins from environment variable
    extra_origins = os.getenv('ALLOWED_ORIGINS', '').split(',')
    if extra_origins and extra_origins[0]:
        base_origins.extend(extra_origins)
        
    return base_origins

origins = get_allowed_origins()

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    allow_headers=[
        "Content-Type", 
        "Authorization", 
        "Accept", 
        "Origin", 
        "X-Requested-With",
        "X-CSRF-Token",
        "Access-Control-Allow-Origin",
    ],
    expose_headers=["Content-Length", "X-CSRF-Token"],
    max_age=86400,
)

# Add Gzip compression
app.add_middleware(GZipMiddleware, minimum_size=1000)

# Add trusted host middleware
app.add_middleware(
    TrustedHostMiddleware, 
    allowed_hosts=["localhost", "127.0.0.1", "0.0.0.0", "orgaai.com", "*.orgaai.com", "*", "frontend"]
)

# Add custom error handling middleware
app.middleware("http")(error_handler)

# Exception handlers
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(RetryException, retry_exception_handler)

# Include routers
app.include_router(auth.router)  # Auth router doesn't need prefix since it has its own
app.include_router(tasks.router, prefix="/api/v1", tags=["tasks"])
app.include_router(chat.router, prefix="/api/v1", tags=["chat"])
app.include_router(projects.router, prefix="/api/v1", tags=["projects"])
app.include_router(events.router, prefix="/api/v1", tags=["events"])
app.include_router(tags.router, prefix="/api/v1", tags=["tags"])
app.include_router(admin.router, prefix="/api/v1", tags=["admin"])  # Nova rota para admin e N8N
app.include_router(webui.router, prefix="/api/webui", tags=["webui"])  # Nova rota para integração com Open WebUI
app.include_router(admin.router, prefix="/api/v1", tags=["admin"])  # Nova rota para administração
app.include_router(ai.router)  # Nova rota para geração de email com AI

# Create database tables for all models
Base.metadata.create_all(bind=engine)

@app.get("/api/v1/health")
async def health_check_api():
    """Health check endpoint for API"""
    return {
        "status": "healthy",
        "timestamp": datetime.datetime.now().isoformat()
    }

@app.get("/health")
async def health_check_root():
    """Health check endpoint at root for container checks"""
    return {"status": "healthy"}

@app.get("/")
def read_root():
    return {"message": "Welcome to Orga.AI API"}