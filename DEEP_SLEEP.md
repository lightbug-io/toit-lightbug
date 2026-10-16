# P1/P2 deep sleep and wake timing

`examples/containers/base-vending.toit` now owns the LP4 sleep lifecycle. Install
it with the STM32 `feature/esp32-c6-deep-sleep-wake` firmware. The whole ESP32
resets on deep-sleep wake, including every other container; run this only when
those containers also permit sleeping. Native ESP-IDF setup is documented in
the companion firmware's `docs/CPU2_C6_DEEP_SLEEP_WAKE.md`.

From the repository root, install the examples project's dependencies and check
the container locally before installing it on a device:

```sh
cd examples
jag pkg install
jag toit analyze containers/base-vending.toit
jag toit compile --snapshot -O2 -o /tmp/base-vending.snapshot containers/base-vending.toit
```

Run `jag pkg install` here even if dependencies have already been installed at
the repository root; `examples/` has its own package lock and dependency links.

The example keeps its existing **5 ms minimum response delay and one response**.
It restores vending identity from an RTC RAM bucket, brings up UART RX before
I2C, sends OPEN to request retained power, resolves device capabilities, sends
AWAKE, and subscribes to button events
with RAM retention. Device identity/temperature/voltage refresh asynchronously.
Missing identity is retried promptly, and the example stays awake until a valid
identity has been obtained. UART protocol data must still be validated against
both kiosk versions on hardware.

`Cpu2Sleep.start-awake` sends OPEN before capability discovery, then starts
heartbeats after its positive ACK. OPEN and discovery each have a one-second
deadline covering the transport write and reply. The demo retries failed setup
after 500 ms, beginning with another OPEN; a lost capability response cannot
block startup for the previous 60-second default. AWAKE follows discovery so
pending P1 commands resume after capabilities are available. This uses the
existing P1 OPEN power policy; ACKing P1's own OPEN alone does not request power.

P1 vetoes deep sleep while charging or on external power, keeping RX active.
A 20-second grace period on cold boot or a reset other than deep-sleep wake
also keeps Jaguar reachable for
programming even if P1 reports no external power. `STARTUP-GRACE` in the example
controls this period; UART service continues during it. The example checks
`esp32.reset-reason == esp32.RESET-DEEPSLEEP` and skips the grace on those wakes.

P1 initialises status at boot and refreshes the charge sensor on PREPARE. On
LP4, charger PGOOD detects a powered/full battery even if STAT is inactive.
P1 replies with `InvalidState` (5) while charging/powered, even if power wake
was not selected. P2 uses this reply; it does not poll or subscribe to Power
Info for the sleep decision.

When undocked, past the 20-second startup grace, with valid identity and idle for 500 ms, the example requests
P1's sleep contract. P1's ten-second charge-off hold can postpone acceptance.
The intended advisory contract is to wait briefly and cancel sleep on any
explicit NACK. The demo waits up to 500 ms after sending PREPARE (configurable
with `Cpu2Sleep --prepare-timeout`); ACK or no response permits reader shutdown,
bus/pin release and deep sleep. Future implementations may ignore the veto.
A NACK leaves the reader and normal 15-second heartbeat schedule running.
Further `deep-sleep` calls return false without sending PREPARE for five seconds
(configurable with `Cpu2Sleep --rejection-retry`). UART processing continues
during this cooldown; after unplugging, it can add up to five seconds before
the next sleep attempt, in addition to P1's charge-off hold.
Silence does not confirm P1 accepted event retention/wake. The reader remains
active during the reply window, then is cancelled and joined before the bus
closes. A second idle check handles a UART frame arriving during the handshake;
an idle veto or teardown failure reconnects and sends AWAKE.

P1 wakes P2 through an open-drain low pulse on **GPIO7 / I2C SCL**. GPIO6 is SDA.
Planned timer wake will use subscriptions to a P1 Timer service, reusing Interval,
Duration and Timeout for infinite repeat, finite repeat and single-use timers.
Its event messages will follow the button wake/retention path, with best-effort
delivery timing and no accuracy guarantee. This service is not implemented yet
and requires no changes to P1 timing or sleep behaviour. P2's local recovery
timer is independent of that service.

The negotiated triggers are a debounced button press and external-power
connection. Button durations arrive on release; P1 retains those messages until
ACKed. The example stores the last accepted event sequence in RTC RAM before
Comms sends its ACK, including after a deep-sleep restart. Adapt
`VendingButtons` for application actions: durable acceptance/deduplication must
precede ACK. RTC state and P1's FIFO do not establish exactly-once behaviour
across P1 resets or loss of P2 power.

Charge removal, periodic telemetry and motion do not wake P2. A one-hour P2
timer recovers missed pulses. Adjust `RECOVERY-WAKE` after measuring cycle
energy; timer boots have a real power cost. This Toit runtime always enables
a timer on deep sleep, so external-only wake requires a runtime change.
No transport REINIT is sent during
resume, because it clears P1 transport buffers.

## Reusing the coordinator

```toit
import esp32
import lightbug.devices as devices
import lightbug.modules.power show Cpu2Sleep

main:
  esp32.ext1-wakeup-status (1 << 7)
  // Initialise the latency-sensitive application here first.
  device := devices.I2C --open=false --reinit-on-comms-start=false
  power := Cpu2Sleep device.comms --wake-message-types=[38, 48]
  power.start-awake device
  // Perform application work and handle subscribed buttons synchronously.
  // Only the transport owner may call this, with all producers quiescent:
  power.deep-sleep device --duration=(Duration --h=1)
```

This minimal example has no button action handler. Register your handler before
AWAKE, so retained events are processed before generic ACKs. Use one Comms
instance/reader per transport. Call `pause-inbound` from the transport owner,
never inside an inbound handler. Coordinate any heartbeat/outbox producers
before sleep. `Cpu2Sleep` stops heartbeats after PREPARE permits sleep and
restores them if teardown or the final idle check aborts sleep.

## Reading timing telemetry

Development timing collection and reports are currently commented out in
`base-vending.toit`, `src/modules/power/cpu2_sleep.toit` and
`src/cust/vending.toit`. UART idle tracking, minimum response delays and the
cold-boot grace remain active. To use the telemetry below, restore those
commented sections and build P1 with `DEBUG_ESP32_WAKE_TIMING=1` in its local
overrides (default 0). P1 builds without that flag omit timing state, capture
and logging, reject development timing queries/reports with `NotSupported`,
and accept AWAKE without processing its optional timing fields.

Capture **STM32/P1 RTT**, with P2 USB disconnected during measurements. Install
both the updated P1 firmware and this container. P2 sends boot/setup timings and
reset/wake causes with AWAKE. P1 logs `CPU2 wake` and `CPU2 P2` lines after the
AWAKE ACK/button handoff, correlated by `cycle`. No P2 USB logging is required.

After at least 500 ms of UART inactivity, P2 sends kiosk timings over I2C for P1
to log as `CPU2 UART` lines. It sends again when request/button counts change,
so an initial report with no request samples can be followed by the first kiosk
exchange. Timestamp capture performs no synchronous prints during TX/RX
switching. Continuous kiosk traffic can defer the report until a quiet interval;
timing records remain in memory. Missing samples are omitted, while zero is valid.

P1 timing is also available through `power.wake-timing`, or V3 **type 47 GET with
payload key 50 = true**. Legacy type 47 GET without this selector is unchanged.

| P1 RTT field | Measurement |
| --- | --- |
| `cycle` | P1 RAM sleep-cycle counter; zero before any accepted PREPARE; resets with P1 |
| `flags` | Valid bits: 1 trigger, 2 first pulse, 4 first AWAKE, 16 P2 times, 64 reset/wake causes, 128 setup times; bit 8 is reserved and bit 32 records SCL release failure |
| `reason` | Bit 1 button, bit 2 external-power connection; may contain both |
| `trigger_to_pulse_ms` | First detected trigger to first actual SCL assertion, including guard/busy-bus waits |
| `pulse_to_awake_ms` | First SCL assertion to receipt of first AWAKE; includes boot, I2C setup and any pulse/timer recovery |
| `trigger_to_awake_ms` | Detected trigger to first AWAKE receipt |
| `attempts` | Actual pulses; busy deferrals do not count; release failures do |
| `app_us`, `uart_ready_us`, `awake_sent_us` | P2 timestamps supplied with AWAKE, in microseconds since P2 wake |
| `i2c_ready_us`, `type_ready_us` | P2 I2C/Comms setup and P1 capability discovery completed, microseconds since P2 wake |
| `reset`, `wake` | ESP32-C6 deep-sleep wake: reset 8, wake 3 for EXT1 or 4 for timer recovery; reset 11 denotes USB reset |

`CPU2 UART` fields give P2's first request header read, first response submission,
first RX restoration, and the latest TX-flush-return to RX-restored interval.
They use `Time.monotonic-us --since-wakeup`. P2 startup values include runtime
startup before application entry; `uart_ready_us - app_us` isolates
the application's RX setup. These are software observations: request timestamps
are when software reads a header, response timestamps precede the write, and RX
restoration timestamps follow UART construction. They are not physical wire
edges or proof that a byte was electrically received.

**Never subtract a P1 timestamp from a P2 timestamp.** P1 intervals use its
millisecond clock; P2 uses a separate microsecond clock. P1's sample is frozen
at first AWAKE and resets on the next accepted PREPARE. Missing measurements are
omitted; zero is valid. Coalesced events retain first-trigger timing. Retry
counts and wake cause distinguish a prompt pulse wake from timer recovery.
If all wake pulses receive no AWAKE, P1 logs a partial snapshot and warning;
any later AWAKE logs the completed snapshot for that cycle. Cycle 0 is startup
before the first accepted PREPARE, rather than a measured trigger wake.

For bench measurements, correlate these reports with charge voltage, STAT,
SCL, and UART waveforms on one scope timebase. Full/inhibited-battery insertion
can still use P1's 500 ms polling fallback. Avoid verbose P1 logging and debug
sleep overrides when measuring latency/current. P1 retains its existing sleep
policy and stays awake while the P2 supply is enabled.

## Validation

The repository CI uses SDK `v2.0.0-alpha.198`:

```sh
make test
toit analyze examples/containers/base-vending.toit
toit compile --snapshot -O 2 -o /tmp/base-vending.snapshot examples/containers/base-vending.toit
```

New host tests cover protocol fields, missing versus zero measurements, sleep
rejection, a delayed NACK, bounded silence allowing sleep, a late application
veto, teardown recovery, lost startup replies, stalled startup writes,
capability-discovery timeout/retry through real Comms, button sequence
deduplication, and stopping/joining/restarting the real Comms reader. Vending
tests use synthetic UART ports; hardware wake, RTC retention, GPIO release and
actual kiosk recognition still require a bench test. Existing tests that only
print failed assertions retain that limitation; the new tests throw on failure.
