# Development

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

The base vending container example uses `--response-count=3` and a 100 ms
minimum response delay.