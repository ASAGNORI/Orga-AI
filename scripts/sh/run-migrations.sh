#!/bin/bash

# Set database connection variables
DB_HOST=${DB_HOST:-db}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-postgres}
DB_USER=${DB_USER:-postgres}
DB_PASSWORD=${DB_PASSWORD:-postgres25}

# Export connection string
export PGPASSWORD=$DB_PASSWORD

# Function to run SQL file
run_sql_file() {
    echo "Running $1..."
    psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -f "$1"
    if [ $? -ne 0 ]; then
        echo "Error running $1"
        exit 1
    fi
}

# Execute scripts in specific order
echo "Running base SQL scripts..."
for file in scripts/sql/*.sql; do
    run_sql_file "$file"
done

echo "Running versioned SQL scripts..."
for file in scripts/sql/versions/*.sql; do
    run_sql_file "$file"
done

echo "Running fix scripts..."
for script in fix_tables.sql fix_user_ids.sql fix_user_table_ids.sql fix_timestamps.sql fix_user_timestamps.sql \
             fix_admin_password.sql fix_password_with_function.sql fix_chat_history.sql \
             fix_task_user_ids.sql fix_project_user_ids.sql fix_task_project_relation.sql fix-uuid.sql; do
    if [ -f "scripts/sql/$script" ]; then
        run_sql_file "scripts/sql/$script"
    fi
done

echo "Running update scripts..."
for script in update_logs_table.sql update_rag_and_prompts.sql; do
    if [ -f "scripts/sql/$script" ]; then
        run_sql_file "scripts/sql/$script"
    fi
done

echo "Running Supabase migrations..."
# Get all SQL files and sort them by version number
find supabase/migrations -name "*.sql" | sort | while read -r file; do
    run_sql_file "$file"
done

echo "All SQL scripts and migrations executed successfully!" 