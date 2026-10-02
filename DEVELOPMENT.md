# Development

## Tests

This repository's tests can be run locally via `make test`.

By default tests run against the `host` device (local execution).

## Vending responses

`Vending` accepts `--response-count` (a positive integer, default `1`).
Each request's response, including `ERROR\r\n`, is sent that many times.
The first response starts no earlier than `--min-response-delay` after the
request header; subsequent responses start at least that duration after the
previous transmission started. Transmission and UART switching may extend
the interval. Unsupported commands remain ignored.

The base vending container example uses `--response-count=3` and a 100 ms
minimum response delay.