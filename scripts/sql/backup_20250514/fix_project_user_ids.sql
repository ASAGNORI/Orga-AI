-- Corrigir o problema de user_id nos projetos
-- Atualiza todos os projetos sem user_id para apontarem para o usuário administrador
-- Funciona de forma similar ao fix_task_user_ids.sql

-- 1. Primeiro encontramos o ID do usuário administrador
DO $$
DECLARE
  admin_id UUID;
BEGIN
  -- Obter o ID do usuário administrador
  SELECT id INTO admin_id FROM auth.users WHERE email = 'angelo.sagnori@gmail.com';

  -- Verificação para prevenção de erros
  IF admin_id IS NULL THEN
    RAISE EXCEPTION 'Usuário administrador não encontrado!';
  END IF;

  -- Atualizar todos os projetos que não têm user_id para o ID do administrador
  UPDATE projects 
  SET user_id = admin_id
  WHERE user_id IS NULL;
  
  -- Exibir quantos projetos foram atualizados
  RAISE NOTICE 'Projetos atualizados com sucesso para o usuário %', admin_id;
END $$;

-- Consultar para verificar se a atualização funcionou
SELECT id, title, user_id FROM projects LIMIT 10;
