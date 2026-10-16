# Development

## Standalone vending firmware

Build a complete ESP32-C6 flash image without Jaguar or its WiFi service:

```sh
./tools/build-vending-standalone.sh
```

The output is `build/out/lpk-standalone.bin`, flashed manually at address `0x0`.
The script finds `toit` or uses `jag toit` as a compiler launcher; set
`TOIT=/path/to/sdk/bin/toit` to select a specific SDK. It downloads and caches
the matching native firmware and a 4 MB partition table with larger app slots,
and installs example dependencies if missing. Downloads require internet on
the first build for each SDK version. An optional argument changes the output
path. The script builds the image without flashing hardware.

## Example dependencies and compilation

The examples have their own `package.yaml` and `package.lock`. Install their
dependencies from `examples/` before compiling or installing a container:

```sh
cd examples
jag pkg install
jag toit analyze containers/base-vending.toit
jag toit compile --snapshot -O2 -o /tmp/base-vending.snapshot containers/base-vending.toit
```

Missing-package errors for `toit-coordinate`, `pkg-http` or `toit-watchdog`
usually mean this install step has not been run. Installing dependencies at the
repository root does not install the examples project's dependencies.

## Tests

This repository's tests can be run locally via `make test`.

By default tests run against the `host` device (local execution).

Native SDKs use `toit run` (or `toit.run`) for host execution.
Running on hardware with `DEVICE=<name>` requires Jaguar (`jag`).
`make test` runs every discovered test and returns nonzero if any test fails.

Run the test-runner regression checks with `python3 tools/test_make_test.py`.


## Vending responses

`Vending` accepts `--response-count` (a positive integer, default `1`).
Each request's response, including `ERROR\r\n`, is sent that many times.
The first response starts no earlier than `--min-response-delay` after the
request header; subsequent responses start at least that duration after the
previous transmission started. Transmission and UART switching may extend
the interval. Unsupported commands remain ignored.

The base vending container example uses `--response-count=1` and a 5 ms
minimum response delay. See [deep sleep and wake timing](DEEP_SLEEP.md) for
P1/P2 setup, timing fields, the container's sleep policy and hardware validation.
