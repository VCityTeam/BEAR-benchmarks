#!/bin/bash
# This script runs inside the Docker container

set -e

DATASETS_DIR="/data/datasets"
DATASET_NAME="${1}"

# Check if dataset name is provided
if [ -z "$DATASET_NAME" ]; then
    echo "ERROR: Dataset name is required"
    echo "Usage: $0 <dataset-name>"
    echo "Example: $0 BEAR-B-day-CBTB"
    exit 1
fi

echo "Loading dataset into ConVerG..."

# Check if extracted directory exists
if [ ! -d "$DATASETS_DIR" ]; then
    echo "ERROR: Datasets directory not found: $DATASETS_DIR"
    exit 1
fi

DATASET_DIR="${DATASETS_DIR}/${DATASET_NAME}"
if [ ! -d "$DATASET_DIR" ]; then
    echo "ERROR: Dataset directory not found: $DATASET_DIR"
    exit 1
fi

for filename in "$DATASET_DIR"/*.trig; do
    echo "import-version \"$filename\"" >> load-commands.txt
done

java -jar /opt/app/quads-cli-loader.jar script load-commands.txt