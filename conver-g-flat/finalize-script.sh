#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/compose.yml"

if [ ! -f "$COMPOSE_FILE" ]; then
    echo "Compose file $COMPOSE_FILE not found." >&2
    exit 1
fi

echo "Stopping Docker Compose stack defined in $COMPOSE_FILE..."

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD=(docker-compose)
else
    echo "Neither 'docker compose' nor 'docker-compose' is available on PATH." >&2
    exit 1
fi

"${DOCKER_COMPOSE_CMD[@]}" -f "$COMPOSE_FILE" down

# removing pg-data folder
rm -rf "$SCRIPT_DIR/pg-data"

echo "Docker Compose stack stopped."
