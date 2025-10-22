#!/bin/bash
# This script runs inside the Docker container

set -e

DATASETS_DIR="/data/datasets"
TDB_BASE_DIR="/data/tdb-databases"
DATASET_NAME="${1}"

# Check if dataset name is provided
if [ -z "$DATASET_NAME" ]; then
    echo "ERROR: Dataset name is required"
    echo "Usage: $0 <dataset-name>"
    echo "Example: $0 BEAR-B-day-CBTB"
    exit 1
fi

echo "Loading dataset into TDB2..."

# Create TDB base directory
mkdir -p "${TDB_BASE_DIR}"

# Check if TDB database already exists
TDB_LOC="${TDB_BASE_DIR}/${DATASET_NAME}"
if [ -d "$TDB_LOC" ]; then
    echo "TDB2 database already exists: $TDB_LOC. Skipping load (database already loaded)"
    exit 0
fi

# Function to load a single .nq file
load_nq_file() {
    local file=$1
    local basename=$(basename "$file" .nq)

    echo "Loading: ${basename}"
    echo "  Source: $file"
    echo "  Target: $TDB_LOC"

    # Load with xloader
    tdb2.xloader --loc="$TDB_LOC" "$file"
    echo "  ✓ Complete"
    echo ""
}

# Function to load directory with multiple .nq files
load_nq_directory() {
    local dir=$1
    local basename=$(basename "$dir")

    echo "Loading: ${basename} (directory)"
    echo "  Source: $dir"
    echo "  Target: $TDB_LOC"

    # Load all .nq files in directory
    tdb2.xloader --loc="$TDB_LOC" "$dir"/*.nq
    echo "  ✓ Complete"
    echo ""
}



# Check if extracted directory exists
if [ ! -d "$DATASETS_DIR" ]; then
    echo "ERROR: Datasets directory not found: $DATASETS_DIR"
    exit 1
fi

# Check if dataset exists as a .nq file
NQ_FILE="${DATASETS_DIR}/${DATASET_NAME}.nq"
DATASET_DIR="${DATASETS_DIR}/${DATASET_NAME}"

if [ -f "$NQ_FILE" ]; then
    echo "Found .nq file: $NQ_FILE"
    load_nq_file "$NQ_FILE"
elif [ -d "$DATASET_DIR" ] && [ "$(ls -A $DATASET_DIR/*.nq 2>/dev/null)" ]; then
    echo "Found directory with .nq files: $DATASET_DIR"
    load_nq_directory "$DATASET_DIR"
else
    echo "ERROR: Dataset not found: ${DATASET_NAME}"
    echo "Looked for:"
    echo "  - ${NQ_FILE}"
    echo "  - ${DATASET_DIR}/ (with .nq files)"
    exit 1
fi

echo "TDB2 database is in: $TDB_LOC"
