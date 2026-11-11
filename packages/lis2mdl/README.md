# LIS2MDL

A general-purpose Toit I2C driver for the LIS2MDL three-axis magnetometer:
configurable continuous/single-shot acquisition, immediate measurements,
temperature, hardware offsets, threshold interrupts and self-test stimulus.
MIT licensed; no package dependencies.

We intend to publish `lis2mdl` as an independent Toit package after API review and hardware validation. It is currently a local path dependency and is not yet available in the Toit registry.

Values retain native chip axes and use **microtesla (µT)**. `Sample.field` is the
standard library's `math.Point3f`; `.x/.y/.z` scalar getters are also available.
Sensitivity is fixed at 0.15 µT/count. There is **no hardware FIFO** and no
programmable full-scale range; `Driver.HAS-FIFO` is false. The driver does not
invent a FIFO method that silently buffers stale readings in software.

## Quick start

```toit
import lis2mdl as mag

sensor := mag.Driver (bus.device mag.ADDRESS)
sensor.configure
    --rate=mag.Driver.RATE-20HZ
    --mode=mag.Driver.MODE-CONTINUOUS
    --power=mag.Driver.POWER-HIGH-RESOLUTION
// Poll later, after conversion startup; this does not wait.
sample := sensor.read-if-ready
if sample:
  print "$(sample.field.x),$(sample.field.y),$(sample.field.z) uT"
```

[examples/read.toit](examples/read.toit) shows bounded reset polling and fresh
measurements. From `examples/`, run `jag pkg install`, then
`jag run --device <device> read.toit`. Adapt pins/pull-ups. On RH2 use the combined
motion example to share bus ownership with V3.

## Configuration

`configure` takes named `Driver` constants (integer enum equivalents) rather
than register numbers. Each call replaces the complete profile; omitted
parameters use defaults.

| Parameter | Named values | Default |
| --- | --- | --- |
| `--rate` | `RATE-10HZ`, `RATE-20HZ`, `RATE-50HZ`, `RATE-100HZ` | `RATE-10HZ` |
| `--mode` | `MODE-CONTINUOUS`, `MODE-SINGLE`, `MODE-IDLE` | `MODE-CONTINUOUS` |
| `--power` | `POWER-HIGH-RESOLUTION`, `POWER-LOW` | `POWER-HIGH-RESOLUTION` |
| `--filter` | `FILTER-ODR-DIV-2`, `FILTER-ODR-DIV-4` low-pass bandwidth | `FILTER-ODR-DIV-2` |
| `--temperature-compensation` | Boolean; compensates magnetic sensitivity over temperature | true |
| `--set-reset` | `SET-RESET-EVERY-63`, `SET-RESET-OFFSET-CANCELLATION`, `SET-RESET-POWER-ON-ONLY` | `SET-RESET-OFFSET-CANCELLATION` |
| `--data-ready-pin` | Boolean; route data-ready to the sensor's output pin | false |

Set/reset controls the sensor's internal magnetic conditioning: every 63 output
conversions, offset-cancellation cycles, or only at power-on. It is unrelated to
software reset. In single mode the driver also configures single-shot offset
cancellation when selected. Internal offset cancellation does **not** replace
assembled-device hard-iron/soft-iron calibration.

Block-data update and little-endian output are enforced. `rate-hz` reads back
the configured rate; `operating-mode` reads the hardware mode (single mode
returns to idle automatically). An invalid parameter is rejected before writes.
A partial I2C configuration failure invalidates converted reads until a complete
`configure` succeeds. The caller allows startup/filter settling.

## Reading values

| Method/property | Result and behavior |
| --- | --- |
| `read-now` | Immediate `Sample` from current output registers, even when ready is false |
| `read-3-axis` | Immediate `math.Point3f` in µT |
| `read-if-ready`, `read` | Fresh-data poll: `Sample` when all axes are ready, otherwise `null`; never waits |
| `read-raw` | `List` of three signed 16-bit counts |
| `status` | `Status` with `data-ready`, per-axis `x-ready/y-ready/z-ready`, `overrun` and register `raw` |
| `data-ready` | All axes have new data |
| `read-raw-temperature`, `read-temperature`, `read-temperature-fahrenheit` | Signed counts, °C, °F; chip temperature, not calibrated ambient temperature |

`Sample` includes `.field`, `.x/.y/.z`, `.overrun` and `.clipped`. Status is read
before output registers so reading the output does not erase the overrun flag
before it is reported. `overrun` means intermediate samples have been lost;
applications decide whether the latest sample remains useful. `clipped` flags
a count within eight counts of an ADC rail.

Immediate reads can repeat an old sample. Output reads consume readiness;
avoid multiple competing consumers. A slow reader loses intermediate samples,
since the chip has no FIFO. Timestamps and synchronization with an IMU are the
application's responsibility.

## Single-shot acquisition and power

For an occasional measurement on an exclusively owned bus:

```toit
sensor.configure --mode=mag.Driver.MODE-IDLE
sample := sensor.read-single --timeout=(Duration --ms=500)
print "$(sample.x),$(sample.y),$(sample.z) uT"
```

`read-single` discards old output, triggers a conversion and polls every 2 ms.
It returns the fresh sample or throws `LIS2MDL_MEASUREMENT_TIMEOUT`, selecting
idle on timeout. It yields while waiting and takes no internal lock. Conversion
rate, power and filtering remain as configured.

For a shared bus, call `trigger` in one locked transaction, release the bus,
and later call `read-if-ready` in another transaction. Do not hold a shared-bus
lock around the blocking `read-single`. `trigger` clears stale output first so
its ready flag belongs to a new conversion. Complete/cancel an outstanding
conversion before triggering another. `trigger` selects idle before clearing
old output, so it can also switch safely from continuous acquisition.

`start-continuous` resumes continuous measurements with existing settings.
`stop` selects idle, retaining rate/filter/temperature settings and bus ownership.
`configure --mode=MODE-SINGLE` also initiates one conversion; `MODE-IDLE` waits
for an explicit trigger or continuous start.

`reset` requests software reset; poll `reset-pending` with a deadline before
configuration. `reboot` reloads factory calibration; similarly wait for
`reboot-pending` to clear, then configure. Both invalidate driver configuration.
The fixed seven-bit I2C `ADDRESS` is `0x1e`; `identity` must be `0x40`.

## Offsets, interrupts and self-test

`write-offsets (math.Point3f x y z)` writes hardware user offsets in **native-axis
µT**, quantized to 0.15 µT/count; `read-offsets` returns the programmed vector.
The hardware subtracts these offsets from measurements. Values must fit signed
16-bit counts. This handles a constant offset, not a soft-iron matrix; avoid
subtracting the same offset again in application calibration.

`configure-interrupt --threshold=30.0` configures a native-axis magnetic threshold
in µT, rounded to the nearest count (0–4915.05 µT). Named booleans `--x`, `--y`,
`--z`, `--active-high`, `--latched` and `--enabled` default true. It configures the
sensor pin only; the host GPIO/ISR is caller-owned. Reading `interrupt-status`
acknowledges a latched interrupt and returns `active`, `overflow`, per-axis
`x-positive/y-positive/z-positive` and `x-negative/y-negative/z-negative`, plus
register `raw`. Data-ready routing is separate from the threshold generator.

`set-self-test true` enables hardware stimulus; `set-self-test false` disables
it. Baseline acquisition, settling and datasheet acceptance limits belong to
the caller. This method is not an automatic pass/fail test.

## Axes, calibration and transport

The native axes are **left-handed**, as
[ST confirms](https://community.st.com/mems-sensors-48/lis2mdl-axis-directions-37653).
Express readings in your fusion algorithm's right-handed frame before heading
calculation. For the RH2 layout, `(mx, -my, mz)` maps magnetic axes into IMU axes.
Apply native-axis calibration before remapping. This board-specific conversion
belongs above the driver; other layouts need their own mapping.

`Driver` accepts an `i2c.Device` or fake implementing `read-reg` and `write`.
`Driver.from-registers` accepts a `read-bytes`/`write-bytes` object, such as Toit's
`serial.Registers` interface. The caller owns transport setup, lifetime and
serialization of complete read/modify/write methods. The adapter does not set
up SPI transactions; the supplied hardware example uses I2C. No tasks are
created and the bus is never closed by the driver.

`read-register address --size=1`, `write-register address bytes` and
`update-register address mask value` expose advanced registers. Multi-byte I2C
transfers set the auto-increment subaddress bit. Raw writes can invalidate
high-level assumptions; reconfigure before returning to converted reads.
Transport errors propagate; short reads throw `LIS2MDL_SHORT_READ`.

Calibration fitting, magnetic-disturbance rejection, heading and fusion belong
above this driver. On-board currents and nearby magnetic materials can affect
the field even when electrical communication is correct.

## Tests and references

From `tests/`, run `jag pkg install` then `jag toit run driver-test.toit`.
Register-fake tests cover configurable modes/rates, µT scaling, ready/overrun
handling, temperature, offsets, interrupt routing, self-test bits, single-shot
stale-data rejection, timeout, reset/reboot and transport failures. The expanded
hardware modes still need target validation; host tests do not establish sensor
noise, electrical behavior or sustained timing.

API conventions were compared with the Toit
[LSM303D](https://github.com/toitware/toit-lsm303d/tree/main/src),
[MPU6050](https://github.com/milkmansson/toit-mpu6050/blob/main/src/mpu6050.toit)
and [LIS3DH](https://github.com/nilwes/LIS3DH/blob/main/src/lis3dh.toit) drivers;
general magnetic acquisition was compared with
[Adafruit's Arduino driver](https://github.com/adafruit/Adafruit_LIS2MDL).
Register behavior follows the
[ST reference driver](https://github.com/STMicroelectronics/lis2mdl-pid) and
[datasheet](https://www.st.com/resource/en/datasheet/lis2mdl.pdf).
See [package publishing notes](../README.md) before publishing independently.
