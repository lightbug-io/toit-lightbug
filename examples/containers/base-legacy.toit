// Base application for Toit alpha.191 envelopes.
//
// The alpha.198 `base.toit` additionally exposes the dock USB V3 bridge.
// Keep this entrypoint so the published base.191 artifact remains available.

import lightbug.devices as devices
import lightbug.firmware as firmware

main:
  firmware.print-startup-line
  devices.I2C --open=false --background=false --startComms=true
