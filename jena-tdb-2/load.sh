#!/bin/bash

# Wrapper script to load datasets into TDB using Docker
# Usage: ./load-docker.sh [dataset-pattern]
# Example: ./load-docker.sh "day-*"

set -e

DATASET="$1"

echo "Building Docker image for Jena TDB..."
docker compose build

echo ""
echo "Running TDB loader in Docker container..."
docker compose run --rm jena-tdb bash /data/docker-scripts/load-tdb.sh "$DATASET"

echo "TDB2 database is in: experiment/tdb-databases/$DATASET"

