#!/bin/bash

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <image_file> <com_port>"
    echo "Example: $0 build/out/base-apps/base-apps.image.bin COM21"
    exit 1
fi

IMAGE_FILE=$1
COM_PORT=$2

# Check if file exists in WSL
if [ ! -f "$IMAGE_FILE" ]; then
    echo "Error: Image file '$IMAGE_FILE' not found."
    exit 1
fi

# Resolve absolute path
ABS_WSL_PATH=$(readlink -f "$IMAGE_FILE")

# Convert to Windows path
if command -v wslpath &> /dev/null; then
    WIN_IMAGE_PATH=$(wslpath -w "$ABS_WSL_PATH")
else
    echo "Error: wslpath not found. Are you running in WSL?"
    exit 1
fi

echo "----------------------------------------------------------------"
echo "Flashing Image Binary"
echo "----------------------------------------------------------------"
echo "Image (WSL): $ABS_WSL_PATH"
echo "Image (Win): $WIN_IMAGE_PATH"
echo "Port:        $COM_PORT"
echo "----------------------------------------------------------------"

# Check if jag.exe is available
if ! command -v jag.exe &> /dev/null; then
    echo "Error: jag.exe not found in PATH."
    exit 1
fi

# Get esptool command from jag
# We use a dummy envelope or 'ignored' as the envelope argument is required but seemingly ignored for this command
# We capture the output and parse the 'Command: [...]' line
ESPTOOL_INFO=$(jag.exe toit tool firmware tool esptool -e ignored 2>&1)
ESPTOOL_CMD_RAW=$(echo "$ESPTOOL_INFO" | grep "Command:" | sed 's/Command: \[\(.*\)\]/\1/' | tr -d '\r')

if [ -z "$ESPTOOL_CMD_RAW" ]; then
    echo "Error: Could not determine esptool command from jag.exe"
    echo "jag output:"
    echo "$ESPTOOL_INFO"
    exit 1
fi

# Replace ", " with " " to handle cases like [python, script.py]
ESPTOOL_CMD=$(echo "$ESPTOOL_CMD_RAW" | sed 's/, / /g')

# Convert to WSL path for direct execution
# This avoids quoting issues with cmd.exe
ESPTOOL_WSL=$(wslpath -u "$ESPTOOL_CMD")

echo "Esptool (WSL): $ESPTOOL_WSL"

# Construct the full command
# Note: We use 0x0 as the address for the image.bin
# We use --no-stub if needed, but the log showed stub usage, so we stick to defaults or what jag uses.
# The user provided log showed:
#   Changing baud rate to 921600
#   Flash will be erased...
#   Wrote ... at 0x00000000
# So we use: -b 921600 --before default_reset --after hard_reset write_flash --flash_mode dio --flash_size detect --flash_freq 40m 0x0 <FILE>

echo "Running esptool..."

# Execute directly
"$ESPTOOL_WSL" -p "$COM_PORT" -b 921600 --before default_reset --after hard_reset write_flash --flash_mode dio --flash_size detect --flash_freq 40m 0x0 "$WIN_IMAGE_PATH"
