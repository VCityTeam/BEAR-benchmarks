#!/bin/bash

# Script to log TDB database size to CSV
# Usage: ./log-size.sh --dataset-full-name <name> --dataset <dataset> --policy <policy> --granularity <granularity> --tag <tag>

set -e

# Parse named arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dataset-full-name)
            DATASET_FULL_NAME="$2"
            shift 2
            ;;
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
            echo "Usage: $0 --dataset-full-name <name> --dataset <dataset> --policy <policy> --granularity <granularity> --tag <tag>"
            exit 1
            ;;
    esac
done

# Validate required arguments
if [ -z "$DATASET_FULL_NAME" ] || [ -z "$DATASET" ] || [ -z "$POLICY" ] || [ -z "$TAG" ]; then
    echo "Error: Missing required arguments"
    echo "Usage: $0 --dataset-full-name <name> --dataset <dataset> --policy <policy> --granularity <granularity> --tag <tag>"
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
TDB_DIR="$PROJECT_ROOT/experiment/tdb-databases/$DATASET_FULL_NAME"
CSV_FILE="$PROJECT_ROOT/benchmark-results/sizes.csv"

# Check if TDB database directory exists
if [ ! -d "$TDB_DIR" ]; then
    echo "Error: TDB database directory does not exist: $TDB_DIR"
    exit 1
fi

# Get the size of the directory in bytes
SIZE=$(du -sk "$TDB_DIR" | cut -f1)
# Convert to bytes (du -sk gives KiB)
SIZE=$((SIZE * 1024))

# Get current date in ISO format
DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Set tool name
TOOL="jena-tdb-2"

# Create benchmark-results directory if it doesn't exist
mkdir -p "$PROJECT_ROOT/benchmark-results"

# Create CSV with header if it doesn't exist
if [ ! -f "$CSV_FILE" ]; then
    echo "DATE,DATASET,POLICY,GRANULARITY,TOOL,TAG,SIZE" > "$CSV_FILE"
    echo "Created CSV file: $CSV_FILE"
fi

# Append the data to CSV
echo "$DATE,$DATASET,$POLICY,$GRANULARITY_VALUE,$TOOL,$TAG,$SIZE" >> "$CSV_FILE"

echo "Logged size for $DATASET_FULL_NAME: $SIZE bytes"
echo "CSV file: $CSV_FILE"

