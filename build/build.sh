#!/bin/bash

set -e

# Detect toit command - use 'toit' if available, otherwise fall back to 'jag toit'
if command -v toit &> /dev/null; then
    TOIT_CMD="toit"
elif command -v jag &> /dev/null; then
    TOIT_CMD="jag toit"
else
    echo "Error: Neither 'toit' nor 'jag' command found."
    echo "Please install Toit SDK or Jaguar CLI."
    exit 1
fi

# Check for correct number of arguments
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <snapshot_name> <target_toit_file> <toit_version> <firmware_type>"
    echo "Example: $0 base-apps ./examples/containers/base-apps.toit v2.0.0-alpha.190 esp32c6"
    echo ""
    echo "Optional environment overrides (highest precedence first):"
    echo "  LIGHTBUG_ENVELOPE_FILE=/absolute/path/to/firmware.envelope"
    echo "  LIGHTBUG_ENVELOPE_URL=https://.../firmware.envelope"
    echo "  LIGHTBUG_ENVELOPE_VERSION=lb.20260225-1"
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
echo "Using command: ${TOIT_CMD}"
echo "----------------------------------------------------------------"
SNAPSHOT_FILE="${BUILD_DIR}/${SNAPSHOT_NAME}.snapshot"
${TOIT_CMD} compile --snapshot -o "${SNAPSHOT_FILE}" -O 2 "$TARGET_FILE"

if [ $? -eq 0 ]; then
    echo "Snapshot created: ${SNAPSHOT_FILE}"
else
    echo "Failed to compile snapshot."
    exit 1
fi

# 2. Locate or Download the envelope
ENVELOPE_NAME="${FIRMWARE_TYPE}-single-ota.envelope"
DOWNLOAD_URL=""
ENVELOPE_CACHE_DIR="build/cache/envelopes"
CUSTOM_ENVELOPE_FILE="${LIGHTBUG_ENVELOPE_FILE}"

if [ -n "${CUSTOM_ENVELOPE_FILE}" ]; then
    echo "Using LIGHTBUG_ENVELOPE_FILE override."
    if [ ! -f "${CUSTOM_ENVELOPE_FILE}" ]; then
        echo "LIGHTBUG_ENVELOPE_FILE does not exist: ${CUSTOM_ENVELOPE_FILE}"
        exit 1
    fi
    SOURCE_ENVELOPE="${CUSTOM_ENVELOPE_FILE}"
    ENVELOPE_NAME="$(basename "${CUSTOM_ENVELOPE_FILE}")"
elif [ -n "${LIGHTBUG_ENVELOPE_URL}" ]; then
    echo "Using LIGHTBUG_ENVELOPE_URL override."
    DOWNLOAD_URL="${LIGHTBUG_ENVELOPE_URL}"
    ENVELOPE_NAME="$(basename "${LIGHTBUG_ENVELOPE_URL}")"
else
    if [ -z "${LIGHTBUG_ENVELOPE_VERSION}" ]; then
        echo "LIGHTBUG_ENVELOPE_VERSION is not set. Please set this environment variable to the desired Lightbug envelope release."
        exit 1
    fi

    ENVELOPE_RELEASE_TAG="${TOIT_VERSION}.${LIGHTBUG_ENVELOPE_VERSION}"
    DOWNLOAD_URL="https://github.com/lightbug-io/toit-envelopes/releases/download/${ENVELOPE_RELEASE_TAG}/${ENVELOPE_NAME}"
fi

if [ -z "${SOURCE_ENVELOPE}" ]; then
    SOURCE_ENVELOPE=""
fi

echo ""
echo "----------------------------------------------------------------"
echo "Step 2: Preparing Lightbug firmware envelope (${ENVELOPE_NAME})..."
if [ -n "${CUSTOM_ENVELOPE_FILE}" ]; then
    echo "Source file: ${CUSTOM_ENVELOPE_FILE}"
elif [ -n "${LIGHTBUG_ENVELOPE_URL}" ]; then
    echo "Source URL: ${LIGHTBUG_ENVELOPE_URL}"
else
    echo "Release: ${ENVELOPE_RELEASE_TAG}"
fi
echo "----------------------------------------------------------------"

if [ -z "${SOURCE_ENVELOPE}" ]; then
    mkdir -p "${ENVELOPE_CACHE_DIR}"
    SOURCE_ENVELOPE_PATH="${ENVELOPE_CACHE_DIR}/${ENVELOPE_NAME}"

    if [ -f "${SOURCE_ENVELOPE_PATH}" ]; then
        echo "Using cached envelope in build directory: ${SOURCE_ENVELOPE_PATH}"
        SOURCE_ENVELOPE="${SOURCE_ENVELOPE_PATH}"
    else
        echo "Downloading envelope from ${DOWNLOAD_URL}..."
        if curl -L -f -o "${SOURCE_ENVELOPE_PATH}" "${DOWNLOAD_URL}"; then
            echo "Download complete: ${SOURCE_ENVELOPE_PATH}"
            SOURCE_ENVELOPE="${SOURCE_ENVELOPE_PATH}"
        else
            echo "Failed to download envelope from ${DOWNLOAD_URL}. Please verify the versions and firmware type."
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
${TOIT_CMD} tool firmware -e "${SOURCE_ENVELOPE}" container install -o "${OUTPUT_ENVELOPE}" "${CONTAINER_NAME}" "${SNAPSHOT_FILE}"

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
${TOIT_CMD} tool firmware --envelope "${OUTPUT_ENVELOPE}" extract --format=image -o "${BIN_FILE}"

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
