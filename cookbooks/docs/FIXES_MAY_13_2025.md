# Fixes Applied on May 13, 2025

This document describes the fixes applied to the Orga.AI project to resolve authentication, database structure issues, and chat formatting problems.

## Issues Fixed

### 0. Chat Response Formatting Issue (FIXED TODAY)

**Problem:**
- AI chat responses were showing repeated asterisks (**) and other formatting characters
- Chat responses looked unprofessional with unwanted markdown formatting
- The issue was in the Ollama API integration in the backend

**Solution:**
- Implemented complete removal of formatting characters (asterisks, backticks, underscores)
- Added cleaning functions to both `AIService` and `StreamService` classes
- Enhanced system prompts to explicitly instruct the model not to use markdown formatting
- Increased the repetition penalty to prevent character repetition
- Created a restart script for quick backend redeployment after changes

### 1. User Authentication Issue

**Problem:**
- The `auth.users` table had incorrect or missing password hash for the admin user
- Some login attempts would fail with "Incorrect password" errors

**Solution:**
- Created a SQL script to update the password hash for the admin user using a compatible bcrypt hash
- Added the proper default admin user (admin@example.com) with the correct password (admin123)

### 2. User ID Generation Issue

**Problem:**
- The `id` column in `auth.users` table was not correctly auto-generating UUIDs
- This caused "NULL identity key" errors when creating new users

**Solution:**
- Updated the database schema to ensure UUID generation is correctly configured
- Set appropriate DEFAULT constraints and fixed any NULL IDs in existing records
- Ensured the SQLAlchemy model uses `default=uuid.uuid4` for new records

### 3. Timestamp Fields Issue

**Problem:**
- The `created_at` and `updated_at` columns in `auth.users` had NULL values
- This caused validation errors when returning user data

**Solution:**
- Updated all NULL timestamps with current timestamps
- Set DEFAULT constraints and NOT NULL constraints to ensure correct data in the future
- Updated the SQLAlchemy model to use `server_default=func.now()` and `nullable=False`

### 4. Ollama Model Configuration

**Problem:**
- The custom Ollama model was not being loaded correctly

**Solution:**
- Created proper Modelfile for the optimized-gemma3 model
- Updated environment variables to use the optimized model
- Configured proper parameters for model optimization

### 5. Vector Store RAG Error

**Problem:**
- Erro ao atualizar o vectorstore: `'Project' object has no attribute 'name'`
- O serviço de RAG (Retrieval Augmented Generation) estava falhando, impedindo que o chat respondesse perguntas sobre tarefas
- O erro ocorria porque o modelo Project tem um atributo 'title', mas o código tentava acessar 'name'

**Solution:**
- Corrigimos o vector_store_service.py para acessar o atributo correto (project.title)
- Garantimos consistência entre os objetos project_metadata
- Reiniciamos o serviço para aplicar as correções

### 6. Task Statistics Error

**Problem:**
- The tasks page was displaying an error "Failed to fetch task statistics"
- The API endpoint `/api/v1/tasks/stats` was failing when processing task tags and priorities

**Solution:**
- Fixed tag processing to properly check if the tags attribute is both present and a list
- Added validation to ensure priority values match expected values ("high", "medium", "low")
- Improved error logging to capture specific exceptions
- Added additional debug logging to track user ID and task counts

## How to Apply These Fixes

A consolidated script has been created to apply all these fixes. Run:

```bash
./scripts/sh/apply_all_fixes.sh
```

This script will:
1. Apply all necessary SQL fixes to the database
2. Check the status of Ollama models
3. Test authentication with the admin user
4. Restart the backend service to apply code changes

Alternatively, you can manually apply the code fixes and restart the backend:

```bash
# Restart just the backend service
docker-compose restart backend
```

## Default Administrator User

After applying these fixes, you can log in with the following credentials:

- **Email**: admin@example.com
- **Password**: admin123

## Preventing These Issues in the Future

1. Always ensure database scripts create tables with proper constraints (NOT NULL, DEFAULT values)
2. Keep the SQLAlchemy models synchronized with the actual database schema
3. Use the `apply_all_fixes.sh` script when deploying new instances
4. Run migrations in the correct order to avoid inconsistent database states
