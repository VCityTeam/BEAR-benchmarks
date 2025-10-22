#!/bin/bash

# Script to download and verify all files from locked-sources.json
# Usage: ./download-all.sh [--force|-f] [--verbose|-v] [--dataset|-d BEAR-A|BEAR-B|BEAR-C]

set -e

# Parse arguments
FORCE_FLAG=""
VERBOSE_FLAG=""
DATASET_FILTER=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --force|-f)
            FORCE_FLAG="--force"
            echo "Force mode enabled - will refresh all files"
            echo ""
            shift
            ;;
        --verbose|-v)
            VERBOSE_FLAG="--verbose"
            echo "Verbose mode enabled - will show detailed logs"
            echo ""
            shift
            ;;
        --dataset|-d)
            DATASET_FILTER="$2"
            case "$DATASET_FILTER" in
                BEAR-A|BEAR-B|BEAR-C)
                    echo "Dataset filter enabled - downloading only $DATASET_FILTER files"
                    echo ""
                    ;;
                *)
                    echo "Error: Invalid dataset '$DATASET_FILTER'. Must be one of: BEAR-A, BEAR-B, BEAR-C"
                    exit 1
                    ;;
            esac
            shift 2
            ;;
        *)
            echo "Error: Unknown option: $1"
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCKED_SOURCES="$SCRIPT_DIR/locked-sources.json"
DOWNLOAD_SCRIPT="$SCRIPT_DIR/download-and-verify.sh"

# Check if locked-sources.json exists
if [ ! -f "$LOCKED_SOURCES" ]; then
    echo "Error: locked-sources.json not found at $LOCKED_SOURCES"
    exit 1
fi

# Check if download-and-verify.sh exists
if [ ! -f "$DOWNLOAD_SCRIPT" ]; then
    echo "Error: download-and-verify.sh not found at $DOWNLOAD_SCRIPT"
    exit 1
fi

# Make sure download-and-verify.sh is executable
chmod +x "$DOWNLOAD_SCRIPT"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed"
    echo "Install with: brew install jq"
    exit 1
fi

# Get all paths from locked-sources.json, optionally filtered by dataset
if [ -n "$DATASET_FILTER" ]; then
    PATHS=$(jq -r 'keys[] | select(startswith("'"$DATASET_FILTER"'/"))' "$LOCKED_SOURCES")
else
    PATHS=$(jq -r 'keys[]' "$LOCKED_SOURCES")
fi

# Count total files
TOTAL=$(echo "$PATHS" | wc -l | tr -d ' ')
CURRENT=0
FAILED=0

echo "=========================================="
echo "Starting download of $TOTAL files"
echo "=========================================="
echo ""

# Iterate over each path
while IFS= read -r path; do
    CURRENT=$((CURRENT + 1))

    # Capture output from download script
    if OUTPUT=$("$DOWNLOAD_SCRIPT" "$path" $FORCE_FLAG $VERBOSE_FLAG 2>&1); then
        # Only show the final status line (the one with ✓)
        STATUS_LINE=$(echo "$OUTPUT" | grep "^✓" | tail -1)
        echo "[$CURRENT/$TOTAL] $STATUS_LINE"
    else
        echo "[$CURRENT/$TOTAL] ✗ Failed: $path"
        FAILED=$((FAILED + 1))
    fi
done <<< "$PATHS"

echo "=========================================="
echo "Download complete!"
echo "Total: $TOTAL"
echo "Success: $((TOTAL - FAILED))"
echo "Failed: $FAILED"
echo "=========================================="

if [ $FAILED -gt 0 ]; then
    exit 1
fi

