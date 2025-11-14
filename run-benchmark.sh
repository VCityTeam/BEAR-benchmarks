#!/bin/bash

# run-benchmark.sh
# Wrapper script to run the BEAR benchmark across all supported tools

set -e

# Color output (same palette as run-experiment.sh)
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

info() {
    echo -e "${YELLOW}$1${NC}"
}

success() {
    echo -e "${GREEN}$1${NC}"
}

error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RUN_EXPERIMENT_SCRIPT="$SCRIPT_DIR/run-experiment.sh"

if [ ! -x "$RUN_EXPERIMENT_SCRIPT" ]; then
    error "run-experiment.sh not found or not executable at $RUN_EXPERIMENT_SCRIPT"
fi

# Disallow passing an explicit tool; the script handles all supported tools automatically.
for arg in "$@"; do
    case "$arg" in
        -t|--tool)
            error "Do not pass the tool argument to run-benchmark.sh; it runs all tools automatically."
            ;;
    esac
done

declare -a TOOLS=(
    "jena-tdb-2"
    "conver-g-flat"
    "conver-g"
)

for tool in "${TOOLS[@]}"; do
    info "==================================="
    info "Running BEAR benchmark for tool: $tool"
    info "==================================="
    echo ""

    "$RUN_EXPERIMENT_SCRIPT" "$@" --tool "$tool"

    echo ""
    success "Completed benchmark for tool: $tool"
    echo ""
done

success "All benchmarks completed successfully!"
