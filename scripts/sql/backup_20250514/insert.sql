-- Inserir usuário na auth.users e sincronizar com public.users
WITH new_user AS (
    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        confirmed_at,
        invited_at,
        confirmation_token,
        confirmation_sent_at,
        recovery_token,
        recovery_sent_at,
        email_change_token,
        email_change,
        email_change_sent_at,
        last_sign_in_at,
        raw_app_meta_data,
        raw_user_meta_data,
        is_super_admin,
        created_at,
        updated_at
    ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(),
        'authenticated',
        'admin',
        'angelo.sagnori@gmail.com',
        crypt('admin123', gen_salt('bf')),
        now(),
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        now(),
        '{"role":"admin"}'::jsonb,
        '{"name":"Admin User"}'::jsonb,
        true,
        now(),
        now()
    ) RETURNING id, email
)
INSERT INTO public.users (
    id,
    email,
    created_at,
    updated_at
) SELECT 
    id,
    email,
    now(),
    now()
FROM new_user;

-- Insert test users and synchronize with public.users
WITH test_users AS (
    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at
    ) VALUES 
    (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(),
        'authenticated',
        'user',
        'user1@example.com',
        crypt('password123', gen_salt('bf')),
        now(),
        '{"role": "user"}'::jsonb,
        '{"name": "Test User 1", "username": "testuser1"}'::jsonb,
        now(),
        now()
    ),
    (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(),
        'authenticated',
        'user',
        'user2@example.com',
        crypt('password123', gen_salt('bf')),
        now(),
        '{"role": "user"}'::jsonb,
        '{"name": "Test User 2", "username": "testuser2"}'::jsonb,
        now(),
        now()
    ) RETURNING id, email
)
INSERT INTO public.users (
    id,
    email,
    created_at,
    updated_at
) SELECT 
    id,
    email,
    now(),
    now()
FROM test_users;

-- Insert test identities
INSERT INTO auth.identities (
    user_id,
    identity_data,
    provider
)
SELECT 
    id,
    json_build_object(
        'sub', id,
        'email', email,
        'email_verified', true
    )::jsonb,
    'email'
FROM auth.users
WHERE email IN ('user1@example.com', 'user2@example.com')
ON CONFLICT DO NOTHING;