-- Migração: Adicionar project_id à tabela tasks
-- Data: 7 de maio de 2025
-- Descrição: Adiciona a coluna project_id à tabela tasks para permitir a associação de tarefas a projetos

-- Adicionar a coluna project_id se não existir
ALTER TABLE public.tasks
    ADD COLUMN IF NOT EXISTS project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL;

-- Criar índice para project_id para melhorar performance de queries
CREATE INDEX IF NOT EXISTS tasks_project_id_idx ON public.tasks(project_id);

-- Comentário para documentação
COMMENT ON COLUMN public.tasks.project_id IS 'Referência ao projeto ao qual a tarefa pertence';

-- Adicionar definição da relação para documentação
COMMENT ON CONSTRAINT tasks_project_id_fkey ON public.tasks IS 'Chave estrangeira que conecta tarefas a projetos';

-- Atualizar o atributo urgency_score caso não exista
ALTER TABLE public.tasks
    ADD COLUMN IF NOT EXISTS urgency_score DOUBLE PRECISION;