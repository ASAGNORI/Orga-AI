-- Script de correção para relacionamento entre tarefas e projetos
-- Data: 7 de maio de 2025
-- Autor: Orga.AI Team
-- Objetivo: Garantir que as tabelas tasks e projects estejam corretamente configuradas

-- Verificar e adicionar coluna project_id na tabela tasks se não existir
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'tasks'
        AND column_name = 'project_id'
    ) THEN
        ALTER TABLE public.tasks
        ADD COLUMN project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL;
        
        RAISE NOTICE 'Coluna project_id adicionada à tabela tasks';
    ELSE
        RAISE NOTICE 'Coluna project_id já existe na tabela tasks';
    END IF;
END $$;

-- Verificar e adicionar coluna urgency_score na tabela tasks se não existir
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'tasks'
        AND column_name = 'urgency_score'
    ) THEN
        ALTER TABLE public.tasks
        ADD COLUMN urgency_score DOUBLE PRECISION;
        
        RAISE NOTICE 'Coluna urgency_score adicionada à tabela tasks';
    ELSE
        RAISE NOTICE 'Coluna urgency_score já existe na tabela tasks';
    END IF;
END $$;

-- Criar índice para project_id para otimizar consultas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'public'
        AND tablename = 'tasks'
        AND indexname = 'tasks_project_id_idx'
    ) THEN
        CREATE INDEX tasks_project_id_idx ON public.tasks(project_id);
        RAISE NOTICE 'Índice tasks_project_id_idx criado';
    ELSE
        RAISE NOTICE 'Índice tasks_project_id_idx já existe';
    END IF;
END $$;

-- Criar índice para status para otimizar kanban
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'public'
        AND tablename = 'tasks'
        AND indexname = 'tasks_status_idx'
    ) THEN
        CREATE INDEX tasks_status_idx ON public.tasks(status);
        RAISE NOTICE 'Índice tasks_status_idx criado';
    ELSE
        RAISE NOTICE 'Índice tasks_status_idx já existe';
    END IF;
END $$;

-- Adicionar comentários para documentação
COMMENT ON COLUMN public.tasks.project_id IS 'Referência ao projeto ao qual a tarefa pertence';
COMMENT ON COLUMN public.tasks.urgency_score IS 'Pontuação de urgência calculada com base em prioridade, data de vencimento e outros fatores';

-- Verificar se há orphaned tasks (tarefas com project_id inexistente)
DO $$
DECLARE
    orphaned_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO orphaned_count
    FROM public.tasks t
    WHERE t.project_id IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 FROM public.projects p
        WHERE p.id = t.project_id
    );
    
    IF orphaned_count > 0 THEN
        RAISE WARNING 'Existem % tarefas órfãs com referências a projetos inexistentes', orphaned_count;
    END IF;
END $$;

-- Registrar execução do script para fins de manutenção
DO $$
BEGIN
    -- Se existir uma tabela de manutenção, registre a execução aqui
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'maintenance_log'
    ) THEN
        INSERT INTO public.maintenance_log (script_name, executed_at, description)
        VALUES ('fix_task_project_relation.sql', NOW(), 'Correção de relações entre tasks e projects');
    END IF;
END $$;