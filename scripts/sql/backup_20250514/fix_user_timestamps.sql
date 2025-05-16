-- Script para garantir que os campos de timestamp em auth.users
-- estão configurados corretamente com valores padrão e não permitem nulos

DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Corrigindo campos de timestamp em auth.users';
    RAISE NOTICE 'Data de execução: %', NOW();
    RAISE NOTICE '================================================';
END $$;

-- Verificar e corrigir a coluna created_at
DO $$
BEGIN
    -- Verificar se a coluna created_at existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'created_at'
    ) THEN
        -- Primeiro, atualizar registros existentes com valores nulos
        UPDATE auth.users SET created_at = NOW() WHERE created_at IS NULL;
        
        -- Depois definir valor padrão e não permitir nulos
        ALTER TABLE auth.users 
        ALTER COLUMN created_at SET DEFAULT NOW(),
        ALTER COLUMN created_at SET NOT NULL;
        
        RAISE NOTICE 'Coluna created_at corrigida com sucesso';
    ELSE
        RAISE NOTICE 'Coluna created_at não existe na tabela auth.users';
    END IF;
END $$;

-- Verificar e corrigir a coluna updated_at
DO $$
BEGIN
    -- Verificar se a coluna updated_at existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'updated_at'
    ) THEN
        -- Primeiro, atualizar registros existentes com valores nulos
        UPDATE auth.users SET updated_at = NOW() WHERE updated_at IS NULL;
        
        -- Depois definir valor padrão e não permitir nulos
        ALTER TABLE auth.users 
        ALTER COLUMN updated_at SET DEFAULT NOW(),
        ALTER COLUMN updated_at SET NOT NULL;
        
        RAISE NOTICE 'Coluna updated_at corrigida com sucesso';
    ELSE
        RAISE NOTICE 'Coluna updated_at não existe na tabela auth.users';
    END IF;
END $$;

DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Script de correção de timestamps concluído!';
    RAISE NOTICE '================================================';
END $$;
