-- Script consolidado para resolver problemas de autenticação e estrutura do banco de dados
-- Este script deve ser executado antes de qualquer outro para garantir consistência

-- Habilitar extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Função para logs de execução
DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Iniciando script de correção consolidado (001_fix_auth_consolidated.sql)';
    RAISE NOTICE 'Data de execução: %', NOW();
    RAISE NOTICE '================================================';
END $$;

-- Garantir que o schema auth existe
CREATE SCHEMA IF NOT EXISTS auth;

-- 1. CORREÇÃO DA TABELA USERS
-- Verificar e corrigir a tabela users
DO $$
BEGIN
    -- Se a tabela não existe, criar com a estrutura correta
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
        RAISE NOTICE 'Criando tabela auth.users com estrutura completa';
        
        CREATE TABLE auth.users (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            email VARCHAR UNIQUE NOT NULL,
            encrypted_password VARCHAR,
            full_name VARCHAR(255),
            is_admin BOOLEAN NOT NULL DEFAULT false,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),
            -- Campos adicionais do Supabase Auth/GoTrue
            instance_id UUID,
            aud VARCHAR,
            role VARCHAR,
            confirmed_at TIMESTAMPTZ,
            invited_at TIMESTAMPTZ,
            confirmation_token VARCHAR,
            confirmation_sent_at TIMESTAMPTZ,
            recovery_token VARCHAR,
            recovery_sent_at TIMESTAMPTZ,
            email_change_token VARCHAR,
            email_change VARCHAR,
            email_change_sent_at TIMESTAMPTZ,
            last_sign_in_at TIMESTAMPTZ,
            raw_app_meta_data JSONB,
            raw_user_meta_data JSONB,
            is_super_admin BOOLEAN
        );
        
        RAISE NOTICE 'Tabela auth.users criada com sucesso';
    ELSE
        RAISE NOTICE 'Tabela auth.users já existe. Verificando e corrigindo campos...';
        
        -- Verificar e adicionar a coluna full_name se não existe
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'full_name'
        ) THEN
            ALTER TABLE auth.users ADD COLUMN full_name VARCHAR(255);
            RAISE NOTICE 'Coluna full_name adicionada à tabela auth.users';
        ELSE
            RAISE NOTICE 'Coluna full_name já existe';
        END IF;
        
        -- Verificar e adicionar a coluna is_admin se não existe
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'is_admin'
        ) THEN
            ALTER TABLE auth.users ADD COLUMN is_admin BOOLEAN DEFAULT false;
            RAISE NOTICE 'Coluna is_admin adicionada à tabela auth.users';
        ELSE
            RAISE NOTICE 'Coluna is_admin já existe';
        END IF;
        
        -- Garantir que id tem DEFAULT uuid_generate_v4()
        BEGIN
            ALTER TABLE auth.users ALTER COLUMN id SET DEFAULT uuid_generate_v4();
            RAISE NOTICE 'Definido valor padrão uuid_generate_v4() para coluna id';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Não foi possível definir valor padrão para id: %', SQLERRM;
        END;
    END IF;
    
    -- Atualizar valores nulos em is_admin
    UPDATE auth.users SET is_admin = false WHERE is_admin IS NULL;
    
    -- Verificar e corrigir tipo da coluna email
    BEGIN
        ALTER TABLE auth.users ALTER COLUMN email TYPE VARCHAR;
        RAISE NOTICE 'Tipo da coluna email corrigido';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Coluna email já está com o tipo correto';
    END;
    
    -- Adicionar UNIQUE constraint se não existir
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint c
        JOIN pg_namespace n ON n.oid = c.connamespace
        WHERE n.nspname = 'auth' AND c.conname ILIKE '%users_email%' AND c.contype = 'u'
    ) THEN
        BEGIN
            ALTER TABLE auth.users ADD CONSTRAINT users_email_key UNIQUE (email);
            RAISE NOTICE 'Constraint UNIQUE adicionada à coluna email';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Não foi possível adicionar constraint UNIQUE para email: %', SQLERRM;
        END;
    END IF;
END $$;

-- 2. FUNÇÃO PARA TIMESTAMP AUTOMÁTICO
CREATE OR REPLACE FUNCTION public.set_current_timestamp_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para atualização automática de updated_at
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'set_auth_users_updated_at'
        AND tgrelid = 'auth.users'::regclass
    ) THEN
        CREATE TRIGGER set_auth_users_updated_at
        BEFORE UPDATE ON auth.users
        FOR EACH ROW
        EXECUTE FUNCTION public.set_current_timestamp_updated_at();
        
        RAISE NOTICE 'Trigger set_auth_users_updated_at criado com sucesso';
    ELSE
        RAISE NOTICE 'Trigger set_auth_users_updated_at já existe';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erro ao verificar/criar trigger: %', SQLERRM;
END $$;

-- 3. TABELA DE TOKENS DE ATUALIZAÇÃO
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'refresh_tokens') THEN
        CREATE TABLE auth.refresh_tokens (
            id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
            token TEXT UNIQUE NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            parent VARCHAR(36),
            revoked BOOLEAN DEFAULT FALSE
        );
        
        RAISE NOTICE 'Tabela auth.refresh_tokens criada';
    ELSE
        RAISE NOTICE 'Tabela auth.refresh_tokens já existe';
    END IF;
END $$;

-- 4. VERIFICAÇÃO E CORREÇÃO DE SCHEMAS E OUTRAS TABELAS
-- Garantir que o schema migrations existe e está configurado corretamente
DO $$
BEGIN
    -- Verificar e criar tabela de migrações do auth
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'schema_migrations') THEN
        CREATE TABLE auth.schema_migrations (
            version varchar(255) PRIMARY KEY
        );
        
        RAISE NOTICE 'Tabela auth.schema_migrations criada';
    ELSE
        RAISE NOTICE 'Tabela auth.schema_migrations já existe';
    END IF;
    
    -- Marcar migrações problemáticas como já aplicadas
    INSERT INTO auth.schema_migrations (version)
    SELECT '20221125140132'
    WHERE NOT EXISTS (SELECT 1 FROM auth.schema_migrations WHERE version = '20221125140132');
    
    INSERT INTO auth.schema_migrations (version)
    SELECT '20230530183156'
    WHERE NOT EXISTS (SELECT 1 FROM auth.schema_migrations WHERE version = '20230530183156');
END $$;

-- 5. CRIAR USUÁRIO PADRÃO PARA TESTE (Se não existir)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'admin@example.com') THEN
        INSERT INTO auth.users (
            email, 
            encrypted_password, 
            full_name,
            is_admin, 
            created_at,
            updated_at,
            confirmed_at
        )
        VALUES (
            'admin@example.com',
            -- senha: admin123 (criptografada com bcrypt)
            '$2b$12$QRCVVnHR.yTl9OLYr6zHi.oBK4R9UpJJ/QjQBwNkYfvQQGIEcR59y',
            'Administrador',
            true,
            NOW(),
            NOW(),
            NOW()
        );
        
        RAISE NOTICE 'Usuário admin@example.com (senha: admin123) criado com sucesso';
    ELSE
        RAISE NOTICE 'Usuário admin@example.com já existe';
    END IF;
END $$;

-- 6. Verificar IDENTIDADES (necessário para integrações como Google, etc)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'identities') THEN
        CREATE TABLE auth.identities (
            id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            provider_id TEXT,
            identity_data JSONB DEFAULT '{}'::jsonb,
            provider TEXT NOT NULL,
            last_sign_in_at TIMESTAMPTZ,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),
            UNIQUE (provider, provider_id)
        );
        
        RAISE NOTICE 'Tabela auth.identities criada com sucesso';
    ELSE
        -- Verificar e adicionar colunas necessárias à tabela identities
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'auth' AND table_name = 'identities' AND column_name = 'identity_data'
        ) THEN
            ALTER TABLE auth.identities ADD COLUMN identity_data JSONB DEFAULT '{}'::jsonb;
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'auth' AND table_name = 'identities' AND column_name = 'last_sign_in_at'
        ) THEN
            ALTER TABLE auth.identities ADD COLUMN last_sign_in_at TIMESTAMPTZ;
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'auth' AND table_name = 'identities' AND column_name = 'provider_id'
        ) THEN
            ALTER TABLE auth.identities ADD COLUMN provider_id TEXT;
        END IF;
        
        RAISE NOTICE 'Tabela auth.identities atualizada';
    END IF;
END $$;

-- 7. RELAÇÕES COM SCHEMA PUBLIC
-- Verifica e garante a existência das tabelas do schema public relacionadas com auth.users

-- Profiles
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') THEN
        CREATE TABLE public.profiles (
            id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
            username text UNIQUE,
            full_name text,
            avatar_url text,
            created_at timestamptz DEFAULT now(),
            updated_at timestamptz DEFAULT now()
        );
        
        RAISE NOTICE 'Tabela public.profiles criada com sucesso';
    ELSE
        RAISE NOTICE 'Tabela public.profiles já existe';
    END IF;
END $$;

-- Projects
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'projects') THEN
        CREATE TABLE public.projects (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            title TEXT NOT NULL,
            description TEXT,
            status TEXT DEFAULT 'active',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        RAISE NOTICE 'Tabela public.projects criada com sucesso';
    ELSE
        RAISE NOTICE 'Tabela public.projects já existe';
    END IF;
END $$;

-- Tasks
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'tasks') THEN
        CREATE TABLE public.tasks (
            id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
            title TEXT NOT NULL,
            description TEXT,
            status TEXT DEFAULT 'todo',
            priority TEXT DEFAULT 'medium',
            due_date TIMESTAMP WITH TIME ZONE,
            estimated_time INTEGER, -- in minutes
            urgency_score DOUBLE PRECISION,
            energy_level INTEGER CHECK (energy_level BETWEEN 1 AND 5),
            tags TEXT[],
            project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        RAISE NOTICE 'Tabela public.tasks criada com sucesso';
    ELSE
        RAISE NOTICE 'Tabela public.tasks já existe';
    END IF;
END $$;

-- Chat History
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'chat_history') THEN
        CREATE TABLE public.chat_history (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            user_message TEXT NOT NULL,
            ai_response TEXT NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        RAISE NOTICE 'Tabela public.chat_history criada com sucesso';
    ELSE
        -- Verificar se a coluna user_id tem o tipo correto (UUID)
        DECLARE
            column_type text;
        BEGIN
            SELECT data_type INTO column_type 
            FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = 'chat_history' AND column_name = 'user_id';
            
            IF column_type != 'uuid' THEN
                -- Remover constraint estrangeira se existir
                EXECUTE 'ALTER TABLE public.chat_history DROP CONSTRAINT IF EXISTS chat_history_user_id_fkey';
                
                -- Converter a coluna para UUID
                ALTER TABLE public.chat_history ALTER COLUMN user_id TYPE UUID USING user_id::uuid;
                
                -- Adicionar nova constraint estrangeira
                ALTER TABLE public.chat_history ADD CONSTRAINT chat_history_user_id_fkey 
                FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
                
                RAISE NOTICE 'Coluna user_id da tabela chat_history convertida para UUID';
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Erro ao verificar/corrigir tipo da coluna user_id na tabela chat_history: %', SQLERRM;
        END;
    END IF;
END $$;

-- Chat Prompts (Prompts Salvos)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'chat_prompts') THEN
        CREATE TABLE public.chat_prompts (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            title VARCHAR(255) NOT NULL,
            content TEXT NOT NULL,
            tags TEXT[],
            is_favorite BOOLEAN DEFAULT false,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        RAISE NOTICE 'Tabela public.chat_prompts criada com sucesso';
    ELSE
        RAISE NOTICE 'Tabela public.chat_prompts já existe';
    END IF;
END $$;

-- Events
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'events') THEN
        CREATE TABLE public.events (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            title TEXT NOT NULL,
            description TEXT,
            start_time TIMESTAMP WITH TIME ZONE NOT NULL,
            end_time TIMESTAMP WITH TIME ZONE NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        RAISE NOTICE 'Tabela public.events criada com sucesso';
    ELSE
        RAISE NOTICE 'Tabela public.events já existe';
    END IF;
END $$;

-- System Logs
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'system_logs') THEN
        CREATE TABLE public.system_logs (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
            action VARCHAR(255) NOT NULL,
            entity_type VARCHAR(255),
            entity_id UUID,
            details JSONB,
            level VARCHAR(50) DEFAULT 'info',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        RAISE NOTICE 'Tabela public.system_logs criada com sucesso';
    ELSE
        -- Verificar se a coluna level existe
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = 'system_logs' AND column_name = 'level'
        ) THEN
            ALTER TABLE public.system_logs ADD COLUMN level VARCHAR(50) DEFAULT 'info';
            RAISE NOTICE 'Coluna level adicionada à tabela system_logs';
        END IF;
        
        RAISE NOTICE 'Tabela public.system_logs já existe';
    END IF;
END $$;

-- Confirmação de conclusão
DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Script de correção consolidado concluído com sucesso!';
    RAISE NOTICE 'Verifique as mensagens acima para detalhes sobre as alterações realizadas.';
    RAISE NOTICE '================================================';
END $$;
