#!/bin/bash

# Script to download a file from locked-sources.json and verify its hash
# Usage: ./download-and-verify.sh <path> [--force|-f] [--verbose|-v]

set -e

# Parse arguments
FORCE_DOWNLOAD=false
VERBOSE=false
PATH_KEY=""

for arg in "$@"; do
    case $arg in
        --force|-f)
            FORCE_DOWNLOAD=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        *)
            if [ -z "$PATH_KEY" ]; then
                PATH_KEY="$arg"
            fi
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

# Check if path argument is provided
if [ -z "$PATH_KEY" ]; then
    echo "Error: Path argument is required"
    echo "Usage: $0 <path> [--force|-f] [--verbose|-v]"
    exit 1
fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCKED_SOURCES="$SCRIPT_DIR/locked-sources.json"

# Check if locked-sources.json exists
if [ ! -f "$LOCKED_SOURCES" ]; then
    echo "Error: locked-sources.json not found at $LOCKED_SOURCES"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed"
    exit 1
fi

# Extract URL and hash from locked-sources.json
URL=$(jq -r --arg key "$PATH_KEY" '.[$key].url // empty' "$LOCKED_SOURCES")
EXPECTED_HASH=$(jq -r --arg key "$PATH_KEY" '.[$key].hash // empty' "$LOCKED_SOURCES")

if [ -z "$URL" ]; then
    echo "Error: No URL found for path '$PATH_KEY' in locked-sources.json"
    exit 1
fi

log_info "Processing: $PATH_KEY"
log_verbose "URL: $URL"

# Extract URL filename and determine archive type
URL_BASENAME=$(basename "$URL")
IS_ARCHIVE=false
ARCHIVE_TYPE=""
EXTENSION="${URL_BASENAME##*.}"
UNARCHIVE=false # tar.gz and gz files are not unarchived by default because they are too heavy

if [[ "$URL_BASENAME" == *.tar.gz ]]; then
    IS_ARCHIVE=true
    ARCHIVE_TYPE="tar.gz"
    EXTENSION="tar.gz"
elif [[ "$URL_BASENAME" == *.gz ]]; then
    IS_ARCHIVE=true
    ARCHIVE_TYPE="gz"
    # Extract the extension before .gz (e.g., txt.gz from file.txt.gz)
    BASENAME_WITHOUT_GZ="${URL_BASENAME%.gz}"
    INNER_EXT="${BASENAME_WITHOUT_GZ##*.}"
    EXTENSION="${INNER_EXT}.gz"
elif [[ "$URL_BASENAME" == *.zip ]]; then
    IS_ARCHIVE=true
    ARCHIVE_TYPE="zip"
    UNARCHIVE=true # Always unarchive zip files
fi

# Determine download path (always with archive extension during download)
  if [[ "$URL_BASENAME" == *.* ]]; then
      DOWNLOAD_PATH="$SCRIPT_DIR/${PATH_KEY}.${EXTENSION}"
  else
      DOWNLOAD_PATH="$SCRIPT_DIR/$PATH_KEY"
  fi

log_verbose "Download path: $DOWNLOAD_PATH"

# Check if file/extracted content already exists
SKIP_DOWNLOAD=false
EXTRACT_DIR="$SCRIPT_DIR/$(dirname "$PATH_KEY")"

if [ "$FORCE_DOWNLOAD" = false ]; then
    if [ "$UNARCHIVE" = true ]; then
        # For archives, check if extracted content exists
        if [ -d "$EXTRACT_DIR" ] && [ "$(ls -A $SCRIPT_DIR/$PATH_KEY 2>/dev/null)" ]; then
            log_verbose "Extracted content $PATH_KEY already exists in: $EXTRACT_DIR"
            SKIP_DOWNLOAD=true
        fi
    else
        # For non-archives, check if final file exists
        if [ -f "$DOWNLOAD_PATH" ]; then
            log_verbose "File already exists: $DOWNLOAD_PATH"
            SKIP_DOWNLOAD=true
        fi
    fi

    if [ "$SKIP_DOWNLOAD" = true ]; then
        log_info "✓ $PATH_KEY (already exists, skipped)"
        log_verbose "Use --force or -f to force refresh"
        exit 0
    fi
fi

if [ "$FORCE_DOWNLOAD" = true ]; then
    log_verbose "Force download enabled - will refresh files"
fi

# Create directory if it doesn't exist
DIR=$(dirname "$DOWNLOAD_PATH")
if [ ! -d "$DIR" ]; then
    log_verbose "Creating directory: $DIR"
    mkdir -p "$DIR"
fi

# Download the file
log_info "Downloading $URL ..."
if ! curl -L -f -o "$DOWNLOAD_PATH" "$URL"; then
    echo "Error: Failed to download file from $URL"
    exit 1
fi

# Compute SHA256 hash of downloaded file
log_verbose "Computing hash..."
COMPUTED_HASH=$(shasum -a 256 "$DOWNLOAD_PATH" | awk '{print $1}')
log_verbose "Computed hash: $COMPUTED_HASH"

# Check if expected hash is empty
if [ -z "$EXPECTED_HASH" ] || [ "$EXPECTED_HASH" = "null" ]; then
    log_verbose "No hash found in locked-sources.json. Updating..."
    # Update the hash in locked-sources.json
    jq --arg key "$PATH_KEY" --arg hash "$COMPUTED_HASH" \
        '.[$key].hash = $hash' "$LOCKED_SOURCES" > "$LOCKED_SOURCES.tmp" && \
        mv "$LOCKED_SOURCES.tmp" "$LOCKED_SOURCES"
    log_info "Hash updated in locked-sources.json"
else
    log_verbose "Expected hash: $EXPECTED_HASH"
    # Compare hashes
    if [ "$COMPUTED_HASH" != "$EXPECTED_HASH" ]; then
        echo "Error: Hash mismatch!"
        echo "Expected: $EXPECTED_HASH"
        echo "Computed: $COMPUTED_HASH"
        rm "$DOWNLOAD_PATH"
        echo "Removed $DOWNLOAD_PATH"
        exit 1
    fi
    log_verbose "Hash verification successful!"
fi

# Handle archives: extract and determine final path
if [ "$UNARCHIVE" = true ]; then
    log_info "Extracting..."

    if [[ "$ARCHIVE_TYPE" == "tar.gz" ]]; then
        # List contents to determine if it's a folder or file
        CONTENTS=$(tar -tzf "$DOWNLOAD_PATH" | head -1)

        # Check if first entry is a directory (ends with /)
        if [[ "$CONTENTS" == */ ]]; then
            log_verbose "Archive contains a folder - extracting without extension"
            tar -xzf "$DOWNLOAD_PATH" -C "$SCRIPT_DIR/$PATH_KEY"
            log_verbose "Extracted to: $SCRIPT_DIR/$PATH_KEY"
        else
            # Archive contains file(s)
            log_verbose "Archive contains files - extracting"
            tar -xzf "$DOWNLOAD_PATH" -C "$EXTRACT_DIR"
            log_verbose "Extracted to: $EXTRACT_DIR"
        fi
    elif [[ "$ARCHIVE_TYPE" == "gz" ]]; then
        # .gz files contain a single file - extract with proper extension
        log_verbose "Extracting .gz file..."
        # Get the filename from the archive (remove .gz extension from URL basename)
        UNCOMPRESSED_NAME="${URL_BASENAME%.gz}"
        EXTENSION="${UNCOMPRESSED_NAME##*.}"

        # Extract to temporary location
        gunzip -c "$DOWNLOAD_PATH" > "$SCRIPT_DIR/${PATH_KEY}.${EXTENSION}"

    elif [[ "$ARCHIVE_TYPE" == "zip" ]]; then
        # List contents to determine if it's a folder or file
        FIRST_ENTRY=$(unzip -l "$DOWNLOAD_PATH" | awk 'NR==4 {print $4}')
        FILE_COUNT=$(unzip -l "$DOWNLOAD_PATH" | grep -c "^  *[0-9]" || echo "0")

        if [[ "$FIRST_ENTRY" == */* ]]; then
            log_verbose "Archive contains files with directory structure"
            # Extract to temporary directory
            TEMP_EXTRACT="$SCRIPT_DIR/${PATH_KEY}.tmp"
            mkdir -p "$TEMP_EXTRACT"
            unzip -q "$DOWNLOAD_PATH" -d "$TEMP_EXTRACT"

            # Create target directory
            mkdir -p "$SCRIPT_DIR/$PATH_KEY"

            # Move all files to target, flattening directory structure
            find "$TEMP_EXTRACT" -type f -exec mv {} "$SCRIPT_DIR/$PATH_KEY/" \;

            # Clean up temp directory
            rm -rf "$TEMP_EXTRACT"
            log_verbose "Extracted and flattened to: $SCRIPT_DIR/$PATH_KEY"
        else
            # Archive contains file(s) at root - check if single file or multiple
            if [ "$FILE_COUNT" -eq 1 ]; then
                # Single file - extract with proper extension
                EXTENSION="${FIRST_ENTRY##*.}"
                unzip -p "$DOWNLOAD_PATH" > "$SCRIPT_DIR/${PATH_KEY}.${EXTENSION}"
                log_verbose "Extracted to: $SCRIPT_DIR/${PATH_KEY}.${EXTENSION}"
            else
                log_verbose "Archive contains multiple files - extract to directory"
                # Multiple files - extract to directory
                mkdir -p "$SCRIPT_DIR/$PATH_KEY"
                unzip -q "$DOWNLOAD_PATH" -d "$SCRIPT_DIR/$PATH_KEY"
                log_verbose "Extracted to: $SCRIPT_DIR/$PATH_KEY"
            fi
        fi
    fi

    rm "$DOWNLOAD_PATH"
    log_verbose "Removed archive: $DOWNLOAD_PATH"
    log_info "✓ $PATH_KEY"
else
    # Non-archive file - already at final destination
    log_info "✓ $DOWNLOAD_PATH"
fi

