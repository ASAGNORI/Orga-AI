-- O erro indica que a senha do usuário admin@example.com está incorreta
-- Vamos gerar uma nova senha usando bcrypt para "admin123" que seja compatível
-- com a implementação de verificação do backend

DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Corrigindo senha do usuário admin@example.com';
    RAISE NOTICE 'Data de execução: %', NOW();
    RAISE NOTICE '================================================';
END $$;

-- Verificando se o usuário existe 
DO $$
DECLARE
    user_exists BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM auth.users WHERE email = 'admin@example.com') INTO user_exists;
    
    IF user_exists THEN
        -- Atualização da senha para "admin123"
        -- Esta é uma senha bcrypt gerada para "admin123" com 12 rounds
        -- Compatível com passlib.context em Python usando CryptContext(schemes=["bcrypt"])
        UPDATE auth.users 
        SET encrypted_password = '$2b$12$LiNT1yCNjufpGlLqKJSoPuCjD0Ey3r7lFdGu5UzVcgQIbc.JDwkdS'
        WHERE email = 'admin@example.com';
        
        RAISE NOTICE 'Senha atualizada para o usuário admin@example.com';
        RAISE NOTICE 'Nova senha: admin123';
    ELSE
        RAISE NOTICE 'Usuário admin@example.com não encontrado. Criando usuário...';
        
        -- Inserir o usuário se não existir
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
            '$2b$12$LiNT1yCNjufpGlLqKJSoPuCjD0Ey3r7lFdGu5UzVcgQIbc.JDwkdS',
            'Administrador',
            true,
            NOW(),
            NOW(),
            NOW()
        );
        
        RAISE NOTICE 'Usuário admin@example.com criado com sucesso';
        RAISE NOTICE 'Senha: admin123';
    END IF;
END $$;

DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Script de correção de senha concluído!';
    RAISE NOTICE '================================================';
END $$;
