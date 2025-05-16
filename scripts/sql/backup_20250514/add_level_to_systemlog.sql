-- Add level field to system_logs table
-- Date: 12/05/2025
-- Author: GitHub Copilot

-- Check if the column already exists
DO $$ 
BEGIN
  -- Check if level column is missing
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'system_logs' 
    AND column_name = 'level'
  ) THEN
    -- Add level column
    ALTER TABLE system_logs 
    ADD COLUMN level VARCHAR DEFAULT 'info';
    
    -- Log the migration
    RAISE NOTICE 'Added level column to system_logs table';
  ELSE
    RAISE NOTICE 'level column already exists in system_logs table';
  END IF;
END $$;
