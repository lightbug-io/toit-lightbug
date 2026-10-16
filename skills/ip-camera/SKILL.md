---
name: ip-camera
description: Capture and inspect IP-camera snapshots as visual feedback during development or troubleshooting.
---

# IP-camera feedback

Use a user-provided camera still-image endpoint to observe a scene or check the
visible result of a task. Setup and commands are in
[DEVELOPMENT.md](../../DEVELOPMENT.md#ip-cameras-for-ai-assisted-development).

- Use the bundled [scripts/capture.sh](scripts/capture.sh) for individual
  snapshots. Resolve its path relative to this skill directory, regardless of the
  current working directory. Read `--help` for options.
  Camera URLs, credentials and orientation are local configuration; do not infer
  them from previous sessions or scan the network for cameras.
- Try native HTTP access first. From WSL, use `--windows` when the endpoint is
  reachable from Windows but not Linux. HTTPS verification stays enabled unless
  the user has chosen the helper's `--insecure` option for their camera.
- Capture when visual evidence answers the user's question. For before/after
  comparisons, keep the framing consistent and allow the observed action to
  finish. Use single snapshots unless the task needs repeated observation.
- Open the resulting image with the available image-viewing tool. Confirm the
  intended subject is visible, and distinguish observations from inferences.
  Ask for a framing, lighting or focus adjustment when the image is unclear.
  Use `--rotate` for the camera's orientation.
- Keep snapshots and credentials out of commits unless the user requests an image
  artifact. Use a locally supplied curl config for authentication.
