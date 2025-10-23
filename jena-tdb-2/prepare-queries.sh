#!/bin/bash

# Script to prepare queries for a given dataset
# Usage: ./prepare-queries.sh DATASET_NAME
# Example: ./prepare-queries.sh BEAR-A
# Example: ./prepare-queries.sh BEAR-B

set -e

DATASET=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -*)
            echo "Error: Unknown option $1"
            echo "Usage: $0 DATASET_NAME"
            echo "Example: $0 BEAR-A"
            exit 1
            ;;
        *)
            if [ -z "$DATASET" ]; then
                DATASET=$1
            else
                echo "Error: Multiple dataset names provided"
                echo "Usage: $0 DATASET_NAME"
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if dataset name is provided
if [ -z "$DATASET" ]; then
    echo "Error: Dataset name is required"
    echo "Usage: $0 DATASET_NAME"
    echo "Example: $0 BEAR-A"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BEAR_INPUTS_DIR="${PROJECT_ROOT}/bear-inputs"
PREPARE_RQ_SCRIPT="${BEAR_INPUTS_DIR}/prepare-rq-queries.sh"
SOURCE_QUERIES_DIR="${BEAR_INPUTS_DIR}/${DATASET}/queries/rq"
DEST_QUERIES_DIR="${PROJECT_ROOT}/experiment/queries/${DATASET}"

if [ ! -d "${BEAR_INPUTS_DIR}/${DATASET}" ]; then
    echo "Error: Dataset directory not found: ${BEAR_INPUTS_DIR}/${DATASET}"
    exit 1
fi

# Step 1: Call prepare-rq-queries.sh
echo "Generating .rq query files from raw queries..."
"$PREPARE_RQ_SCRIPT" "$DATASET"

# Step 2: Check if source queries directory exists
if [ ! -d "$SOURCE_QUERIES_DIR" ]; then
    echo "Error: Source queries directory not found: $SOURCE_QUERIES_DIR"
    exit 1
fi

# Step 3: Copy queries to experiment/queries/$DATASET
echo "Copying queries to experiment directory..."
# Create destination directory if it doesn't exist
mkdir -p "$DEST_QUERIES_DIR"

# Copy all .rq files
cp -r "${SOURCE_QUERIES_DIR}"/* "$DEST_QUERIES_DIR/"

echo "Copied $(ls -1 "$SOURCE_QUERIES_DIR" | wc -l | tr -d ' ') query files"
echo "Done! Queries are ready at: $DEST_QUERIES_DIR"

