#!/bin/bash

# Wrapper script to load datasets into TDB using Docker
# Usage: ./load-docker.sh [dataset-pattern]
# Example: ./load-docker.sh "day-*"

set -e

DATASET="$1"

echo "Using Docker image for QuaDer-CLI..."
docker compose up -d postgres-flat

echo ""
echo "Running QuaDer-CLI in Docker container..."
docker compose run --rm quads-loader-cli-flat bash /data/docker-scripts/load-converg.sh "$DATASET"

echo "ConVerG database is in: ./pg-data"

