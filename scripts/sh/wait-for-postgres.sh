#!/bin/sh
# wait-for-postgres.sh

set -e

host="$GOTRUE_DB_HOST"
port="$GOTRUE_DB_PORT"
user="$GOTRUE_DB_USER"
password="$GOTRUE_DB_PASSWORD"

until PGPASSWORD=$password psql -h "$host" -p "$port" -U "$user" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up - executing command"

exec "$@"