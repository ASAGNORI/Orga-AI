#!/bin/bash

set -e

# Load environment variables
if [ -f ../.env ]; then
    export $(cat ../.env | grep -v '^#' | xargs)
fi

# Wait for PostgreSQL to be ready
until PGPASSWORD=$POSTGRES_PASSWORD psql -h db -U postgres -c '\q'; do
    echo "PostgreSQL is unavailable - sleeping"
    sleep 1
done

echo "PostgreSQL is up - executing initial setup"

# Run initial setup SQL
PGPASSWORD=$POSTGRES_PASSWORD psql -h db -U postgres -d postgres -f /docker-entrypoint-initdb.d/init.sql

# Run migrations
for file in /docker-entrypoint-initdb.d/migrations/*.sql; do
    if [ -f "$file" ]; then
        echo "Running migration: $file"
        PGPASSWORD=$POSTGRES_PASSWORD psql -h db -U postgres -d postgres -f "$file"
    fi
done

echo "Database initialization complete!"