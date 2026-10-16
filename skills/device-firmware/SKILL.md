---
name: device-firmware
description: Inspect, flash and verify Toit firmware on a specified ESP/P2 device, including Jaguar and firmware-bundled containers. Use for firmware replacement rather than ordinary app uploads.
---

# Toit device firmware

This skill covers the ESP/P2 side of Lightbug devices. P1/STM32 updates use the
separate firmware project and procedure; an ESP/P2 flash does not update P1.
For transport selection and Windows/WSL paths, read
[Jaguar transports](../jaguar/references/transports.md).

## Establish scope and artifact

Use existing session approval when it covers the specific device and effects.
Otherwise establish the target, artifact and intended changes before writing.
Permission to install a container or disable Wi-Fi is not automatically approval
to replace firmware. Prepare and inspect the artifact first so any remaining
approval is for a concrete operation.

Before flashing:

- Identify the present port and physical device from USB identity and current
  device logs. Do not infer identity from a COM number or an old bench map.
- Inspect the artifact's SDK, chip, flash/partition layout, embedded containers,
  assets and boot triggers. Verify the app startup defines and intended device
  identity/settings; do not copy another device's identity from a bench image.
- Distinguish a stock Jaguar provisioning flash from installing a prepared app
  envelope. Stock provisioning does not automatically include the project app.
  Check whether existing containers/configuration will be retained or replaced;
  do not promise either without inspecting the image and flash procedure.
- Verify the intended control path after reboot: Wi-Fi HTTP, UART, or native USB.
  For USB-only operation, confirm both the console and Jaguar input path support
  the board. `--uart-only` does not by itself select native USB.
- Confirm recovery access and close only your own serial monitor. If another
  process owns the port, don't kill it to make flashing proceed.

## Flash one verified target at a time

Inspect the installed CLI help rather than assuming flags from another SDK.
Commands below are templates in the shell hosting Jaguar; substitute the verified
artifact and port. For Windows invoked from WSL, convert paths as described in
the transport reference.

Inspect a prepared envelope without accessing hardware:

```text
jag toit tool firmware --envelope ARTIFACT.envelope show
```

Flash that envelope after the target and replacement effects are authorized:

```text
jag toit tool firmware --envelope ARTIFACT.envelope flash --port PORT
```

For intentional stock Jaguar provisioning, inspect `jag flash --help`, select the
envelope/chip/network configuration explicitly, then use `jag flash` on the
verified port. Saved CLI Wi-Fi settings may be applied; don't print credentials.
Do not substitute stock provisioning for an app-envelope flash without checking
the changed behavior and scope.

Prefer the envelope tool over manually guessed `esptool` addresses. A full
`.image.bin` and an app-only `.bin` are not interchangeable. For raw binaries,
require the documented image layout/offsets and inspect the flashing helper
before invoking it. Don't erase the entire chip as routine troubleshooting.

## Verify and stop

Require a successful flash exit and write/hash verification. Then re-identify
the port if it re-enumerated, attach logs, and check the firmware identity and
expected app startup. If the app is bundled into the envelope, verify its boot
trigger and startup rather than relying solely on `jag container list`.

Record the artifact/revision, target identity, flash result, startup evidence and
any incomplete checks in the task/PR notes. A successful flash does not prove RF
delivery or all app behavior; test those only when included in the task.

If connectivity or startup fails, preserve the error and investigate the cable,
port ownership, reset/boot mode, power and console path. Retry only when there is
a reason the result may differ. Repeated unchanged failures are not proof of a
hardware defect or justification to overwrite another device or downgrade its SDK.
