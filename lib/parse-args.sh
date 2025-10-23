#!/bin/bash

# lib/parse-args.sh
# Argument parsing and validation for BEAR benchmark experiments

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print usage
usage() {
    echo "Usage: $0 -d|--dataset <dataset> -p|--policy <policy> -t|--tool <tool> [-g|--granularity <granularity>] [-c|--clear] [-v|--verbose] [--tag <tag>]"
    echo ""
    echo "Required Arguments:"
    echo "  -d, --dataset <value>   : BEAR-A | BEAR-B | BEAR-C"
    echo "  -p, --policy <value>    : IC | CB | TB | CBTB"
    echo "  -t, --tool <value>      : jena-tdb-2 | rdf-hdt | conver-g"
    echo ""
    echo "Conditional Arguments:"
    echo "  -g, --granularity <value> : day | hour | instant (required for BEAR-B, not allowed for BEAR-A and BEAR-C)"
    echo ""
    echo "Optional Arguments:"
    echo "  -c, --clear             : Clear previous data (default: false)"
    echo "  -v, --verbose           : Enable verbose output (default: false)"
    echo "  --tag <value>           : Custom tag for this experiment run (default: username)"
    echo "  -h, --help              : Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -d BEAR-A -p IC -t jena-tdb-2"
    echo "  $0 --dataset BEAR-A --policy IC --tool jena-tdb-2 --clear --verbose"
    echo "  $0 -d BEAR-B -g day -p CBTB -t rdf-hdt -c -v --tag experiment-1"
    echo "  $0 -d BEAR-C -p TB -t conver-g --tag baseline"
}

# Function to print error messages
error_with_usage() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    usage
    exit 1
}

# Function to validate dataset
validate_dataset() {
    local dataset=$1
    case "$dataset" in
        BEAR-A|BEAR-B|BEAR-C)
            return 0
            ;;
        *)
            error_with_usage "Invalid dataset: $dataset. Must be one of: BEAR-A, BEAR-B, BEAR-C"
            ;;
    esac
}

# Function to validate policy
validate_policy() {
    local policy=$1
    case "$policy" in
        IC|CB|TB|CBTB)
            return 0
            ;;
        *)
            error_with_usage "Invalid policy: $policy. Must be one of: IC, CB, TB, CBTB"
            ;;
    esac
}

# Function to validate tool
validate_tool() {
    local tool=$1
    case "$tool" in
        jena-tdb-2|rdf-hdt|conver-g)
            return 0
            ;;
        *)
            error_with_usage "Invalid tool: $tool. Must be one of: jena-tdb-2, rdf-hdt, conver-g"
            ;;
    esac
}

# Function to validate granularity
validate_granularity() {
    local granularity=$1
    case "$granularity" in
        day|hour|instant)
            return 0
            ;;
        *)
            error_with_usage "Invalid granularity: $granularity. Must be one of: day, hour, instant"
            ;;
    esac
}

# Function to parse and validate arguments
parse_and_validate_args() {
    # Default values for optional arguments
    CLEAR=false
    TAG="$(whoami)"
    VERBOSE=false

    # Initialize required arguments as empty
    DATASET=""
    POLICY=""
    TOOL=""
    GRANULARITY=""

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dataset)
                DATASET="$2"
                shift 2
                ;;
            -p|--policy)
                POLICY="$2"
                shift 2
                ;;
            -t|--tool)
                TOOL="$2"
                shift 2
                ;;
            -g|--granularity)
                GRANULARITY="$2"
                shift 2
                ;;
            -c|--clear)
                CLEAR=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --tag)
                TAG="$2"
                shift 2

                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                error_with_usage "Unknown option: $1"
                ;;
        esac
    done

    # Check if required arguments are provided
    if [ -z "$DATASET" ]; then
        error_with_usage "Dataset argument is required (-d|--dataset)"
    fi

    if [ -z "$POLICY" ]; then
        error_with_usage "Policy argument is required (-p|--policy)"
    fi

    if [ -z "$TOOL" ]; then
        error_with_usage "Tool argument is required (-t|--tool)"
    fi

    # Validate arguments
    validate_dataset "$DATASET"
    validate_policy "$POLICY"
    validate_tool "$TOOL"

    # Validate granularity based on dataset
    if [ "$DATASET" = "BEAR-B" ]; then
        if [ -z "$GRANULARITY" ]; then
            error_with_usage "Granularity argument is required for BEAR-B dataset (-g|--granularity)"
        fi
        validate_granularity "$GRANULARITY"
    else
        # BEAR-A or BEAR-C
        if [ -n "$GRANULARITY" ]; then
            error_with_usage "Granularity argument is not allowed for $DATASET dataset"
        fi
    fi

    # Export variables for use in calling script
    export BEAR_TAG="$TAG"
    export BEAR_DATASET="$DATASET"
    export BEAR_POLICY="$POLICY"
    export BEAR_TOOL="$TOOL"
    export BEAR_GRANULARITY="$GRANULARITY"
    export BEAR_CLEAR="$CLEAR"
    export BEAR_VERBOSE="$VERBOSE"
}

