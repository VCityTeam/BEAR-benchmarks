#!/bin/bash

# run-experiment.sh
# Script to run BEAR benchmark experiments with different datasets, policies, and tools

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() {
    echo -e "${YELLOW}$1${NC}"
}

success() {
    echo -e "${GREEN}$1${NC}"
    echo ""
}

error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source the argument parsing library
source "$SCRIPT_DIR/lib/parse-args.sh"

# Parse and validate arguments
parse_and_validate_args "$@"

success "Arguments validated successfully!"

# Get validated values from exported variables
DATASET="$BEAR_DATASET"
POLICY="$BEAR_POLICY"
TOOL="$BEAR_TOOL"
GRANULARITY="$BEAR_GRANULARITY"
CLEAR="$BEAR_CLEAR"
VERBOSE="$BEAR_VERBOSE"

echo ""
info "==================================="
info "BEAR Benchmark Experiment"
info "==================================="
echo "Dataset:  $DATASET"
if [ -n "$GRANULARITY" ]; then
    echo "Granularity: $GRANULARITY"
fi
echo "Policy:   $POLICY"
echo "Tool:     $TOOL"
echo "Clear:    $CLEAR"
echo "Verbose:  $VERBOSE"
info "==================================="
echo ""

if [ "$VERBOSE" = "true" ]; then
    VERBOSE_FLAG="--verbose"
fi

if [ -n "$GRANULARITY" ]; then
    GRANULARITY_FLAG="--granularity $GRANULARITY"
fi

info "Starting experiment..."

# Clear experiment folder if requested
if [ "$CLEAR" = "true" ]; then
    EXPERIMENT_DIR="$SCRIPT_DIR/experiment"
    if [ -d "$EXPERIMENT_DIR" ]; then
        info "Clearing experiment folder..."
        rm -rf "$EXPERIMENT_DIR"
        success "Experiment folder cleared successfully!"
    else
        info "Experiment folder does not exist, skipping clear."
    fi
fi

info "Downloading inputs from BEAR..."
if "$SCRIPT_DIR/bear-inputs/download-all.sh" -d "$DATASET" $VERBOSE_FLAG; then
    success "Dataset files downloaded successfully!"
else
    error "Failed to download dataset files"
fi

info "Extracting dataset..."
OUTPUT_DIR="$SCRIPT_DIR/experiment/datasets"
if $SCRIPT_DIR/bear-inputs/extract.sh --dataset "$DATASET" --policy "$POLICY" --outdir "$OUTPUT_DIR" $GRANULARITY_FLAG $VERBOSE_FLAG; then
    success "Dataset extracted successfully to $OUTPUT_DIR"
else
    error "Failed to extract dataset"
fi

if [ -n "$GRANULARITY" ]; then
    DATASET_FULL_NAME="$DATASET-$GRANULARITY-$POLICY"
else
    DATASET_FULL_NAME="$DATASET-$POLICY"
fi

info "Loading dataset..."
cd $TOOL
if $SCRIPT_DIR/$TOOL/load.sh "$DATASET_FULL_NAME"; then
    success "Dataset $DATASET_FULL_NAME loaded successfully to $TOOL"
else
    error "Failed to load dataset $DATASET_FULL_NAME"
fi
cd ..

info "Preparing queries..."
if $SCRIPT_DIR/$TOOL/prepare-queries.sh "$DATASET"; then
    success "Queries for $DATASET prepared successfully!"
else
    error "Failed to prepare queries for $DATASET"
fi

info "Note: Additional experiment execution logic to be implemented."

