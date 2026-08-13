# Build

Scripts and artifacts related to building useful outputs from this repository.

## Scripts

 - `build.sh`: A shell script that builds an application into its various artifacts.
 - `flash_envelope.sh`: A shell script that flashes a built `.envelope` file to a connected Lightbug device, using `jag`.
 - `flash_image.sh`: A shell script that flashes a built `.image.bin` file to a connected ESP32 device, using `esptool.py` via `jag`.

Example usage:

```sh
./build/build.sh basic-ble-cert-test ./examples/basic/ble-cert-test.toit v2.0.0-alpha.190 esp32c6
```

## Dockerized builds

If you want to keep your host Jaguar / Toit SDK setup untouched, use the Docker wrapper.
It builds a small image with a pinned Jaguar release, runs `jag setup` inside the
container, installs package dependencies, and then calls the same `build/build.sh`
workflow used by CI.

Example for an application in a different repository:

```sh
./build/build_in_docker.sh \
	example-kiosk-app \
	/workspace/external-app/src/main.toit \
	esp32c6 \
	v2.0.0-alpha.191
```

This writes artifacts to:

```text
build/out/example-kiosk-app/
```

Useful environment overrides:

```sh
JAG_VERSION=v1.63.0
LIGHTBUG_ENVELOPE_VERSION=lb.20260415-1
LIGHTBUG_ENVELOPE_URL=https://.../firmware.envelope
LIGHTBUG_ENVELOPE_FILE=/absolute/path/to/firmware.envelope
LIGHTBUG_FIRMWARE_VERSION=0.18.0
```

If you already have a local envelope built elsewhere, `LIGHTBUG_ENVELOPE_FILE` is the
most reliable way to avoid SDK / envelope version mismatches.

### Using a custom local envelope (manual firmware build)

If you need to build against a local envelope instead of a released `toit-envelopes` artifact,
set `LIGHTBUG_ENVELOPE_FILE` to the local file path.

The envelope source precedence in `build.sh` is:
1. `LIGHTBUG_ENVELOPE_FILE` (local file path)
2. `LIGHTBUG_ENVELOPE_URL` (remote URL)
3. `LIGHTBUG_ENVELOPE_VERSION` (release suffix + auto-download)

Example for `base-vending` with your manual envelope:

```sh
LIGHTBUG_ENVELOPE_FILE=/path/to/toit-envelopes/build/variants/esp32c6-console-none-usb-serial-jtag/esp32c6/firmware.envelope \
./build/build.sh base-vending ./examples/containers/base-vending.toit v2.0.0-alpha.189 esp32c6
```

This avoids SDK mismatch errors like:
`Snapshot was built by SDK ... but envelope is for SDK ...`.

## Artifacts

The` out/` directory contains build artifacts that are generated during the build process.

For each application these will be:
 - A `.snapshot` file containing the Toit snapshot of the application.
 - A `.envelope` file containing the Toit firmware, including the application snapshot.
 - A `.image.bin` file containing the binary image that can be flashed directly to an ESP32 device.

Example usage:

```sh
./build/flash_envelope.sh ./build/out/basic-ble-cert-test/basic-ble-cert-test.envelope COM14
```

```sh
./build/flash_image.sh build/out/basic-ble-cert-test/basic-ble-cert-test.image.bin COM14
```