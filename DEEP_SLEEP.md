# ESP32 deep sleep

`Cpu2Sleep` coordinates deep sleep on the ESP32 (P2) with the Lightbug
controller (P1). It requires P1 firmware that supports the CPU2 sleep handshake
and an ESP32-C6 with the shared I2C SCL wake connection (GPIO7; SDA is GPIO6).
Deep sleep restarts the whole ESP32, so all containers and application tasks
must agree that it is safe to sleep.

```text
P2 application                         P1 controller
     |                                      |
     |---- OPEN, capability discovery ----->|
     |---- AWAKE -------------------------->|
     |---- Button subscription (optional) ->|
     |                                      |
     |---- PREPARE (selected wake sources) ->|
     |<--- ACK / NACK ----------------------|
     |                                      |
     |  NACK: stay awake and retry later     |
     |  ACK or silence: enter deep sleep    |
     |  P2 supply remains on                |
     |                                      |
     |<--- SCL wake pulse ------------------| button / power connected
     |  restart application                 |
     |---- AWAKE -------------------------->|
     |<--- retained button events ----------|
     |---- ACK after handling ------------->|
```

## Choose wake sources

Pass `--wake-message-types` to `Cpu2Sleep`:

- **Button (38):** wake on a debounced press. The event, including press duration,
  arrives on release. The coordinator creates a RAM subscription with the default
  subscription ID (0) and no expiry. Register a synchronous button handler before
  calling `start-awake` so retained events can be handled before acknowledgement.
- **Power Info (48):** wake when external power is connected, including with a
  full battery. No Power Info subscription is needed. Disconnecting power and
  periodic power readings do not cause a wake.

The default is both sources; choose at least one. Timer-service subscriptions
are not supported yet. The local ESP32 recovery timer is separate.

## Use the coordinator

See [the standalone example](examples/modules/power/deep-sleep.toit) for a
minimal external-power wake example, or
[the vending container](examples/containers/base-vending.toit) for button
handling and an application idle check.

```toit
import esp32
import lightbug.devices as devices
import lightbug.modules.power show Cpu2Sleep

main:
  esp32.ext1-wakeup-status (1 << 7) // Release the wake pin before using I2C.
  device := devices.I2C --open=false --reinit-on-comms-start=false
  power := Cpu2Sleep device.comms --wake-message-types=[48]
  power.start-awake device

  // Do application work here. Allow a programming window on cold boot.
  if esp32.reset-reason != esp32.RESET-DEEPSLEEP: sleep (Duration --s=20)
  while not (power.deep-sleep device --duration=(Duration --h=1)):
    sleep (Duration --s=5)
```

Use one transport owner and one Comms reader. `--reinit-on-comms-start=false`
preserves pending events across deep-sleep restarts. Register application handlers
before `start-awake`; it opens the link, discovers capabilities, declares AWAKE
and subscribes to selected button events.

For an application with ongoing work, supply `--can-sleep=(:: application-idle)`.
The coordinator checks it before PREPARE and again before closing the transport.
Coordinate other tasks that can write to the transport before calling
`deep-sleep`. The coordinator handles its reader and heartbeats.

## Sleep acceptance and recovery

P1 returns `InvalidState` (5) while charging or connected to external power,
regardless of the selected wake sources. A full battery still counts as external
power. This keeps the example accessible while USB is connected.

The intended contract is to honour an explicit NACK and stay awake. ACK or no
response permits sleep; only ACK confirms that P1 accepted the requested wake
sources and event retention. `Cpu2Sleep` waits up to 500 ms for PREPARE to be sent
and answered (`--prepare-timeout`). A failed or stalled write aborts the attempt.
Following a NACK, `deep-sleep` returns `false` and waits five seconds before
sending another request (`--rejection-retry`). UART work and normal heartbeats
continue. P1 may also hold its charging status briefly after disconnection.

The vending example waits 20 seconds on cold boot for programming, skips that
grace after deep-sleep wake, and sleeps after 500 ms of UART inactivity once its
identity is available. It wakes on button or power connection and has a one-hour
recovery timer. The current Toit runtime requires a timer; the commented
60-second alternative is useful for testing. Wake latency depends on hardware,
firmware and runtime startup; full-battery connection may be detected by polling.

Button delivery is ordered and at least once. Accept events before acknowledging
them and preserve the last accepted sequence across deep sleep if duplicate
actions matter. The vending example uses RTC RAM for this. P1 reset or loss of
P2 power can discard retained state; this is not an exactly-once guarantee.

## Build and run

Install the examples' dependencies before compiling or installing:

```sh
cd examples
jag pkg install
jag toit analyze containers/base-vending.toit
jag toit compile --snapshot -O2 -o /tmp/base-vending.snapshot containers/base-vending.toit
```

For a complete flash image without Jaguar's WiFi service, see the
[standalone build instructions](DEVELOPMENT.md#standalone-vending-firmware).
Run `make test` for host regression tests. Confirm wake, GPIO release and
application behaviour on the target hardware before deployment.
