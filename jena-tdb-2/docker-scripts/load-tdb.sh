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

# Function to load CB (Change-Based) datasets with additions/deletions
load_cb_directory() {
    local dir=$1
    local basename=$(basename "$dir")

    echo "Loading: ${basename} (Change-Based dataset)"
    echo "  Source: $dir"
    echo "  Target: $TDB_LOC"
    echo ""
    echo "Converting .nt files to .nq with named graphs..."

    # Create temporary directory for converted files
    local temp_dir="/tmp/tdb-cb-temp-$$"
    mkdir -p "$temp_dir"

    # Convert all added/deleted .nt files to .nq with named graphs
    local file_count=0
    for file in "$dir"/data-added_*.nt "$dir"/data-deleted_*.nt; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file" .nt)
            local nq_file="$temp_dir/${filename}.nq"

            # Extract change type (added/deleted) and version range
            if [[ $filename =~ data-(added|deleted)_([0-9]+)-([0-9]+) ]]; then
                local change_type="${BASH_REMATCH[1]}"
                local version_from="${BASH_REMATCH[2]}"
                local version_to="${BASH_REMATCH[3]}"

                # Create named graph URI
                local graph_uri="http://bear.org/changes/${change_type}/${version_from}-${version_to}"

                # Convert .nt to .nq by adding the graph URI to each line
                # Remove trailing " ." from N-Triples and add graph URI with " ."
                awk -v graph="<$graph_uri>" '{sub(/ \.$/, ""); print $0 " " graph " ."}' "$file" > "$nq_file"

                file_count=$((file_count + 1))
                echo "  Converted: $filename -> ${filename}.nq (graph: $graph_uri)"
            fi
        fi
    done

    echo ""
    echo "Converted $file_count files. Loading into TDB2..."

    # Load all converted .nq files with xloader
    if [ $file_count -gt 0 ]; then
        tdb2.xloader --loc="$TDB_LOC" "$temp_dir"/*.nq
        echo "  ✓ Complete"
    else
        echo "  ⚠ No files to load"
    fi

    # Cleanup
    rm -rf "$temp_dir"
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
elif [ -d "$DATASET_DIR" ] && [ "$(ls -A $DATASET_DIR/data-added_*.nt 2>/dev/null)" ]; then
    echo "Found directory with Change-Based (CB) .nt files: $DATASET_DIR"
    load_cb_directory "$DATASET_DIR"
else
    echo "ERROR: Dataset not found: ${DATASET_NAME}"
    echo "Looked for:"
    echo "  - ${NQ_FILE}"
    echo "  - ${DATASET_DIR}/ (with .nq files)"
    echo "  - ${DATASET_DIR}/ (with CB .nt files: data-added_*.nt, data-deleted_*.nt)"
    exit 1
fi

echo "TDB2 database is in: $TDB_LOC"
