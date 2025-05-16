-- Fix chat_history table
ALTER TABLE public.chat_history
    ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Create trigger for chat_history updated_at
DROP TRIGGER IF EXISTS chat_history_updated_at ON public.chat_history;
CREATE TRIGGER chat_history_updated_at
    BEFORE UPDATE ON public.chat_history
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at();

-- Fix tasks table
ALTER TABLE public.tasks
    ALTER COLUMN tags TYPE TEXT[] USING CASE 
        WHEN tags IS NULL THEN ARRAY[]::TEXT[]
        WHEN jsonb_typeof(tags) = 'array' THEN ARRAY(SELECT jsonb_array_elements_text(tags))
        ELSE ARRAY[]::TEXT[]
    END,
    ALTER COLUMN status SET DEFAULT 'todo',
    ALTER COLUMN status SET NOT NULL,
    ADD CONSTRAINT tasks_status_check CHECK (status IN ('todo', 'in_progress', 'done')),
    ALTER COLUMN priority SET DEFAULT 'medium',
    ALTER COLUMN priority SET NOT NULL,
    ADD CONSTRAINT tasks_priority_check CHECK (priority IN ('low', 'medium', 'high'));

-- Add urgency_score column if missing
ALTER TABLE public.tasks
    ADD COLUMN IF NOT EXISTS urgency_score DOUBLE PRECISION;

-- Fix projects table
ALTER TABLE public.projects
    ALTER COLUMN status SET DEFAULT 'active',
    ALTER COLUMN status SET NOT NULL,
    ADD CONSTRAINT projects_status_check CHECK (status IN ('active', 'completed', 'archived'));

-- Create missing indexes
CREATE INDEX IF NOT EXISTS chat_history_user_id_idx ON public.chat_history(user_id);
CREATE INDEX IF NOT EXISTS chat_history_created_at_idx ON public.chat_history(created_at DESC);
CREATE INDEX IF NOT EXISTS projects_user_id_idx ON public.projects(user_id);
CREATE INDEX IF NOT EXISTS projects_status_idx ON public.projects(status);
CREATE INDEX IF NOT EXISTS tasks_priority_idx ON public.tasks(priority);
CREATE INDEX IF NOT EXISTS tasks_created_at_idx ON public.tasks(created_at DESC);

-- Add comments for documentation
COMMENT ON TABLE public.chat_history IS 'Stores chat history and interactions with AI';
COMMENT ON TABLE public.tasks IS 'Stores user tasks with priority and status tracking';
COMMENT ON TABLE public.projects IS 'Stores user projects and their current status';

-- Update existing triggers to ensure they use the correct timezone
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
