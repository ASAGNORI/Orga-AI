-- Fix profiles and tasks to reference public.users instead of auth.users

-- Remove obsolete trigger on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger on public.users to populate profiles
CREATE TRIGGER on_public_user_created
  AFTER INSERT ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Adjust foreign key for tasks.user_id to reference public.users
ALTER TABLE public.tasks
  DROP CONSTRAINT IF EXISTS tasks_user_id_fkey,
  ADD CONSTRAINT tasks_user_id_fkey FOREIGN KEY(user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- Adjust foreign key for profiles.id to reference public.users
ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_id_fkey,
  ADD CONSTRAINT profiles_id_fkey FOREIGN KEY(id) REFERENCES public.users(id) ON DELETE CASCADE; 