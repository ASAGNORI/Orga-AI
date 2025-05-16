-- filepath: /Users/angelosagnori/Downloads/orga-ai-v4/scripts/sql/add_full_name_column.sql

-- Adiciona a coluna full_name à tabela auth.users se ela não existir
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

