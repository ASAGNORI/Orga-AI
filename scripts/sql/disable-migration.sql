-- Cria tabela de migrações se não existir
CREATE TABLE IF NOT EXISTS auth.schema_migrations (
    version varchar(255) PRIMARY KEY
);

-- Marca as migrações problemáticas como já aplicadas
INSERT INTO auth.schema_migrations (version)
SELECT '20221125140132'
WHERE NOT EXISTS (SELECT 1 FROM auth.schema_migrations WHERE version = '20221125140132');

INSERT INTO auth.schema_migrations (version)
SELECT '20221208132122'
WHERE NOT EXISTS (SELECT 1 FROM auth.schema_migrations WHERE version = '20221208132122'); 