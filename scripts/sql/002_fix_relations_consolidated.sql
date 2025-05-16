-- Script consolidado para correção de relações e IDs (002_fix_relations_consolidated.sql)
-- Data: 14 de maio de 2025

DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Iniciando script de correção de relações (002_fix_relations_consolidated.sql)';
    RAISE NOTICE 'Data de execução: %', NOW();
    RAISE NOTICE '================================================';
END $$;

-- 1. CORREÇÃO DE USER IDs EM TASKS
DO $$
BEGIN
    -- Remover tasks órfãs (sem usuário válido)
    DELETE FROM public.tasks 
    WHERE user_id NOT IN (SELECT id FROM auth.users);
    
    -- Garantir que todas as tasks têm user_id válido
    ALTER TABLE public.tasks 
    DROP CONSTRAINT IF EXISTS tasks_user_id_fkey,
    ADD CONSTRAINT tasks_user_id_fkey 
    FOREIGN KEY (user_id) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE;
    
    RAISE NOTICE 'Correção de user_ids em tasks concluída';
END $$;

-- 2. CORREÇÃO DE USER IDs EM PROJECTS
DO $$
BEGIN
    -- Remover projetos órfãos
    DELETE FROM public.projects 
    WHERE user_id NOT IN (SELECT id FROM auth.users);
    
    -- Garantir que todos os projetos têm user_id válido
    ALTER TABLE public.projects 
    DROP CONSTRAINT IF EXISTS projects_user_id_fkey,
    ADD CONSTRAINT projects_user_id_fkey 
    FOREIGN KEY (user_id) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE;
    
    RAISE NOTICE 'Correção de user_ids em projects concluída';
END $$;

-- 3. CORREÇÃO DE RELAÇÃO TASK-PROJECT
DO $$
BEGIN
    -- Limpar projetos inválidos das tasks
    UPDATE public.tasks 
    SET project_id = NULL 
    WHERE project_id NOT IN (SELECT id FROM public.projects);
    
    -- Garantir constraint de projeto
    ALTER TABLE public.tasks 
    DROP CONSTRAINT IF EXISTS tasks_project_id_fkey,
    ADD CONSTRAINT tasks_project_id_fkey 
    FOREIGN KEY (project_id) 
    REFERENCES public.projects(id) 
    ON DELETE SET NULL;
    
    RAISE NOTICE 'Correção de relações task-project concluída';
END $$;

-- 4. CORREÇÃO DE TIMESTAMPS
DO $$
BEGIN
    -- Corrigir timestamps nulos em tasks
    UPDATE public.tasks 
    SET created_at = NOW() 
    WHERE created_at IS NULL;
    
    UPDATE public.tasks 
    SET updated_at = created_at 
    WHERE updated_at IS NULL;
    
    -- Corrigir timestamps nulos em projects
    UPDATE public.projects 
    SET created_at = NOW() 
    WHERE created_at IS NULL;
    
    UPDATE public.projects 
    SET updated_at = created_at 
    WHERE updated_at IS NULL;
    
    -- Adicionar triggers de atualização automática se não existirem
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_tasks_updated_at') THEN
        CREATE TRIGGER set_tasks_updated_at
        BEFORE UPDATE ON public.tasks
        FOR EACH ROW
        EXECUTE FUNCTION public.set_current_timestamp_updated_at();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_projects_updated_at') THEN
        CREATE TRIGGER set_projects_updated_at
        BEFORE UPDATE ON public.projects
        FOR EACH ROW
        EXECUTE FUNCTION public.set_current_timestamp_updated_at();
    END IF;
    
    RAISE NOTICE 'Correção de timestamps concluída';
END $$;

-- Confirmação de conclusão
DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Script de correção de relações concluído com sucesso!';
    RAISE NOTICE '================================================';
END $$;
