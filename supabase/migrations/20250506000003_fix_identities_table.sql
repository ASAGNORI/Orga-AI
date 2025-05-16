-- Fix para o problema da coluna identity_data na tabela auth.identities
-- Esta migração garante que a coluna identity_data exista e marca a migração problemática como já aplicada

-- Primeiro, verifica se a coluna identity_data existe na tabela auth.identities
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'auth' 
        AND table_name = 'identities' 
        AND column_name = 'identity_data'
    ) THEN
        -- Adiciona a coluna identity_data se não existir
        ALTER TABLE auth.identities ADD COLUMN identity_data jsonb NOT NULL DEFAULT '{}'::jsonb;
    END IF;
END $$;

-- Verifica se a coluna last_sign_in_at existe na tabela auth.identities
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'auth' 
        AND table_name = 'identities' 
        AND column_name = 'last_sign_in_at'
    ) THEN
        -- Adiciona a coluna last_sign_in_at se não existir
        ALTER TABLE auth.identities ADD COLUMN last_sign_in_at timestamptz;
    END IF;
END $$;

-- Marca a migração problemática como já aplicada para evitar que ela seja executada
INSERT INTO auth.schema_migrations (version)
SELECT '20221125140132'
WHERE NOT EXISTS (SELECT 1 FROM auth.schema_migrations WHERE version = '20221125140132');

-- Garante que a migração seja marcada como aplicada mesmo se a tabela não existir
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.tables 
        WHERE table_schema = 'auth' 
        AND table_name = 'schema_migrations'
    ) THEN
        CREATE TABLE IF NOT EXISTS auth.schema_migrations (
            version varchar(255) PRIMARY KEY
        );
        
        INSERT INTO auth.schema_migrations (version) VALUES ('20221125140132');
    END IF;
END $$; 