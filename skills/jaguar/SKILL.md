---
name: jaguar
description: Discover Toit devices, choose native or Windows/WSL Jaguar access, inspect logs, and run or install apps and containers. Use device-firmware for firmware replacement.
---

# Jaguar development

Read [transport selection](references/transports.md) before choosing a serial
port, host CLI or network address. Use the installed CLI's help and version;
options and SDK compatibility depend on that installation.

## Establish the target

Record the device identity, current serial port or network/proxy endpoint, and
the source or container involved. COM numbers and DHCP addresses are connection
details, not identities. Confirm the target from present USB devices and current
Jaguar/P1 logs; do not reuse a bench map from another session.

Use the user's existing authorization. An app update does not imply permission
to replace firmware, change network settings or operate additional devices.
Explain any new side effects and obtain the missing approval before those steps.

## Choose the operation

Commands below run from the repository root, in the shell hosting Jaguar. Replace
`DEVICE` and `NAME` with verified values; select a source file for the task.

| Intent | Command | Effect |
| --- | --- | --- |
| Inspect toolchain | `jag version` | Shows CLI and SDK versions |
| Check endpoint | `jag ping --device DEVICE` | Checks Jaguar connectivity |
| Inspect installed apps | `jag container list --device DEVICE` | Lists Jaguar-managed containers |
| Read logs | `jag monitor --port PORT --attach --force-plain` | Attaches; opening serial can still disturb some boards |
| Try an app | `jag run --device DEVICE ./examples/containers/base-apps-dev.toit` | Replaces Jaguar's current run program; does not install it for boot |
| Install for boot | `jag container install NAME ./examples/containers/base-apps.toit --device DEVICE` | Installs/replaces a named container and starts it |

`jag run` does not automatically remove installed containers. Check what is
already running before starting another app that owns the same hardware.
For non-display devices, choose a suitable entrypoint instead of `base-apps`.
Relay can start with `-D lb-app=relay`; source defines do not select a device.

## Containers, watchdogs and radios

- `base-apps.toit` starts its own watchdog provider. The optional development
  entrypoint `base-apps-dev.toit` supports `-D lb-watchdog-provider=external`.
  Use that define only when an external provider is actually installed/running.
  Do not run the production provider alongside a separate one.
- Replacing an app can leave watchdog clients or hardware subscriptions behind.
  On an upload/reset failure, collect logs and inspect the lifecycle before
  retrying. Do not mask a watchdog or treat a failed upload as a successful start.
- ESP-NOW needs Wi-Fi released on the current Toit implementation. Jaguar's
  `-D jag.wifi=false` changes network availability while the program runs. The
  installed CLI documents a default timeout; inspect `jag run --help` and choose
  the timeout deliberately. Verify a working USB/UART path before disabling the
  network used for updates. HTTP development controls also need networking.
- A Wi-Fi-disabled run is not the same as persistent USB-only firmware. If a
  firmware change is required, use [device-firmware](../device-firmware/SKILL.md).

## Verify the result

Capture the upload result and subsequent app startup from the verified device.
For a boot install, check the container list and boot behavior when a restart is
within scope. Firmware-bundled containers may start independently of Jaguar's
registry; use the envelope contents and startup logs as evidence for those.

Keep one serial owner per port. Close only the monitor/proxy you launched, using
its recorded process identity; do not kill processes by a broad command match.
Record source revision, target, defines, artifact/log paths and observed result
in the task/PR notes, without adding a permanent per-session bench diary.
