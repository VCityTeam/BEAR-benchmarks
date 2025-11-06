#!/bin/bash
set -euo pipefail

# Ensure bind-mounted data directories are owned by the runtime user
fix_ownership() {
    local path=$1
    if [ -d "$path" ]; then
        chown -R "${JENA_USER}:${JENA_USER}" "$path"
    fi
}

fix_ownership /data/tdb-databases
fix_ownership /data/queries

# Drop privileges to the configured Jena user for the actual command
exec gosu "${JENA_USER}:${JENA_USER}" "$@"
