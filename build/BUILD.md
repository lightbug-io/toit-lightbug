# Build

Scripts and artifacts related to building useful outputs from this repository.

Normal CI tests and release artifacts use Toit `v2.0.0-alpha.198` only.
The supported variants are `ble-cert-test`, `base`, and `base-vending`, all using
the `.198` envelope profile. The `base` variant includes the Apps functionality.
The alpha.191 profiles and legacy entrypoints have been retired.

## Experimental ESP32-S31 base

Set the repository Actions secret `TOIT_ENVELOPES_READ_TOKEN` to a fine-grained
token with **Actions: read** access to `lightbug-io/toit-envelopes`. The default
workflow token is scoped to this repository, not the envelope repository.
Manual workflows must be registered on the default branch before dispatching.

1. In `lightbug-io/toit-envelopes`, manually run **Build** with `profile: s31`.
2. Once it succeeds, copy the numeric run ID from its Actions URL.
3. Here, manually run **Build experimental S31 base**, supplying that ID as
   `envelopes_run_id`.

This opt-in workflow downloads the envelope and matching Linux x64 SDK from
that run, checks their checksums, and compiles the existing
`examples/containers/base.toit` unchanged. The `base-s31-4mb-artifacts` artifact
contains the snapshot, application envelope, full `base.s31.image.bin`, source
metadata, and checksums. CI checks the image is exactly 4 MiB and that both
bootloader and application headers identify S31 with a 4 MiB flash configuration.
Normal C6 builds and releases are unaffected.

The target module is **ESP32-S31-WROOM-3-N16R16V** (16 MiB flash, 16 MiB octal
PSRAM). PSRAM is enabled; the initial flash layout deliberately uses only 4 MiB,
with one OTA slot. This is a build/bring-up artifact, not hardware-qualified
firmware: the base app still expects Lightbug peripheral wiring and may require
board-specific pin changes before it runs on an S31 board.

Flash the complete image at address **0x0**, not at the S31 bootloader offset
(the image already places that bootloader at 0x2000). Use an S31-capable
**esptool 5.5 or newer** with ROM-only flashing:

```sh
esptool --chip esp32s31 --port /dev/ttyACM0 --no-stub \
  write-flash 0x0 base.s31.image.bin
```

Alternatively, flash the envelope with the experimental SDK's firmware tool,
which selects the matching S31 esptool and ROM-only mode. Do not use the legacy
`flash_image.sh` / installed Jaguar tooling for this experimental target.

## Scripts

 - `build.sh`: A shell script that builds an application into its various artifacts.
 - `flash_envelope.sh`: A shell script that flashes a built `.envelope` file to a connected Lightbug device, using `jag`.
 - `flash_image.sh`: A shell script that flashes a built `.image.bin` file to a connected ESP32 device, using `esptool.py` via `jag`.

Example usage:

```sh
./build/build.sh base ./examples/containers/base.toit v2.0.0-alpha.198 esp32c6
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
	v2.0.0-alpha.198
```

This writes artifacts to:

```text
build/out/example-kiosk-app/
```

Useful environment overrides:

```sh
JAG_VERSION=v1.71.0
LIGHTBUG_FIRMWARE_VARIANT=base
LIGHTBUG_ENVELOPE_RELEASE_TAG=lb.20260819-1
LIGHTBUG_ENVELOPE_ASSET=esp32c6-single-ota.198.envelope
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
3. `LIGHTBUG_ENVELOPE_RELEASE_TAG` plus `LIGHTBUG_ENVELOPE_ASSET`
4. `LIGHTBUG_ENVELOPE_VERSION` (legacy release suffix + auto-download)

Example for `base-vending` with your manual envelope:

```sh
LIGHTBUG_ENVELOPE_FILE=/path/to/toit-envelopes/dist/esp32c6-single-ota.198.envelope \
./build/build.sh base-vending.198 ./examples/containers/base-vending.toit v2.0.0-alpha.198 esp32c6
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
