#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: IP_CAMERA_URL=<snapshot-url> skills/ip-camera/scripts/capture.sh [options] [output.jpg]

Capture one still image. Requires curl and ImageMagick (magick or convert).
  --windows       Fetch through Windows curl.exe from WSL (requires wslpath).
  --rotate DEG    Rotate clockwise after EXIF orientation: 0, 90, 180 or 270.
  --insecure      Allow an untrusted HTTPS certificate for this request.
  --help          Show this help.

Optional environment: IP_CAMERA_ROTATE (default 0), IP_CAMERA_CURL_CONFIG.
Use a local curl config file for authentication; do not commit credentials.
EOF
}

windows=false
insecure=false
rotation="${IP_CAMERA_ROTATE:-0}"
output=""
while (($#)); do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --windows) windows=true; shift ;;
    --insecure) insecure=true; shift ;;
    --rotate)
      if (($# < 2)); then echo '--rotate requires degrees' >&2; exit 2; fi
      rotation="$2"; shift 2 ;;
    -*) echo "Unknown option: $1" >&2; exit 2 ;;
    *)
      if [[ -n "$output" ]]; then echo 'Only one output path is supported' >&2; exit 2; fi
      output="$1"; shift ;;
  esac
done
case "$rotation" in
  0|90|180|270) ;;
  *) echo 'Rotation must be 0, 90, 180 or 270' >&2; exit 2 ;;
esac
url="${IP_CAMERA_URL:?Set IP_CAMERA_URL to the camera HTTP(S) still-image endpoint}"
case "$url" in
  http://*|https://*) ;;
  *) echo 'IP_CAMERA_URL must use HTTP or HTTPS' >&2; exit 2 ;;
esac

if command -v magick >/dev/null 2>&1; then
  converter=magick
elif command -v convert >/dev/null 2>&1; then
  converter=convert
else
  echo 'ImageMagick is required (magick or convert)' >&2; exit 2
fi
fetcher=curl
if "$windows"; then
  fetcher=curl.exe
  command -v wslpath >/dev/null || { echo '--windows requires WSL wslpath' >&2; exit 2; }
fi
command -v "$fetcher" >/dev/null || { echo "$fetcher is required" >&2; exit 2; }

output="${output:-${TMPDIR:-/tmp}/ip-camera-$(date +%Y%m%d-%H%M%S).jpg}"
output_dir="$(cd -- "$(dirname -- "$output")" && pwd)"
output="$output_dir/$(basename -- "$output")"
work="$(mktemp -d "$output_dir/.ip-camera.XXXXXX")"
trap 'rm -rf -- "$work"' EXIT
raw="$work/snapshot"
download="$raw"
config="${IP_CAMERA_CURL_CONFIG:-}"
if "$windows"; then
  download="$(wslpath -w "$raw")"
  if [[ -n "$config" ]]; then config="$(wslpath -w "$config")"; fi
fi
args=()
# curl requires --config before the options that should override its contents.
if [[ -n "$config" ]]; then args+=(--config "$config"); fi
args+=(--fail --silent --show-error --connect-timeout 5 --max-time 10)
args+=(--proto '=http,https' --output "$download")
if "$insecure"; then args+=(--insecure); fi
"$fetcher" "${args[@]}" --url "$url"

# Convert before replacing the destination, so bad responses preserve old images.
"$converter" "$raw[0]" -auto-orient -rotate "$rotation" "$work/output.jpg"
mv -- "$work/output.jpg" "$output"
printf '%s\n' "$output"
