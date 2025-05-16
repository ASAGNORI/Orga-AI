-- Fix tasks table
ALTER TABLE tasks
ALTER COLUMN status SET DEFAULT 'todo',
ALTER COLUMN status SET NOT NULL,
ALTER COLUMN priority SET DEFAULT 'medium',
ALTER COLUMN priority SET NOT NULL,
DROP COLUMN IF EXISTS updated_at,
ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Add foreign key constraint if missing
ALTER TABLE tasks
DROP CONSTRAINT IF EXISTS tasks_user_id_fkey,
ADD CONSTRAINT tasks_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Fix projects table
ALTER TABLE projects
DROP COLUMN IF EXISTS updated_at,
ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS tasks_user_id_idx ON tasks(user_id);
CREATE INDEX IF NOT EXISTS tasks_status_idx ON tasks(status);
CREATE INDEX IF NOT EXISTS projects_user_id_idx ON projects(user_id);
CREATE INDEX IF NOT EXISTS projects_status_idx ON projects(status);
