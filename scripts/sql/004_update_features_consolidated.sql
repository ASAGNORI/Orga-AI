-- Script consolidado para atualização de features (004_update_features_consolidated.sql)
-- Data: 14 de maio de 2025

DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Iniciando script de atualização de features (004_update_features_consolidated.sql)';
    RAISE NOTICE 'Data de execução: %', NOW();
    RAISE NOTICE '================================================';
END $$;

-- 1. ATUALIZAÇÃO DE SISTEMA DE CHAT
DO $$
BEGIN
    -- Adicionar suporte a prompts salvos por usuário
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'saved_prompts') THEN
        CREATE TABLE public.saved_prompts (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            title VARCHAR(255) NOT NULL,
            content TEXT NOT NULL,
            category VARCHAR(50),
            tags TEXT[],
            is_favorite BOOLEAN DEFAULT false,
            use_count INTEGER DEFAULT 0,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );

        -- Índices para melhor performance
        CREATE INDEX idx_saved_prompts_user ON public.saved_prompts(user_id);
        CREATE INDEX idx_saved_prompts_category ON public.saved_prompts(category);
        
        -- Trigger para updated_at
        CREATE TRIGGER set_saved_prompts_updated_at
        BEFORE UPDATE ON public.saved_prompts
        FOR EACH ROW
        EXECUTE FUNCTION public.set_current_timestamp_updated_at();
        
        RAISE NOTICE 'Tabela saved_prompts criada com sucesso';
    END IF;
END $$;

-- 2. ATUALIZAÇÃO DO SISTEMA DE TAREFAS
DO $$
BEGIN
    -- Adicionar suporte a subtarefas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_schema = 'public' 
                  AND table_name = 'tasks' 
                  AND column_name = 'parent_id') THEN
        
        ALTER TABLE public.tasks
        ADD COLUMN parent_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE,
        ADD COLUMN is_subtask BOOLEAN DEFAULT false,
        ADD COLUMN completion_percentage INTEGER DEFAULT 0 CHECK (completion_percentage BETWEEN 0 AND 100);
        
        -- Índice para consultas de subtarefas
        CREATE INDEX idx_tasks_parent ON public.tasks(parent_id) WHERE parent_id IS NOT NULL;
        
        RAISE NOTICE 'Suporte a subtarefas adicionado com sucesso';
    END IF;

    -- Adicionar campos para IA e automação
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_schema = 'public' 
                  AND table_name = 'tasks' 
                  AND column_name = 'ai_metadata') THEN
        
        ALTER TABLE public.tasks
        ADD COLUMN ai_metadata JSONB DEFAULT '{}',
        ADD COLUMN auto_schedule BOOLEAN DEFAULT false,
        ADD COLUMN energy_level INTEGER CHECK (energy_level BETWEEN 1 AND 5),
        ADD COLUMN estimated_duration INTERVAL;
        
        RAISE NOTICE 'Campos de IA e automação adicionados com sucesso';
    END IF;
END $$;

-- 3. ATUALIZAÇÃO DO SISTEMA DE RELATÓRIOS
DO $$
BEGIN
    -- Criar tabela de métricas de produtividade
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'productivity_metrics') THEN
        CREATE TABLE public.productivity_metrics (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            date DATE NOT NULL,
            tasks_completed INTEGER DEFAULT 0,
            tasks_created INTEGER DEFAULT 0,
            focus_time INTERVAL DEFAULT '0'::INTERVAL,
            energy_level INTEGER,
            productivity_score DECIMAL(5,2),
            notes TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),
            UNIQUE(user_id, date)
        );

        CREATE INDEX idx_productivity_metrics_user_date 
        ON public.productivity_metrics(user_id, date);

        -- Trigger para updated_at
        CREATE TRIGGER set_productivity_metrics_updated_at
        BEFORE UPDATE ON public.productivity_metrics
        FOR EACH ROW
        EXECUTE FUNCTION public.set_current_timestamp_updated_at();
        
        RAISE NOTICE 'Tabela productivity_metrics criada com sucesso';
    END IF;
END $$;

-- 4. ATUALIZAÇÃO DE INTEGRAÇÕES
DO $$
BEGIN
    -- Criar tabela de integrações por usuário
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'user_integrations') THEN
        CREATE TABLE public.user_integrations (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            integration_type VARCHAR(50) NOT NULL,
            credentials JSONB DEFAULT '{}',
            is_active BOOLEAN DEFAULT true,
            settings JSONB DEFAULT '{}',
            last_sync_at TIMESTAMPTZ,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),
            UNIQUE(user_id, integration_type)
        );

        -- Índices para performance
        CREATE INDEX idx_user_integrations_user 
        ON public.user_integrations(user_id);
        
        CREATE INDEX idx_user_integrations_type 
        ON public.user_integrations(integration_type);

        -- Trigger para updated_at
        CREATE TRIGGER set_user_integrations_updated_at
        BEFORE UPDATE ON public.user_integrations
        FOR EACH ROW
        EXECUTE FUNCTION public.set_current_timestamp_updated_at();
        
        RAISE NOTICE 'Tabela user_integrations criada com sucesso';
    END IF;
END $$;

-- Confirmação de conclusão
DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Script de atualização de features concluído com sucesso!';
    RAISE NOTICE '================================================';
END $$;
