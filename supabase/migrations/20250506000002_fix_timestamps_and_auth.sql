-- Atualizar a estrutura do chat_history para usar TIMESTAMPTZ
ALTER TABLE public.chat_history
    ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at::TIMESTAMPTZ,
    ALTER COLUMN created_at SET DEFAULT NOW(),
    ALTER COLUMN updated_at TYPE TIMESTAMPTZ USING COALESCE(updated_at::TIMESTAMPTZ, NOW()),
    ALTER COLUMN updated_at SET DEFAULT NOW();

-- Garantir que os triggers de atualização automática existam
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recriar os triggers para cada tabela
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at_timestamp' AND tgrelid = 'public.chat_history'::regclass) THEN
        CREATE TRIGGER set_updated_at_timestamp
            BEFORE UPDATE ON public.chat_history
            FOR EACH ROW
            EXECUTE FUNCTION handle_updated_at();
    END IF;
END $$;

-- Garantir permissões corretas no schema auth
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT SELECT ON auth.users TO authenticated;

-- Atualizar as constraints para garantir integridade referencial
ALTER TABLE public.chat_history
    DROP CONSTRAINT IF EXISTS chat_history_user_id_fkey,
    ADD CONSTRAINT chat_history_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Criar índices adicionais para melhor performance
CREATE INDEX IF NOT EXISTS idx_chat_history_user_id ON public.chat_history(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_history_created_at ON public.chat_history(created_at DESC);

-- Adicionar comentários para documentação
COMMENT ON TABLE public.chat_history IS 'Histórico de conversas com IA';
COMMENT ON COLUMN public.chat_history.user_id IS 'Referência ao usuário no schema auth';
COMMENT ON COLUMN public.chat_history.created_at IS 'Timestamp com timezone da criação';
COMMENT ON COLUMN public.chat_history.updated_at IS 'Timestamp com timezone da última atualização';
