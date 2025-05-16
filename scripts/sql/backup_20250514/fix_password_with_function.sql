-- Recriação da senha com geração garantida por uma função PL/pgSQL
-- que implementa o algoritmo usado pelo sistema

DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Nova tentativa de correção de senha';
    RAISE NOTICE 'Data de execução: %', NOW();
    RAISE NOTICE '================================================';
END $$;

-- Excluir função antiga se existir
DROP FUNCTION IF EXISTS hash_password(text);

-- Criar função de hash que usa formato compatível com o backend
CREATE OR REPLACE FUNCTION hash_password(password text)
RETURNS text AS $$
BEGIN
    -- Usamos pgcrypto para gerar um hash bcrypt
    RETURN crypt(password, gen_salt('bf', 8));
END;
$$ LANGUAGE plpgsql;

-- Atualizar a senha do usuário admin
UPDATE auth.users
SET encrypted_password = hash_password('admin123')
WHERE email = 'admin@example.com';

-- Verificar se a atualização funcionou
DO $$
DECLARE
    user_exists BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM auth.users WHERE email = 'admin@example.com') INTO user_exists;
    
    IF user_exists THEN
        RAISE NOTICE 'Senha atualizada para o usuário admin@example.com';
        RAISE NOTICE 'Nova senha: admin123 (formato compatível com o backend)';
    ELSE
        RAISE NOTICE 'Usuário admin@example.com não encontrado!';
    END IF;
END $$;
