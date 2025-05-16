
-- Este script corrige problemas com a tabela auth.users:
-- 1. Garante que o UUID é gerado automaticamente para o ID
-- 2. Alinha a estrutura da tabela com o modelo SQLAlchemy

-- Garante o valor default para o ID
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'auth'
        AND table_name = 'users'
        AND column_name = 'id'
        AND column_default LIKE 'uuid_generate_v4()%'
    ) THEN
        ALTER TABLE auth.users 
        ALTER COLUMN id SET DEFAULT uuid_generate_v4();
    END IF;
END
$$;

-- Adiciona a coluna full_name se não existir
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'auth'
        AND table_name = 'users'
        AND column_name = 'full_name'
    ) THEN
        ALTER TABLE auth.users ADD COLUMN full_name VARCHAR(255);
    END IF;
END
$$;

-- Adiciona a coluna is_admin se não existir
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'auth'
        AND table_name = 'users'
        AND column_name = 'is_admin'
    ) THEN
        ALTER TABLE auth.users ADD COLUMN is_admin BOOLEAN DEFAULT false;
    END IF;
END
$$;

-- Atualiza campos que podem estar null mas não deveriam
UPDATE auth.users
SET is_admin = false
WHERE is_admin IS NULL;

-- Corrige o trigger para campos de timestamp
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'set_auth_users_updated_at'
    ) THEN
        CREATE TRIGGER set_auth_users_updated_at
        BEFORE UPDATE ON auth.users
        FOR EACH ROW
        EXECUTE FUNCTION public.set_current_timestamp_updated_at();
    END IF;
END
$$;

-- Cria função para timestamp se não existir
CREATE OR REPLACE FUNCTION public.set_current_timestamp_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
