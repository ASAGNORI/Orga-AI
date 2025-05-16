-- Migration script for RAG and prompt enhancements
-- Created on 2025-05-09

-- Add response_metadata JSON column to chat_history
ALTER TABLE chat_history ADD COLUMN IF NOT EXISTS response_metadata JSONB;
COMMENT ON COLUMN chat_history.response_metadata IS 'Additional metadata like processing time, RAG usage, intent detection';

-- Update chat_prompts table with new columns
ALTER TABLE chat_prompts 
  ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS title VARCHAR,
  ADD COLUMN IF NOT EXISTS category VARCHAR,
  ADD COLUMN IF NOT EXISTS tags VARCHAR[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Create index for faster prompt retrieval by user
CREATE INDEX IF NOT EXISTS idx_chat_prompts_user_id ON chat_prompts(user_id);

-- Update existing chat_prompts to assign them to the first user (admin)
UPDATE chat_prompts
SET user_id = (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
WHERE user_id IS NULL;

-- Make user_id column required after assigning default
ALTER TABLE chat_prompts ALTER COLUMN user_id SET NOT NULL;

-- Create a cache table for RAG embeddings if needed in the future
CREATE TABLE IF NOT EXISTS vector_cache (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  vector_type VARCHAR NOT NULL, -- 'task', 'project', 'chat'
  item_id UUID NOT NULL,
  embedding FLOAT[] NULL, -- Vector data
  metadata JSONB NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for quick vector retrieval
CREATE INDEX IF NOT EXISTS idx_vector_cache_user_type ON vector_cache(user_id, vector_type);

-- Update chat_history table to add optional association with tasks or projects
ALTER TABLE chat_history 
  ADD COLUMN IF NOT EXISTS related_task_id UUID REFERENCES tasks(id),
  ADD COLUMN IF NOT EXISTS related_project_id UUID REFERENCES projects(id);

-- Create trigger to update timestamps
CREATE OR REPLACE FUNCTION update_timestamp() 
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers to tables that need them
DROP TRIGGER IF EXISTS update_chat_prompts_timestamp ON chat_prompts;
CREATE TRIGGER update_chat_prompts_timestamp
BEFORE UPDATE ON chat_prompts
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS update_vector_cache_timestamp ON vector_cache;
CREATE TRIGGER update_vector_cache_timestamp
BEFORE UPDATE ON vector_cache
FOR EACH ROW EXECUTE FUNCTION update_timestamp();
