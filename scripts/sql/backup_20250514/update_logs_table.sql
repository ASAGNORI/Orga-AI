-- Atualizar a tabela system_logs para incluir novos campos necessários para N8N
ALTER TABLE system_logs 
ADD COLUMN IF NOT EXISTS level VARCHAR DEFAULT 'info',
ADD COLUMN IF NOT EXISTS source VARCHAR DEFAULT 'system',
ADD COLUMN IF NOT EXISTS message TEXT,
ALTER COLUMN action DROP NOT NULL;

-- Inserir um log de teste para confirmar as alterações
INSERT INTO system_logs (id, action, level, source, message, details, created_at)
VALUES (
  gen_random_uuid(), 
  'migration', 
  'info', 
  'system', 
  'Tabela de logs atualizada para suportar integração N8N',
  '{"migration_date": "2025-05-15", "version": "1.1.0"}'::jsonb,
  NOW()
);
