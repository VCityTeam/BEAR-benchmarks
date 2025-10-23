#!/bin/bash

# Wrapper script to query TDB databases using Docker
# Usage: ./query.sh -d <dataset> -n <dataset-full-name> -q <query-file>
# Example: ./query.sh -d BEAR-B -n BEAR-B-day-CBTB -q p-1.rq
# Example: ./query.sh --dataset BEAR-B --dataset-full-name BEAR-B-day-CBTB --query-file p-1.rq

set -e

DATASET=""
DATASET_FULL_NAME=""
QUERY_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dataset)
            DATASET="$2"
            shift 2
            ;;
        -n|--dataset-full-name)
            DATASET_FULL_NAME="$2"
            shift 2
            ;;
        -q|--query-file)
            QUERY_FILE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 -d <dataset> -n <dataset-full-name> -q <query-file>"
            echo "   or: $0 --dataset <dataset> --dataset-full-name <dataset-full-name> --query-file <query-file>"
            echo "Example: $0 -d BEAR-B -n BEAR-B-day-CBTB -q p-1.rq"
            exit 1
            ;;
    esac
done

if [ -z "$DATASET" ] || [ -z "$DATASET_FULL_NAME" ] || [ -z "$QUERY_FILE" ]; then
    echo "Error: All parameters are required"
    echo "Usage: $0 -d <dataset> -n <dataset-full-name> -q <query-file>"
    echo "   or: $0 --dataset <dataset> --dataset-full-name <dataset-full-name> --query-file <query-file>"
    echo "Example: $0 -d BEAR-B -n BEAR-B-day-CBTB -q p-1.rq"
    exit 1
fi

TDB_LOC="/data/tdb-databases/${DATASET_FULL_NAME}"
QUERY_PATH="/data/queries/${DATASET}/${QUERY_FILE}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

mkdir -p "$PROJECT_ROOT/experiment/results"

echo "Querying TDB database ${DATASET_FULL_NAME} with query file: ${DATASET}/${QUERY_FILE}"

docker compose run --rm jena-tdb tdb2.tdbquery --loc="$TDB_LOC" --query="$QUERY_PATH" > "$PROJECT_ROOT/experiment/results/${DATASET_FULL_NAME}-${QUERY_FILE%.rq}-result.txt"
