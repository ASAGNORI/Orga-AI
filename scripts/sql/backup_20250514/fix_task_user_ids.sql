-- Corrigir o problema de user_id nas tarefas
-- Atualiza todas as tarefas sem user_id para apontarem para o usuário administrador

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

  -- Atualizar todas as tarefas que não têm user_id para o ID do administrador
  UPDATE tasks 
  SET user_id = admin_id
  WHERE user_id IS NULL;
  
  -- Exibir quantas tarefas foram atualizadas
  RAISE NOTICE 'Tarefas atualizadas com sucesso para o usuário %', admin_id;
END $$;

-- Consultar para verificar se a atualização funcionou
SELECT id, title, user_id FROM tasks LIMIT 10;
