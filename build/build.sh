#!/bin/bash

set -e

# Check for correct number of arguments
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <snapshot_name> <target_toit_file> <toit_version> <firmware_type>"
    echo "Example: $0 base-apps ./examples/containers/base-apps.toit v2.0.0-alpha.189 esp32c6"
    exit 1
fi

SNAPSHOT_NAME=$1
TARGET_FILE=$2
TOIT_VERSION=$3
FIRMWARE_TYPE=$4

# Define output directories
# Assuming script is run from project root, or we use relative paths for output
OUTPUT_BASE="build/out"
BUILD_DIR="${OUTPUT_BASE}/${SNAPSHOT_NAME}"

# Create output directory
mkdir -p "${BUILD_DIR}"

echo "Output directory: ${BUILD_DIR}"

# 1. Compile the snapshot
echo "----------------------------------------------------------------"
echo "Step 1: Compiling snapshot from ${TARGET_FILE}..."
echo "----------------------------------------------------------------"
SNAPSHOT_FILE="${BUILD_DIR}/${SNAPSHOT_NAME}.snapshot"
jag toit compile --snapshot -o "${SNAPSHOT_FILE}" -O 2 "$TARGET_FILE"

if [ $? -eq 0 ]; then
    echo "Snapshot created: ${SNAPSHOT_FILE}"
else
    echo "Failed to compile snapshot."
    exit 1
fi

# 2. Locate or Download the envelope
ENVELOPE_BASE_NAME="firmware-${FIRMWARE_TYPE}"
ENVELOPE_NAME="${ENVELOPE_BASE_NAME}.envelope"
ENVELOPE_GZ_NAME="${ENVELOPE_NAME}.gz"

# Check local cache first
# Linux cache path example: ~/.cache/jaguar/v2.0.0-alpha.189/envelopes/firmware-esp32c6.envelope
LOCAL_CACHE_PATH="$HOME/.cache/jaguar/${TOIT_VERSION}/envelopes/${ENVELOPE_NAME}"
DOWNLOAD_URL="https://github.com/toitlang/envelopes/releases/download/${TOIT_VERSION}/${ENVELOPE_GZ_NAME}"

# We need a path to the envelope file to use for the install command
SOURCE_ENVELOPE=""

echo ""
echo "----------------------------------------------------------------"
echo "Step 2: Preparing base firmware envelope..."
echo "----------------------------------------------------------------"

if [ -f "${LOCAL_CACHE_PATH}" ]; then
    echo "Found cached envelope at: ${LOCAL_CACHE_PATH}"
    SOURCE_ENVELOPE="${LOCAL_CACHE_PATH}"
else
    echo "Envelope not found in local cache: ${LOCAL_CACHE_PATH}"
    
    # Check if we already downloaded it in the build dir
    DOWNLOADED_ENVELOPE="${BUILD_DIR}/${ENVELOPE_NAME}"
    DOWNLOADED_ENVELOPE_GZ="${BUILD_DIR}/${ENVELOPE_GZ_NAME}"
    
    if [ -f "${DOWNLOADED_ENVELOPE}" ]; then
        echo "Using previously downloaded envelope in build dir: ${DOWNLOADED_ENVELOPE}"
        SOURCE_ENVELOPE="${DOWNLOADED_ENVELOPE}"
    else
        echo "Downloading envelope from ${DOWNLOAD_URL}..."
        if curl -L -f -o "${DOWNLOADED_ENVELOPE_GZ}" "${DOWNLOAD_URL}"; then
            echo "Download complete. Unzipping..."
            gunzip "${DOWNLOADED_ENVELOPE_GZ}"
            SOURCE_ENVELOPE="${DOWNLOADED_ENVELOPE}"
        else
            echo "Failed to download envelope. Please check the version and firmware type."
            exit 1
        fi
    fi
fi

# 3. Install container into envelope
OUTPUT_ENVELOPE="${BUILD_DIR}/${SNAPSHOT_NAME}.envelope"
CONTAINER_NAME="apps"

echo ""
echo "----------------------------------------------------------------"
echo "Step 3: Creating final envelope ${OUTPUT_ENVELOPE}..."
echo "----------------------------------------------------------------"
# Using 'apps' as the container name as per standard practice/example
jag toit tool firmware -e "${SOURCE_ENVELOPE}" container install -o "${OUTPUT_ENVELOPE}" "${CONTAINER_NAME}" "${SNAPSHOT_FILE}"

if [ $? -ne 0 ]; then
    echo "Failed to create envelope."
    exit 1
fi

# 4. Extract binary image from the generated envelope
BIN_FILE="${BUILD_DIR}/${SNAPSHOT_NAME}.image.bin"
echo ""
echo "----------------------------------------------------------------"
echo "Step 4: Extracting binary image ${BIN_FILE}..."
echo "----------------------------------------------------------------"
jag toit tool firmware --envelope "${OUTPUT_ENVELOPE}" extract --format=image -o "${BIN_FILE}"

if [ $? -ne 0 ]; then
    echo "Failed to extract binary image from envelope."
    exit 1
fi

echo ""
echo "Success!"
echo "Generated files in ${BUILD_DIR}:"
echo "  1. Snapshot: ${SNAPSHOT_NAME}.snapshot"
echo "  2. Envelope: ${SNAPSHOT_NAME}.envelope"
echo "  3. Image: ${SNAPSHOT_NAME}.image.bin"
