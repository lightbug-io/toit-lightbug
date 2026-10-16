#!/usr/bin/env bash
set -euo pipefail

if [[ ${1:-} == --help || $# -gt 1 ]]; then
  echo "Usage: $0 [output.bin]"
  echo "Build standalone ESP32-C6 vending firmware. Set TOIT to use a specific SDK executable."
  exit 0
fi

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
output=${1:-"$repo_dir/build/out/lpk-standalone.bin"}
if [[ -n ${TOIT:-} ]]; then
  toit=("$TOIT")
elif command -v toit >/dev/null 2>&1; then
  toit=(toit)
elif command -v jag >/dev/null 2>&1; then
  toit=(jag toit) # Compiler launcher only; Jaguar is not included in the image.
else
  echo "Install a Toit SDK or Jaguar, or set TOIT=/path/to/sdk/bin/toit." >&2
  exit 1
fi

sdk_version=$("${toit[@]}" version)
if [[ ! $sdk_version =~ ^v[0-9][A-Za-z0-9.+-]*$ ]]; then
  echo "Unrecognised Toit SDK version: $sdk_version" >&2
  exit 1
fi

cache_dir="$repo_dir/build/cache/standalone/$sdk_version"
mkdir -p -- "$cache_dir" "$(dirname -- "$output")"
work_dir=$(mktemp -d "$cache_dir/build.XXXXXX")
trap 'rm -rf -- "$work_dir"' EXIT

download() {
  local name=$1
  if [[ ! -s "$cache_dir/$name" ]]; then
    curl --fail --location --retry 3 \
      "https://github.com/toitlang/envelopes/releases/download/$sdk_version/$name" \
      --output "$work_dir/$name"
    mv -- "$work_dir/$name" "$cache_dir/$name"
  fi
}

download firmware-esp32c6.envelope.gz
# alpha.199 exceeds the default app partition. This table fits 4 MB flash
# with larger OTA app slots, matching Jaguar's C6 partition workaround.
download partitions-esp32-ota-1d0000.csv

if [[ ! -d "$repo_dir/examples/.packages" ]]; then
  (cd -- "$repo_dir/examples" && "${toit[@]}" pkg install)
fi

gzip -dc "$cache_dir/firmware-esp32c6.envelope.gz" > "$work_dir/firmware.envelope"
"${toit[@]}" compile -Werror --snapshot -O2 --project-root "$repo_dir/examples" \
  -o "$work_dir/lpk.snapshot" "$repo_dir/examples/containers/base-vending.toit"
"${toit[@]}" tool firmware -e "$work_dir/firmware.envelope" \
  container install lpk "$work_dir/lpk.snapshot"
"${toit[@]}" tool firmware -e "$work_dir/firmware.envelope" \
  extract --format=image --partitions="$cache_dir/partitions-esp32-ota-1d0000.csv" \
  -o "$work_dir/lpk.bin"
mv -- "$work_dir/lpk.bin" "$output"
echo "Built $output ($sdk_version, ESP32-C6; no Jaguar service)."
echo "Flash this complete image at address 0x0."
