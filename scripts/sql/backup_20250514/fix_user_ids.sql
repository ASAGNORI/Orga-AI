-- Script de correção para garantir que o campo 'id' da tabela auth.users
-- tem valor padrão UUID gerado automaticamente e que ids nulos são ajustados

DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Iniciando correção de IDs nulos em auth.users';
    RAISE NOTICE 'Data de execução: %', NOW();
    RAISE NOTICE '================================================';
END $$;

-- Garantir que a extensão uuid-ossp está habilitada
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Verificar se a coluna id tem valor padrão e ajustar se necessário
DO $$
BEGIN
    -- Verificar se a coluna id tem valor padrão uuid_generate_v4()
    ALTER TABLE auth.users ALTER COLUMN id SET DEFAULT uuid_generate_v4();
    RAISE NOTICE 'Valor padrão uuid_generate_v4() definido para coluna id';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Não foi possível definir o valor padrão para id: %', SQLERRM;
END $$;

-- Atualizar qualquer registro existente com id nulo
DO $$
DECLARE
    null_count INT;
BEGIN
    -- Contar registros com ID nulo
    SELECT COUNT(*) INTO null_count FROM auth.users WHERE id IS NULL;
    
    IF null_count > 0 THEN
        RAISE NOTICE 'Encontrados % registros com ID nulo. Corrigindo...', null_count;
        
        -- Atualizar registros com ID nulo
        UPDATE auth.users SET id = uuid_generate_v4() WHERE id IS NULL;
        
        RAISE NOTICE 'IDs nulos foram corrigidos com sucesso';
    ELSE
        RAISE NOTICE 'Não foram encontrados registros com ID nulo';
    END IF;
END $$;

-- Verificar constraints
DO $$
BEGIN
    -- Verificar se a coluna id tem a constraint PRIMARY KEY
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints tc
        JOIN information_schema.constraint_column_usage AS ccu USING (constraint_schema, constraint_name)
        WHERE tc.table_schema = 'auth'
          AND tc.table_name = 'users'
          AND tc.constraint_type = 'PRIMARY KEY'
          AND ccu.column_name = 'id'
    ) THEN
        RAISE NOTICE 'Adicionando PRIMARY KEY constraint na coluna id';
        ALTER TABLE auth.users ADD PRIMARY KEY (id);
    ELSE
        RAISE NOTICE 'A coluna id já tem a constraint PRIMARY KEY';
    END IF;
    
    -- Garantir que email é único
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints tc
        JOIN information_schema.constraint_column_usage AS ccu USING (constraint_schema, constraint_name)
        WHERE tc.table_schema = 'auth'
          AND tc.table_name = 'users'
          AND tc.constraint_type = 'UNIQUE'
          AND ccu.column_name = 'email'
    ) THEN
        RAISE NOTICE 'Adicionando UNIQUE constraint na coluna email';
        ALTER TABLE auth.users ADD CONSTRAINT users_email_key UNIQUE (email);
    ELSE
        RAISE NOTICE 'A coluna email já tem a constraint UNIQUE';
    END IF;
END $$;

DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Script de correção de IDs concluído com sucesso!';
    RAISE NOTICE '================================================';
END $$;
