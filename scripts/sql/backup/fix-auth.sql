-- Fix para os problemas de migração do Auth

-- Adiciona a coluna identity_data se não existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'auth' 
        AND table_name = 'identities' 
        AND column_name = 'identity_data'
    ) THEN
        ALTER TABLE auth.identities ADD COLUMN identity_data jsonb NOT NULL DEFAULT '{}'::jsonb;
    END IF;
END $$;

-- Adiciona a coluna last_sign_in_at se não existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'auth' 
        AND table_name = 'identities' 
        AND column_name = 'last_sign_in_at'
    ) THEN
        ALTER TABLE auth.identities ADD COLUMN last_sign_in_at timestamptz;
    END IF;
END $$;

-- Adiciona a coluna provider_id se não existe ou altera a restrição NOT NULL
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'auth' 
        AND table_name = 'identities' 
        AND column_name = 'provider_id'
    ) THEN
        ALTER TABLE auth.identities ADD COLUMN provider_id TEXT DEFAULT 'default';
    ELSE
        -- Se existe mas está com NOT NULL constraint, remover a restrição
        ALTER TABLE auth.identities ALTER COLUMN provider_id DROP NOT NULL;
        -- Atualizar valores nulos com um valor padrão
        UPDATE auth.identities SET provider_id = 'default' WHERE provider_id IS NULL;
    END IF;
END $$;

-- Garante que a tabela schema_migrations existe
CREATE TABLE IF NOT EXISTS auth.schema_migrations (
    version varchar(255) PRIMARY KEY
);

-- Marca a migração problemática como já aplicada
INSERT INTO auth.schema_migrations (version)
SELECT '20221125140132'
WHERE NOT EXISTS (SELECT 1 FROM auth.schema_migrations WHERE version = '20221125140132');

-- Adiciona um email de teste (opcional, apenas para garantir que existem dados)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM auth.users WHERE email = 'teste@example.com'
    ) THEN
        RAISE NOTICE 'Usuário teste já existe';
    ELSE
        INSERT INTO auth.users (email, encrypted_password, email_confirmed_at)
        VALUES ('teste@example.com', '$2a$10$d4QoJ.RhOWJXjLjyy8JjrepWJXJgYKCbo9WHY8bW5z5GrK6h8LYdq', NOW());
    END IF;
END $$; 