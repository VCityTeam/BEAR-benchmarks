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

info "Experiment configuration ready."

# TODO: Add experiment execution logic here
info "Starting experiment..."

# Placeholder for actual experiment execution
# This is where you would call the appropriate tool-specific scripts
# based on the validated parameters

echo ""
info "Note: Experiment execution logic to be implemented."

