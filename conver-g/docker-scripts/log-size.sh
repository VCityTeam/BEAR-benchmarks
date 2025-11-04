#!/bin/bash
# This script runs inside the Docker container to get PostgreSQL database size

set -e

# Query PostgreSQL to get the database size
DB_SIZE=$(psql -U postgres -d converg -t -c "SELECT pg_database_size('converg');")

if [ -z "$DB_SIZE" ]; then
    echo "ERROR: Failed to get database size from PostgreSQL"
    exit 1
fi

echo "$DB_SIZE"
