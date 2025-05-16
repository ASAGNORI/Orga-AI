-- Add is_admin field to users table
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT FALSE;

-- Set angelo.sagnori@gmail.com as admin
UPDATE auth.users SET is_admin = TRUE WHERE email = 'angelo.sagnori@gmail.com';

COMMENT ON COLUMN auth.users.is_admin IS 'Flag para identificar usuários administradores';
