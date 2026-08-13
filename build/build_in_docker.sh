#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  build/build_in_docker.sh <snapshot_name> <target_toit_file> [firmware_type] [toit_version]

Example:
  build/build_in_docker.sh \
    example-kiosk-app \
    /workspace/external-app/src/main.toit \
    esp32c6 \
    v2.0.0-alpha.191

Optional environment variables:
  JAG_VERSION=v1.63.0
  LIGHTBUG_ENVELOPE_VERSION=lb.20260415-1
  LIGHTBUG_ENVELOPE_URL=https://.../firmware.envelope
  LIGHTBUG_ENVELOPE_FILE=/absolute/path/to/firmware.envelope
  LIGHTBUG_FIRMWARE_VERSION=0.0.0
  DOCKER_IMAGE_TAG=lightbug-toit-builder:jag-v1.63.0
EOF
}

if [[ $# -lt 2 || $# -gt 4 ]]; then
  usage
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is not installed or not on PATH." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIGHTBUG_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOCKERFILE_PATH="${SCRIPT_DIR}/docker/Dockerfile"

SNAPSHOT_NAME="$1"
TARGET_INPUT="$2"
FIRMWARE_TYPE="${3:-esp32c6}"
TOIT_VERSION="${4:-v2.0.0-alpha.191}"
JAG_VERSION="${JAG_VERSION:-v1.63.0}"
DOCKER_IMAGE_TAG="${DOCKER_IMAGE_TAG:-lightbug-toit-builder:jag-${JAG_VERSION#v}}"
CONTAINER_HOME="/tmp/home"
HOME_CACHE_DIR="${LIGHTBUG_ROOT}/build/cache/docker-home/${JAG_VERSION}"

mkdir -p "${HOME_CACHE_DIR}"

TARGET_FILE="$(realpath "${TARGET_INPUT}")"
if [[ ! -f "${TARGET_FILE}" ]]; then
  echo "Error: target Toit file not found: ${TARGET_INPUT}" >&2
  exit 1
fi

find_package_root() {
  local dir="$1"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/package.yaml" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

TARGET_DIR="$(dirname "${TARGET_FILE}")"
TARGET_PACKAGE_ROOT="$(find_package_root "${TARGET_DIR}")" || {
  echo "Error: could not find package.yaml above ${TARGET_FILE}" >&2
  exit 1
}

CONTAINER_TARGET_FILE=""
TARGET_MOUNT_ARGS=()

case "${TARGET_FILE}" in
  "${LIGHTBUG_ROOT}"/*)
    TARGET_RELATIVE="$(realpath --relative-to="${LIGHTBUG_ROOT}" "${TARGET_FILE}")"
    CONTAINER_TARGET_FILE="/workspace/lightbug/${TARGET_RELATIVE}"
    ;;
  *)
    TARGET_RELATIVE="$(realpath --relative-to="${TARGET_PACKAGE_ROOT}" "${TARGET_FILE}")"
    CONTAINER_TARGET_FILE="/workspace/target-app/${TARGET_RELATIVE}"
    TARGET_MOUNT_ARGS=(
      -v "${TARGET_PACKAGE_ROOT}:/workspace/target-app"
    )
    ;;
esac

ENVELOPE_ENV_ARGS=()
CUSTOM_ENVELOPE_MOUNT_ARGS=()

if [[ -n "${LIGHTBUG_ENVELOPE_VERSION:-}" ]]; then
  ENVELOPE_ENV_ARGS+=( -e "LIGHTBUG_ENVELOPE_VERSION=${LIGHTBUG_ENVELOPE_VERSION}" )
fi
if [[ -n "${LIGHTBUG_ENVELOPE_URL:-}" ]]; then
  ENVELOPE_ENV_ARGS+=( -e "LIGHTBUG_ENVELOPE_URL=${LIGHTBUG_ENVELOPE_URL}" )
fi
if [[ -n "${LIGHTBUG_FIRMWARE_VERSION:-}" ]]; then
  ENVELOPE_ENV_ARGS+=( -e "LIGHTBUG_FIRMWARE_VERSION=${LIGHTBUG_FIRMWARE_VERSION}" )
fi
if [[ -n "${LIGHTBUG_ENVELOPE_FILE:-}" ]]; then
  CUSTOM_ENVELOPE_FILE="$(realpath "${LIGHTBUG_ENVELOPE_FILE}")"
  if [[ ! -f "${CUSTOM_ENVELOPE_FILE}" ]]; then
    echo "Error: LIGHTBUG_ENVELOPE_FILE does not exist: ${LIGHTBUG_ENVELOPE_FILE}" >&2
    exit 1
  fi
  CUSTOM_ENVELOPE_DIR="$(dirname "${CUSTOM_ENVELOPE_FILE}")"
  CUSTOM_ENVELOPE_NAME="$(basename "${CUSTOM_ENVELOPE_FILE}")"
  CUSTOM_ENVELOPE_MOUNT_ARGS=( -v "${CUSTOM_ENVELOPE_DIR}:/workspace/custom-envelope:ro" )
  ENVELOPE_ENV_ARGS+=( -e "LIGHTBUG_ENVELOPE_FILE=/workspace/custom-envelope/${CUSTOM_ENVELOPE_NAME}" )
fi

echo "==> Building Docker image ${DOCKER_IMAGE_TAG}"
docker build \
  --build-arg "JAG_VERSION=${JAG_VERSION}" \
  -f "${DOCKERFILE_PATH}" \
  -t "${DOCKER_IMAGE_TAG}" \
  "${LIGHTBUG_ROOT}"

echo "==> Running firmware build in container"
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -e "HOME=${CONTAINER_HOME}" \
  "${ENVELOPE_ENV_ARGS[@]}" \
  -v "${HOME_CACHE_DIR}:${CONTAINER_HOME}" \
  -v "${LIGHTBUG_ROOT}:/workspace/lightbug" \
  "${TARGET_MOUNT_ARGS[@]}" \
  "${CUSTOM_ENVELOPE_MOUNT_ARGS[@]}" \
  "${DOCKER_IMAGE_TAG}" \
  bash -lc '
    set -euo pipefail
    cd /workspace/lightbug
    jag version
    jag setup
    jag pkg install
    cd /workspace/lightbug/examples
    jag pkg install
    if [[ -d /workspace/target-app ]]; then
      cd /workspace/target-app
      jag pkg install
    fi
    cd /workspace/lightbug
    ./build/build.sh "'"${SNAPSHOT_NAME}"'" "'"${CONTAINER_TARGET_FILE}"'" "'"${TOIT_VERSION}"'" "'"${FIRMWARE_TYPE}"'"
  '

OUTPUT_DIR="${LIGHTBUG_ROOT}/build/out/${SNAPSHOT_NAME}"
IMAGE_PATH="${OUTPUT_DIR}/${SNAPSHOT_NAME}.image.bin"

echo ""
echo "==> Build artifacts"
ls -lah "${OUTPUT_DIR}"
if [[ -f "${IMAGE_PATH}" ]]; then
  stat -c '%n %s bytes' "${IMAGE_PATH}"
fi