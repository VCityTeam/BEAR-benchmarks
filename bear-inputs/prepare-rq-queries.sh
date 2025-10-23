#!/bin/bash

# Script to split raw query files into individual SPARQL query files
# Usage: ./split-queries.sh DATASET_NAME [--force|-f]
# Example: ./split-queries.sh BEAR-A
# Example: ./split-queries.sh BEAR-A --force


set -e

FORCE_MODE=false
DATASET=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force|-f)
            FORCE_MODE=true
            shift
            ;;
        -*)
            echo "Error: Unknown option $1"
            echo "Usage: $0 DATASET_NAME [--force|-f]"
            echo "Example: $0 BEAR-A"
            echo "Example: $0 BEAR-A --force"
            exit 1
            ;;
        *)
            if [ -z "$DATASET" ]; then
                DATASET=$1
            else
                echo "Error: Multiple dataset names provided"
                echo "Usage: $0 DATASET_NAME [--force|-f]"
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if dataset name is provided
if [ -z "$DATASET" ]; then
    echo "Error: Dataset name is required"
    echo "Usage: $0 DATASET_NAME [--force|-f]"
    echo "Use '--force' or '-f' argument to overwrite:"
    echo "  $0 $DATASET --force"
    exit 1
fi


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAW_DIR="${SCRIPT_DIR}/${DATASET}/queries/raw"
OUTPUT_DIR="${SCRIPT_DIR}/${DATASET}/queries/rq"


# Check if raw directory exists
if [ ! -d "$RAW_DIR" ]; then
    echo "Error: Raw queries directory not found: $RAW_DIR"
    exit 1
fi

# Check if output directory already exists and has files
if [ -d "$OUTPUT_DIR" ] && [ "$(ls -A "$OUTPUT_DIR" 2>/dev/null)" ]; then
    if [ "$FORCE_MODE" = true ]; then
        echo "Force mode enabled: Emptying output directory"
        rm -rf "${OUTPUT_DIR:?}"/*
    else
        echo "$OUTPUT_DIR already exists and is not empty. Skipping processing. (use 'force' to overwrite)"
        exit 0
    fi
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "Processing queries for dataset: $DATASET"
echo "Raw directory: $RAW_DIR"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Special handling for BEAR-C: add SELECT * WHERE before opening brace
if [ "$DATASET" = "BEAR-C" ]; then
    echo "BEAR-C detected: processing raw .txt files to .rq files with SELECT * WHERE"
    for raw_file in "$RAW_DIR"/*.txt; do
        # Skip if no .txt files found
        [ -e "$raw_file" ] || continue

        # Get the base filename without extension
        base_name=$(basename "$raw_file" .txt)

        # Create output filename
        output_file="${OUTPUT_DIR}/${base_name}.rq"

        # Process file: add SELECT * WHERE and GRAPH ?g at the line with first opening brace
        awk '{
            if (!found && /^[[:space:]]*\{[[:space:]]*$/) {
                print "SELECT * WHERE {"
                print "  GRAPH ?g {"
                found = 1
                brace_depth = 1
            } else if (found && !closed) {
                # Count braces to track depth
                line = $0
                for (i = 1; i <= length(line); i++) {
                    char = substr(line, i, 1)
                    if (char == "{") brace_depth++
                    if (char == "}") brace_depth--
                }

                # Print with indentation while inside the graph block
                print "  " $0

                # When we reach depth 0, close the GRAPH block
                if (brace_depth == 0) {
                    print "  }"
                    closed = 1
                }
            } else {
                print
            }
        }' "$raw_file" > "$output_file"

        echo "  Processed: ${base_name}.txt -> ${base_name}.rq"
    done
    echo ""
    echo "Done! All query files have been processed to: $OUTPUT_DIR"
    exit 0
fi

# Special handling for BEAR-B joins folder
if [ "$DATASET" = "BEAR-B" ]; then
    JOINS_DIR="${RAW_DIR}/joins"
    if [ -d "$JOINS_DIR" ]; then
        echo "BEAR-B joins detected: processing join queries"
        for join_file in "$JOINS_DIR"/*.txt; do
            # Skip if no .txt files found
            [ -e "$join_file" ] || continue

            # Get the base filename without extension
            base_name=$(basename "$join_file" .txt)

            # Create output filename with .rq extension
            output_file="${OUTPUT_DIR}/${base_name}.rq"

            # Write SPARQL query to file: add SELECT * WHERE at the beginning
            # Strip the outer braces from the join file and extract just the triple patterns
            echo "SELECT * WHERE {" > "$output_file"
            echo "  GRAPH ?g {" >> "$output_file"
            # Remove lines with only braces and whitespace, then indent the content
            sed '/^[[:space:]]*{[[:space:]]*$/d; /^[[:space:]]*}[[:space:]]*$/d; s/^/    /' "$join_file" >> "$output_file"
            echo "  }" >> "$output_file"
            echo "}" >> "$output_file"

            echo "  Processed: ${base_name}.txt -> ${base_name}.rq"
        done
        echo ""
    fi
fi

# Process each .txt file in the raw directory
for raw_file in "$RAW_DIR"/*.txt; do
    # Skip if no .txt files found
    [ -e "$raw_file" ] || continue

    # Get the base filename without extension
    base_name=$(basename "$raw_file" .txt)

    echo "Processing: $base_name.txt"

    # Initialize counter
    counter=1

    # Read file line by line
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines
        if [ -z "$line" ] || [ -z "$(echo "$line" | tr -d '[:space:]')" ]; then
            continue
        fi

        # Create output filename
        output_file="${OUTPUT_DIR}/${base_name}-${counter}.rq"

        # Write SPARQL query to file
        echo "SELECT * WHERE {" > "$output_file"
        echo "  GRAPH ?g {" >> "$output_file"
        echo "    $line" >> "$output_file"
        echo "  }" >> "$output_file"
        echo "}" >> "$output_file"

        counter=$((counter + 1))
    done < "$raw_file"

    echo "  Created $((counter - 1)) query files"
done

echo ""
echo "Done! All queries have been split into individual .rq files in: $OUTPUT_DIR"

