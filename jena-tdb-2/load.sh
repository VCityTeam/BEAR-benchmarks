#!/bin/bash

# Wrapper script to load datasets into TDB using Docker
# Usage: ./load-docker.sh [dataset-pattern]
# Example: ./load-docker.sh "day-*"

set -e

DATASET="$1"
POLICY="$2"

echo "Building Docker image for Jena TDB..."
docker compose build

# if POLICY is IC, transforming .nt to .nq
if [ "$POLICY" == "IC" ]; then
    echo "Transforming $DATASET .nt files to .trig files for IC policy..."
    docker compose run --rm quads-creator "/data/$DATASET" "/data/$DATASET" "*" theoretical "$DATASET"
    echo "  ✓ Transformation complete"
fi

echo ""
echo "Running TDB loader in Docker container..."
docker compose run --rm jena-tdb-2 bash /data/docker-scripts/load-tdb.sh "$DATASET" "$POLICY"

echo "TDB2 database is in: experiment/tdb-databases/$DATASET"

