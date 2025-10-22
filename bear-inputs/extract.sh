#!/bin/bash

# Extract script for BEAR datasets
# Usage: ./extract.sh --dataset <BEAR-A|BEAR-B|BEAR-C> --policy <CB|CBTB|IC|TB> [--granularity <day|hour|instant>] [--verbose|-v] [--outdir <directory>]
# Example: ./extract.sh --dataset BEAR-A --policy CB
# Example: ./extract.sh --dataset BEAR-B --policy CB --granularity day

set -e

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Parse arguments
VERBOSE=false
DATASET=""
POLICY=""
GRANULARITY=""
OUTDIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --dataset|-d)
            DATASET="$2"
            shift 2
            ;;
        --policy|-p)
            POLICY="$2"
            shift 2
            ;;
        --granularity|-g)
            GRANULARITY="$2"
            shift 2
            ;;
        --outdir)
            OUTDIR="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            shift
            ;;
    esac
done

# Logging helper functions
log_info() {
    echo "$@"
}

log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo "$@"
    fi
}

# Validate required arguments
if [ -z "$DATASET" ] || [ -z "$POLICY" ]; then
    echo "Usage: $0 --dataset <BEAR-A|BEAR-B|BEAR-C> --policy <CB|CBTB|IC|TB> [--granularity <day|hour|instant>] [--verbose|-v] [--outdir <directory>]"
    echo "Example: $0 --dataset BEAR-A --policy CB"
    echo "Example: $0 --dataset BEAR-B --policy CB --granularity day"
    echo ""
    echo "Options:"
    echo "  --dataset, -d      Dataset to use (BEAR-A, BEAR-B, or BEAR-C)"
    echo "  --policy, -p       Policy to use (CB, CBTB, IC, or TB)"
    echo "  --granularity, -g  Granularity for BEAR-B (day, hour, or instant)"
    echo "  --outdir           Override the default extracted directory location"
    echo "  --verbose, -v      Enable verbose output"
    exit 1
fi

# Construct INPUT_PATH based on arguments
if [ -n "$GRANULARITY" ]; then
    INPUT_PATH="$SCRIPT_DIR/$DATASET/datasets/$GRANULARITY-$POLICY"
else
    INPUT_PATH="$SCRIPT_DIR/$DATASET/datasets/$POLICY"
fi

log_verbose "Constructed input path: $INPUT_PATH"

# Get the directory and base name
DIR=$(dirname "$INPUT_PATH")
if [ -n "$GRANULARITY" ]; then
    BASE="$DATASET-$GRANULARITY-$POLICY"
else
    BASE="$DATASET-$POLICY"
fi

log_verbose "Directory: $DIR"
log_verbose "Base name: $BASE"

# Create extracted directory if it doesn't exist
if [ -n "$OUTDIR" ]; then
    EXTRACTED_DIR="$OUTDIR"
else
    EXTRACTED_DIR="$DIR/extracted"
fi
mkdir -p "$EXTRACTED_DIR"
log_verbose "Extract directory: $EXTRACTED_DIR"

# Check if extraction target already exists
if [ -d "$EXTRACTED_DIR/$BASE" ]; then
    log_info "Target directory $EXTRACTED_DIR/$BASE already exists. Skipping extraction."
    exit 0
elif compgen -G "$EXTRACTED_DIR/$BASE.*" > /dev/null; then
    log_info "Target file(s) matching $EXTRACTED_DIR/$BASE.* already exist. Skipping extraction."
    exit 0
fi

# Auto-detect the actual file by checking what exists
ACTUAL_FILE=""
TAR_GZ=false
if [ -f "${INPUT_PATH}.tar.gz" ]; then
    ACTUAL_FILE="${INPUT_PATH}.tar.gz"
    TAR_GZ=true
elif [ -f "${INPUT_PATH}.nq.gz" ]; then
    ACTUAL_FILE="${INPUT_PATH}.nq.gz"
    TARGET_EXT="nq"
elif [ -f "${INPUT_PATH}.nt.gz" ]; then
    ACTUAL_FILE="${INPUT_PATH}.nt.gz"
    TARGET_EXT="nt"
elif [ -f "${INPUT_PATH}.gz" ]; then
    ACTUAL_FILE="${INPUT_PATH}.gz"
else
    echo "Error: No compressed file found for ${INPUT_PATH}"
    echo "Tried: .tar.gz, .nq.gz, .nt.gz, .gz"
    exit 1
fi


# Check if file exists with .tar.gz extension
if [ "$TAR_GZ" = true ]; then
    log_info "Found ${ACTUAL_FILE} - extracting tar.gz archive..."

    # Create subdirectory for tar.gz contents
    TARGET_DIR="$EXTRACTED_DIR/$BASE"
    mkdir -p "$TARGET_DIR"
    log_verbose "Target directory: $TARGET_DIR"

    # Extract tar.gz to the target directory
    log_verbose "Extracting tar.gz to target directory..."
    tar -xzf "$ACTUAL_FILE" -C "$TARGET_DIR"
    log_info "Extracted to $TARGET_DIR"

    # Now extract all .gz files within the extracted directory
    log_info "Looking for .gz files to extract..."
    find "$TARGET_DIR" -name "*.gz" -type f | while read -r gz_file; do
        log_verbose "Extracting: $gz_file"
        # Get the directory of the gz file
        gz_dir=$(dirname "$gz_file")
        # Get the base name without .gz
        gz_base=$(basename "$gz_file" .gz)
        # Extract in place
        gunzip -c "$gz_file" > "$gz_dir/$gz_base"
        # Remove the .gz file after extraction
        rm "$gz_file"
        log_verbose "  -> $gz_dir/$gz_base"
    done

    log_info "Done extracting ${ACTUAL_FILE} and all nested .gz files"

# Check if file exists with .gz extension (but not .tar.gz)
else
    log_info "Found ${ACTUAL_FILE} - extracting gz file..."

    # Extract directly to extracted directory with name without .gz
    log_verbose "Extracting to: $EXTRACTED_DIR/$BASE.$TARGET_EXT"
    gunzip -c "${ACTUAL_FILE}" > "$EXTRACTED_DIR/$BASE.$TARGET_EXT"
    log_info "Extracted to $EXTRACTED_DIR/$BASE.$TARGET_EXT"
fi

log_info "Extraction complete!"

