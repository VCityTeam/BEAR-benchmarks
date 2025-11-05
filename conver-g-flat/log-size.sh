#!/bin/bash

# Script to log ConVerG (PostgreSQL) database size to CSV
# Usage: ./log-size.sh --dataset <dataset> --policy <policy> --granularity <granularity> --tag <tag>

set -e

# Parse named arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dataset)
            DATASET="$2"
            shift 2
            ;;
        --policy)
            POLICY="$2"
            shift 2
            ;;
        --granularity)
            GRANULARITY="$2"
            shift 2
            ;;
        --tag)
            TAG="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 --dataset <dataset> --policy <policy> --granularity <granularity> --tag <tag>"
            echo "Shifting to next argument"
            shift 2
            ;;
    esac
done

# Validate required arguments
if [ -z "$DATASET" ] || [ -z "$POLICY" ] || [ -z "$TAG" ]; then
    echo "Error: Missing required arguments"
    echo "Usage: $0 --dataset <dataset> --policy <policy> --granularity <granularity> --tag <tag>"
    exit 1
fi

# Set granularity to empty string if not set (for BEAR-A and BEAR-C)
GRANULARITY_VALUE="${GRANULARITY:-}"
if [ -z "$GRANULARITY_VALUE" ]; then
    GRANULARITY_VALUE="N/A"
fi

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Define paths
CSV_FILE="$PROJECT_ROOT/benchmark-results/sizes.csv"

echo "Getting PostgreSQL database size..."
# Run the size logging script inside the Docker container and remove the whitespaces
SIZE=$(docker compose exec postgres bash /data/docker-scripts/log-size.sh | tr -d '[:space:]')

if [ -z "$SIZE" ]; then
    echo "Error: Failed to get database size from PostgreSQL"
    exit 1
fi

# Get current date in ISO format
DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Set tool name
TOOL="postgres"

# Create benchmark-results directory if it doesn't exist
mkdir -p "$PROJECT_ROOT/benchmark-results"

# Create CSV with header if it doesn't exist
if [ ! -f "$CSV_FILE" ]; then
    echo "DATE,DATASET,POLICY,GRANULARITY,TOOL,TAG,SIZE" > "$CSV_FILE"
    echo "Created CSV file: $CSV_FILE"
fi

# Append the data to CSV
echo "$DATE,$DATASET,$POLICY,$GRANULARITY_VALUE,$TOOL,$TAG,$SIZE" >> "$CSV_FILE"

echo "Logged size for $DATASET: $SIZE bytes"
echo "CSV file: $CSV_FILE"

