-- Script consolidado para adição de campos (003_add_fields_consolidated.sql)
-- Data: 14 de maio de 2025

DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Iniciando script de adição de campos (003_add_fields_consolidated.sql)';
    RAISE NOTICE 'Data de execução: %', NOW();
    RAISE NOTICE '================================================';
END $$;

-- 1. CAMPOS DE SISTEMA
DO $$
BEGIN
    -- Adicionar campo level em system_logs se não existir
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'system_logs' AND column_name = 'level'
    ) THEN
        ALTER TABLE public.system_logs 
        ADD COLUMN level VARCHAR(50) DEFAULT 'info';
        
        -- Adicionar check constraint para level
        ALTER TABLE public.system_logs 
        ADD CONSTRAINT system_logs_level_check 
        CHECK (level IN ('debug', 'info', 'warning', 'error', 'critical'));
        
        RAISE NOTICE 'Campo level adicionado à tabela system_logs';
    END IF;
    
    -- Adicionar campos de metadados se não existirem
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'system_logs' AND column_name = 'metadata'
    ) THEN
        ALTER TABLE public.system_logs 
        ADD COLUMN metadata JSONB DEFAULT '{}';
        
        RAISE NOTICE 'Campo metadata adicionado à tabela system_logs';
    END IF;
END $$;

-- 2. CAMPOS DE ADMINISTRAÇÃO
DO $$
BEGIN
    -- Garantir que auth.users tem campo is_admin
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'is_admin'
    ) THEN
        ALTER TABLE auth.users 
        ADD COLUMN is_admin BOOLEAN DEFAULT false;
        
        RAISE NOTICE 'Campo is_admin adicionado à tabela users';
    END IF;
    
    -- Atualizar valores nulos
    UPDATE auth.users 
    SET is_admin = false 
    WHERE is_admin IS NULL;
    
    -- Garantir que o usuário admin@example.com é admin
    UPDATE auth.users 
    SET is_admin = true 
    WHERE email = 'admin@example.com';
END $$;

-- 3. CAMPOS DE CHAT E RAG
DO $$
BEGIN
    -- Adicionar campos para RAG em chat_history
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'chat_history' AND column_name = 'context_data'
    ) THEN
        ALTER TABLE public.chat_history 
        ADD COLUMN context_data JSONB DEFAULT '{}',
        ADD COLUMN embedding_vector vector(384),
        ADD COLUMN tokens_used INTEGER DEFAULT 0;
        
        RAISE NOTICE 'Campos RAG adicionados à tabela chat_history';
    END IF;
    
    -- Adicionar campos para prompts salvos
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'chat_prompts' AND column_name = 'metadata'
    ) THEN
        ALTER TABLE public.chat_prompts 
        ADD COLUMN metadata JSONB DEFAULT '{}',
        ADD COLUMN category VARCHAR(50);
        
        RAISE NOTICE 'Campos adicionados à tabela chat_prompts';
    END IF;
END $$;

-- Confirmação de conclusão
DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Script de adição de campos concluído com sucesso!';
    RAISE NOTICE '================================================';
END $$;
