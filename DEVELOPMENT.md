# Development

## Tests

This repository's tests can be run locally via `make test`.

By default tests run against the `host` device (local execution).

Native SDKs use `toit run` (or `toit.run`) for host execution.
Running on hardware with `DEVICE=<name>` requires Jaguar (`jag`).
`make test` runs every discovered test and returns nonzero if any test fails.

Run the test-runner regression checks with `python3 tools/test_make_test.py`.
