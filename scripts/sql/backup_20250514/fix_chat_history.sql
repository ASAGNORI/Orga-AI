-- Drop existing table and constraints
DROP TABLE IF EXISTS chat_history;

-- Recreate table with correct structure
CREATE TABLE chat_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    user_message TEXT NOT NULL,
    ai_response TEXT NOT NULL,
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    created_at VARCHAR,
    CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
