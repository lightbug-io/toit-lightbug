# LSM6DS3

A general-purpose Toit I2C driver for the LSM6DS3 and LSM6DS3TR: configurable
accelerometer/gyroscope, immediate measurements, hardware FIFO, temperature,
interrupt routing and self-test stimulus. MIT licensed; no package dependencies.

We intend to publish `lsm6ds3` as an independent Toit package after API review and hardware validation. It is currently a local path dependency and is not yet available in the Toit registry.

Measurements preserve native chip axes. Acceleration includes gravity and is in
**m/s²**; angular velocity is in **rad/s**. Vectors use the standard library's
`math.Point3f`, with `.x`, `.y` and `.z`. No calibration, filtering, axis remapping
or background sampling is hidden in the driver.

## Quick start

```toit
import lsm6ds3 as imu

sensor := imu.Driver (bus.device imu.ADDRESS-HIGH)
sensor.configure
    --accel-rate=imu.Driver.RATE-104HZ
    --gyro-rate=imu.Driver.RATE-104HZ
    --accel-range=imu.Driver.ACCEL-RANGE-4G
    --gyro-range=imu.Driver.GYRO-RANGE-500DPS
// Allow startup settling before relying on the output; see examples/read.toit.
sample := sensor.read-6-axis
print "acceleration: $(sample.acceleration.x) m/s^2"
print "angular velocity: $(sample.angular-velocity.z) rad/s"
```

[examples/read.toit](examples/read.toit) includes bounded reset polling, direct
measurements and FIFO acquisition. From `examples/`, install dependencies with
`jag pkg install`, then run `jag run --device <device> read.toit`. Adapt pins and
pull-ups. On RH2 use the combined motion demo so the sensors and V3 share one
bus owner.

## Configuration

`configure` configures both sensors and **leaves FIFO stopped**. Parameters take
named `Driver` constants, not physical rates or register addresses. Constants
are integer enum equivalents, following established Toit driver conventions.
Each call replaces the complete sensor profile; omitted parameters use defaults.

| Parameter | Named values | Default |
| --- | --- | --- |
| `--accel-rate` | `RATE-OFF`, `RATE-12-5HZ`, `RATE-26HZ`, `RATE-52HZ`, `RATE-104HZ`, `RATE-208HZ`, `RATE-416HZ`, `RATE-833HZ`, `RATE-1660HZ`, `RATE-3330HZ`, `RATE-6660HZ` | `RATE-104HZ` |
| `--gyro-rate` | Same rates through `RATE-1660HZ`; `RATE-OFF` powers down gyro | `RATE-104HZ` |
| `--accel-range` | `ACCEL-RANGE-2G`, `ACCEL-RANGE-4G`, `ACCEL-RANGE-8G`, `ACCEL-RANGE-16G` | `ACCEL-RANGE-8G` |
| `--gyro-range` | `GYRO-RANGE-125DPS`, `GYRO-RANGE-245DPS`, `GYRO-RANGE-500DPS`, `GYRO-RANGE-1000DPS`, `GYRO-RANGE-2000DPS` | `GYRO-RANGE-1000DPS` |
| `--accel-power`, `--gyro-power` | `POWER-HIGH-PERFORMANCE`, `POWER-NORMAL` | `POWER-HIGH-PERFORMANCE` |
| `--accel-bandwidth` | `null` for ODR-dependent selection; `BANDWIDTH-400HZ`, `BANDWIDTH-200HZ`, `BANDWIDTH-100HZ`, `BANDWIDTH-50HZ` for manual accelerometer anti-alias bandwidth | `null` |

Ranges are bipolar full scales; DPS means degrees/second **configuration**, not
output units. High rates require high-performance mode: normal mode is limited
to 208 Hz. Block-data update (BDU), little-endian output and register auto-increment
are enforced. Conversion factors follow the selected ranges; standard gravity
is 9.80665 m/s². `accel-rate-hz`, `gyro-rate-hz`, `accel-range` and `gyro-range`
report the configured profile. Module constant `SAMPLE-RATE` means the default
104 Hz only; use the getters for configurable applications.

Invalid parameters are rejected before writing registers. A transport failure
partway through configuration invalidates converted reads until `configure`
succeeds. Reset, reconfiguration and FIFO restart break the acquisition timeline.
The application owns sensor/filter settling and timestamp discontinuities.

## Immediate and fresh measurements

| Method/property | Result and behavior |
| --- | --- |
| `read-now` | Immediate `Sample` from the latest output registers; does not wait for new data |
| `read-6-axis` | Same snapshot, requiring both sensing channels enabled |
| `read-3-axis --sensor=Driver.SENSOR-ACCELEROMETER` | Immediate `math.Point3f` in m/s²; default selection |
| `read-3-axis --sensor=Driver.SENSOR-GYROSCOPE` | Immediate `math.Point3f` in rad/s |
| `read-acceleration`, `read-angular-velocity` | Explicit names for the corresponding immediate vector reads |
| `read-if-ready`, `read` | `Sample` when every enabled sensor is ready; otherwise `null`; never waits |
| `status` | `Status` with `acceleration-ready`, `gyroscope-ready`, `temperature-ready` and register `raw` |
| `data-ready` | True when every enabled channel has new data |
| `read-raw-acceleration`, `read-raw-angular-velocity` | Three signed 16-bit counts in a `List`, without conversion |
| `convert-acceleration raw`, `convert-angular-velocity raw` | Convert a signed 16-bit count to m/s² or rad/s using the current range; no bus I/O |
| `read-raw-temperature`, `read-temperature`, `read-temperature-fahrenheit` | Signed counts, °C, °F; chip temperature, not calibrated ambient temperature |

`Sample.acceleration` and `.angular-velocity` are `math.Point3f` values, or `null`
when a channel is absent. Scalar getters `.ax/.ay/.az/.gx/.gy/.gz` are also
available; accessing a missing channel throws `CHANNEL_NOT_IN_FRAME`.
`Sample.clipped` flags a count within eight counts of an ADC rail. Reading a
powered-down channel through a converted direct-read method throws.

Immediate reads can return the same measurement repeatedly. BDU protects output
words during a read; it does not make sensors at different rates simultaneous.
Reading outputs consumes their ready flags. Avoid multiple competing consumers
of readiness/output registers. Use FIFO for ordered motion integration; output
register reads are not a substitute for timestamped history.

## Hardware FIFO

`Driver.HAS-FIFO` is true. Configure sensors first, then start acquisition:

```toit
sensor.start-fifo
    --mode=imu.Driver.FIFO-CONTINUOUS
    --rate=imu.Driver.RATE-104HZ
    --watermark-words=96
frames := sensor.read-fifo --max-frames=8
frames.do: | sample/imu.Sample |
  print "$(sample.ax),$(sample.ay),$(sample.az)"
sensor.stop-fifo
```

| `start-fifo` parameter | Values / meaning | Default |
| --- | --- | --- |
| `--mode` | `FIFO-CONTINUOUS` overwrites oldest data; `FIFO-STOP-WHEN-FULL` preserves a full capture; `FIFO-CONTINUOUS-TO-FIFO` and `FIFO-BYPASS-TO-CONTINUOUS` require separate trigger setup | `FIFO-CONTINUOUS` |
| `--rate` | Any nonzero `RATE-*`; `null` selects the faster configured sensor rate | `null` |
| `--watermark-words` | 0–4095 **16-bit words**, not bytes or frames | 0 |
| `--accel-decimation`, `--gyro-decimation` | `FIFO-NOT-STORED`, `FIFO-NO-DECIMATION`, `FIFO-DIV-2`, `FIFO-DIV-3`, `FIFO-DIV-4`, `FIFO-DIV-8`, `FIFO-DIV-16`, `FIFO-DIV-32` | `FIFO-NO-DECIMATION` |
| `--stop-on-watermark` | Stop insertion at a nonzero watermark | false |

A paired XYZ gyro + XYZ acceleration frame uses six words. An acceleration-only
or gyro-only frame uses three. Exclude a powered-down sensor explicitly, e.g.
`--gyro-decimation=imu.Driver.FIFO-NOT-STORED`. At least one sensor must be stored.
FIFO configuration excludes temperature and embedded-function datasets.

`read-fifo --max-frames=4` returns a list of complete `Sample` frames, with a
maximum batch of 16. It supports one or both sensors **at the FIFO rate, without
decimation**. It rejects incompatible patterns with
`FIFO_PATTERN_REQUIRES_RAW_READ`. The first frame after each restart is discarded
because it can straddle the mode change; an empty list is normal initially.

`fifo-status` returns `FifoStatus`: `words` (unread count), `pattern` (next word's
position in the repeating hardware pattern), `watermark`, `overrun`, `full`,
`empty` and register `flags`. A full FIFO is readable in stop-when-full mode;
an overrun means ordered history has been lost. Decoded reads reject overruns
before/after the transfer and nonzero starting patterns. After a read,
`pending-frames` estimates complete frames left at the status snapshot; it is
neither a timestamp nor a precise backlog age.

For mixed rates, decimation or custom decoding, use
`read-fifo-raw --max-words=32` (1–256 words per call). Its `FifoChunk` contains
starting `.status` and a `.words` list of signed counts. The caller interprets
the hardware pattern and sample timing; `convert-acceleration` and
`convert-angular-velocity` scale individual counts using the current ranges.
Raw reads do not discard the
first frame and clear `pending-frames`, since frame size is application-defined.

`stop-fifo` clears the FIFO while leaving sensors running. `restart-fifo` clears
and starts the last successful FIFO profile; it requires a prior `start-fifo`.
`configure`, `reset` and sensor `stop` invalidate that saved profile. A failed
FIFO reconfiguration also invalidates the saved profile, so it cannot restart
with partially changed decimation settings. After a FIFO/I2C error,
discard the failed batch, restart acquisition and break the integration timeline.
At high rates, select a bus speed and drain cadence that prevent overruns.

## Interrupts, power and diagnostics

`configure-interrupt` routes readiness/FIFO events to a sensor interrupt pin.
Named booleans `--acceleration-ready`, `--gyroscope-ready`, `--fifo-watermark`,
`--fifo-overrun`, `--fifo-full` default false. `--pin` selects 1 (default) or 2;
`--temperature-ready` is supported only on pin 2. `--active-low` and `--open-drain`
default false and affect both interrupt outputs. No host GPIO or ISR is installed.
Unrelated routing bits are preserved.

`set-self-test --accelerometer=... --gyroscope=...` accepts `SELF-TEST-OFF`
(default), `SELF-TEST-POSITIVE` or `SELF-TEST-NEGATIVE`. It only enables the hardware
stimulus: follow the datasheet's settling, baseline and acceptance procedure;
this is not an automatic pass/fail test.

`stop` stops FIFO and powers down both sensing channels while retaining ranges;
call `configure`, then `start-fifo` if required, to resume. `reset` requests
software reset; poll `reset-pending` with a deadline before configuration.
`identity` must be `0x69`. Addresses are seven-bit `ADDRESS-LOW` (`0x6a`, SA0 low)
and `ADDRESS-HIGH` (`0x6b`, SA0 high). **LSM6DS3TR-C** (identity `0x6a`) and other
LSM6 variants are not supported; an I2C address is not a chip identity.

## Transport and scope

`Driver` accepts an `i2c.Device` or fake providing `read-reg` and `write`.
`Driver.from-registers` accepts an object providing `read-bytes`/`write-bytes`,
such as the Toit `serial.Registers` interface. The caller owns transport setup,
lifetime and locking, including serialization of complete read/modify/write
methods on a shared bus. The adapter does not configure SPI transactions; the
provided hardware example is I2C. Drivers create no tasks and never close the bus.

`read-register address --size=1`, `write-register address bytes` and
`update-register address mask value` expose advanced registers. Writes that
change ranges, byte order, axes or FIFO settings invalidate high-level assumptions;
reconfigure before returning to converted reads. Transport errors propagate;
short reads throw `LSM6DS3_SHORT_READ`. No retry hides missing samples.

The typed API covers general acquisition; embedded pedometer, tap/free-fall,
sensor-hub and advanced digital-filter configuration require register-level
code. Hardware validation of the additional rates/modes remains necessary.

## Tests and references

From `tests/`, run `jag pkg install` then `jag toit run driver-test.toit`.
Register-fake tests cover ranges/rates and SI scaling, immediate/fresh reads,
power, temperature, interrupts, self-test bits, FIFO modes/patterns and transport
failures. They do not establish electrical compatibility or sustained bus timing.

API conventions were compared with the Toit
[LSM303D](https://github.com/toitware/toit-lsm303d/tree/main/src),
[MPU6050](https://github.com/milkmansson/toit-mpu6050/blob/main/src/mpu6050.toit)
and [LIS3DH](https://github.com/nilwes/LIS3DH/blob/main/src/lis3dh.toit) drivers.
The acquisition surface was compared with
[SparkFun's Arduino driver](https://github.com/sparkfun/SparkFun_LSM6DS3_Arduino_Library).
Register facts and conversion factors follow
[ST's LSM6DS3 reference driver](https://github.com/STMicroelectronics/lsm6ds3-pid).
See [package publishing notes](../README.md) before publishing independently.
