#!/bin/bash

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <envelope_file> <com_port>"
    echo "Example: $0 build/out/base-apps/base-apps.envelope COM21"
    exit 1
fi

ENVELOPE_FILE=$1
COM_PORT=$2

# Check if file exists in WSL
if [ ! -f "$ENVELOPE_FILE" ]; then
    echo "Error: Envelope file '$ENVELOPE_FILE' not found."
    exit 1
fi

# Resolve absolute path
ABS_WSL_PATH=$(readlink -f "$ENVELOPE_FILE")

# Convert to Windows path
if command -v wslpath &> /dev/null; then
    WIN_PATH=$(wslpath -w "$ABS_WSL_PATH")
else
    echo "Error: wslpath not found. Are you running in WSL?"
    exit 1
fi

echo "----------------------------------------------------------------"
echo "Flashing Firmware"
echo "----------------------------------------------------------------"
echo "Envelope (WSL): $ABS_WSL_PATH"
echo "Envelope (Win): $WIN_PATH"
echo "Port:           $COM_PORT"
echo "----------------------------------------------------------------"

# Check if jag.exe is available
if ! command -v jag.exe &> /dev/null; then
    echo "Error: jag.exe not found in PATH. Please ensure Jaguar is installed on Windows and added to PATH."
    exit 1
fi

# Execute flashing command using Windows executable
# We use jag.exe to access Windows COM ports
jag.exe toit tool firmware -e "$WIN_PATH" flash --port "$COM_PORT"
