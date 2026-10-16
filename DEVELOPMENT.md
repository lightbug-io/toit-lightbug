# Development

## Tests

This repository's tests can be run locally via `make test`.

By default tests run against the `host` device (local execution).

Native SDKs use `toit run` (or `toit.run`) for host execution.
Running on hardware with `DEVICE=<name>` requires Jaguar (`jag`).
`make test` runs every discovered test and returns nonzero if any test fails.

Run the test-runner regression checks with `python3 tools/test_make_test.py`.

## IP cameras for AI-assisted development

An IP camera gives an AI coding agent visual feedback from your workspace.
Aim a phone or camera at the subject, check that relevant details are readable,
and provide its **HTTP(S) still-image URL**. A viewer page or video stream
URL is not a still-image endpoint. Keep access on your development network;
internet exposure is unnecessary.

Install curl and ImageMagick (`magick` or `convert`), then configure the endpoint
locally and capture a frame:

```bash
export IP_CAMERA_URL='http://<camera-host>:<port>/<snapshot-path>'
skills/ip-camera/scripts/capture.sh /tmp/camera-snapshot.jpg
```

From WSL, add `--windows` if only Windows can reach the camera; this uses
`curl.exe` and `wslpath`. Use `--rotate 90` (or 180/270) for a rotated mount; the
helper applies EXIF orientation first. HTTPS certificates are verified by default.
For a known camera with a self-signed certificate, `--insecure` is an explicit
per-capture option. Authentication can be supplied through
`IP_CAMERA_CURL_CONFIG`, pointing to a private curl config file outside the repo.
Do not put credentials in committed files.

Tell the agent what is in view and what to check, for example:
“Use the configured IP camera to compare the setup before and after my change.”
The agent can capture and inspect frames, describe visible differences, and ask
for better framing or lighting when needed. Single snapshots usually suffice;
use repeated captures when the task needs observations over time.
The reusable agent instructions are in the [IP-camera skill](skills/ip-camera/SKILL.md).
