-- Revert user references back to auth.users
ALTER TABLE public.tasks
  DROP CONSTRAINT IF EXISTS tasks_user_id_fkey,
  ADD CONSTRAINT tasks_user_id_fkey FOREIGN KEY(user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_id_fkey,
  ADD CONSTRAINT profiles_id_fkey FOREIGN KEY(id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.projects
  DROP CONSTRAINT IF EXISTS projects_user_id_fkey,
  ADD CONSTRAINT projects_user_id_fkey FOREIGN KEY(user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.chat_history
  DROP CONSTRAINT IF EXISTS chat_history_user_id_fkey,
  ADD CONSTRAINT chat_history_user_id_fkey FOREIGN KEY(user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Remove incorrect trigger
DROP TRIGGER IF EXISTS on_public_user_created ON public.users;

-- Restore correct trigger on auth.users
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Add comment explaining the change
COMMENT ON TABLE auth.users IS 'Primary user table - all user references should point to this table';
