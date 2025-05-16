-- Add full_name column to auth.users table
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS full_name TEXT;

-- Update existing users to have a default full_name based on their email
UPDATE auth.users 
SET full_name = COALESCE(full_name, SPLIT_PART(email, '@', 1))
WHERE full_name IS NULL OR full_name = '';

-- Add a trigger to ensure full_name is never null
CREATE OR REPLACE FUNCTION auth.set_default_full_name()
RETURNS trigger AS $$
BEGIN 
    IF NEW.full_name IS NULL OR NEW.full_name = '' THEN
        NEW.full_name := SPLIT_PART(NEW.email, '@', 1);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS ensure_user_full_name ON auth.users;
CREATE TRIGGER ensure_user_full_name
    BEFORE INSERT OR UPDATE ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION auth.set_default_full_name();
