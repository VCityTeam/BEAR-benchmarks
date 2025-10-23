#!/bin/bash

# Script to log query execution time to CSV
# Usage: ./log-time.sh --dataset-full-name <name> --dataset <dataset> --policy <policy> --granularity <granularity> --tag <tag> --query <query> --time <time_ms> --tool <tool>

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
        --query)
            QUERY="$2"
            shift 2
            ;;
        --time)
            TIME_MS="$2"
            shift 2
            ;;
        --tool)
            TOOL="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 --dataset-full-name <name> --dataset <dataset> --policy <policy> --granularity <granularity> --tag <tag> --query <query> --time <time_ms> --tool <tool>"
            exit 1
            ;;
    esac
done

# Validate required arguments
if [ -z "$DATASET_FULL_NAME" ] || [ -z "$DATASET" ] || [ -z "$POLICY" ] || [ -z "$TAG" ] || [ -z "$QUERY" ] || [ -z "$TIME_MS" ] || [ -z "$TOOL" ]; then
    echo "Error: Missing required arguments"
    echo "Usage: $0 --dataset-full-name <name> --dataset <dataset> --policy <policy> --granularity <granularity> --tag <tag> --query <query> --time <time_ms> --tool <tool>"
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
CSV_FILE="$PROJECT_ROOT/benchmark-results/times.csv"

# Get current date in ISO format
DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Create benchmark-results directory if it doesn't exist
mkdir -p "$PROJECT_ROOT/benchmark-results"

# Create CSV with header if it doesn't exist
if [ ! -f "$CSV_FILE" ]; then
    echo "DATE,DATASET,POLICY,GRANULARITY,TOOL,TAG,QUERY,TIME_MS" > "$CSV_FILE"
    echo "Created CSV file: $CSV_FILE"
fi

# Append the data to CSV
echo "$DATE,$DATASET,$POLICY,$GRANULARITY_VALUE,$TOOL,$TAG,$QUERY,$TIME_MS" >> "$CSV_FILE"

