-- Cria uma função para converter UUID para texto de forma segura
CREATE OR REPLACE FUNCTION auth.uuid_to_text(uuid) RETURNS text AS $$
BEGIN
    RETURN $1::text;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Marca a migração 20221208132122 como já aplicada
INSERT INTO auth.schema_migrations (version)
SELECT '20221208132122'
WHERE NOT EXISTS (SELECT 1 FROM auth.schema_migrations WHERE version = '20221208132122');

-- Faz um update seguro nas identidades com conversão de tipos
DO $$
BEGIN
    UPDATE auth.identities
    SET last_sign_in_at = '2022-11-25'
    WHERE
        last_sign_in_at IS NULL AND
        created_at = '2022-11-25'::timestamptz AND
        updated_at = '2022-11-25'::timestamptz AND
        provider = 'email';
END $$; 