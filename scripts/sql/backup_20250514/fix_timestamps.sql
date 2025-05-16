-- Corrigir timestamp columns em tasks
ALTER TABLE tasks 
  ALTER COLUMN created_at SET DEFAULT NOW(),
  ALTER COLUMN updated_at SET DEFAULT NOW();

-- Corrigir timestamp columns em projects
ALTER TABLE projects
  ALTER COLUMN created_at SET DEFAULT NOW(),
  ALTER COLUMN updated_at SET DEFAULT NOW();

-- Atualizar todas as linhas existentes com timestamps
UPDATE tasks SET updated_at = NOW() WHERE updated_at IS NULL;
UPDATE projects SET updated_at = NOW() WHERE updated_at IS NULL;
