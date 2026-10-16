# Native, Windows and WSL access

Choose the host based on which operating system can reach the actual endpoint.
There are two independent questions: who owns the serial device, and who can
reach the device or proxy over the network.

| Environment | Preferred starting point |
| --- | --- |
| Native Linux/macOS with an accessible device | Native `jag`; use the discovered serial path or current network endpoint |
| Native Windows | Windows Jaguar and present COM ports |
| WSL; USB device attached to Windows | Windows Jaguar for COM-port operations |
| WSL; USB explicitly attached to Linux | Native Jaguar with its Linux serial path; do not also open it from Windows |
| WSL network request times out, Windows succeeds | Run that Jaguar operation on Windows; changing the host is not a reason to flash |

Check `jag version` on the host you will actually use. Windows and Linux can have
different Jaguar executables, cached SDKs, package caches and Wi-Fi defaults.
Do not assume the current shell's aliases or configuration exist on the other host.

## Discover and verify

On Windows, enumerate *present* Espressif ports in PowerShell:

```powershell
Get-CimInstance Win32_SerialPort |
  Where-Object { $_.PNPDeviceID -like 'USB\VID_303A*' } |
  Select-Object DeviceID,PNPDeviceID
```

That filter is for native Espressif USB. For USB/UART adapters, inspect their
present port entries too. Historical `Get-PnpDevice` entries can include unplugged
devices. Map the USB identity to the current Jaguar identity or P1 device ID.

For network access, use current startup/DHCP logs and confirm with `jag ping
--device DEVICE`. Discovery broadcasts can fail across WSL even when explicit
IP access works. A ping confirms an endpoint responds; also check its identity.

For an ongoing serial log, use `--attach`. Without it, Jaguar deliberately resets
the device. Some boards also reset when a port is opened despite `--attach`;
watch for the boot banner and report that interruption. Avoid repeatedly opening
and closing monitors during a timing-sensitive test.

## Invoke Windows Jaguar from WSL

For fixed commands, PowerShell avoids Linux shell aliases. Propagate the native
exit status, and quote PowerShell expressions against expansion by Bash:

```bash
powershell.exe -NoProfile -Command 'jag version; exit $LASTEXITCODE'
```

PowerShell can use the repository's WSL UNC path as its working directory.
Verify it when compiling relative sources; Linux absolute paths such as `/home`
or `/tmp` are not Windows paths. Convert artifact paths with `wslpath -w` before
passing them to a Windows executable. For example, when `jag.exe` is on WSL's PATH:

```bash
jag.exe toit tool firmware --envelope "$(wslpath -w "$artifact")" show
```

For parameterized PowerShell calls, use properly quoted arguments or an argument
array. Do not concatenate user-provided paths/defines into shell code; JSON
encoding is not shell quoting. An interop/vsock error can be a host execution
restriction; distinguish it from device failure.

## USB proxy versus a USB log console

`jag monitor --proxy` needs a working **bidirectional Jaguar endpoint**. A boot
log visible over USB does not prove Jaguar can receive commands there. Match
the configured endpoint baud with `--baud`; do not rely on the proxy's default.
Inspect the proxy's printed address and use that endpoint for subsequent calls.
Keep its serial process open while making requests through it. Check whether
the proxy exposes a network listener/discovery before starting it; don't assume
it binds to loopback only.

On ESP32-C6, native USB Serial/JTAG and UART0 are distinct paths. Some envelopes
mirror logs to USB while the Jaguar endpoint reads UART0. In that case changing
the host, baud or `--uart-only` flag alone does not make native USB input work:
the firmware console and Jaguar endpoint must both support that input path.
Inspect the envelope/build configuration and endpoint implementation, or use an
already validated artifact. Do not depend on a patched executable or artifact
that only exists under a previous session's `/tmp` directory.
