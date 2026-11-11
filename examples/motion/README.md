# Motion processing on RH2

Run [rh2.toit](rh2.toit) to explore IMU processing on an ESP32-C6:
read an LSM6DS3 accelerometer/gyroscope and LIS2MDL magnetometer, estimate
orientation as a quaternion, and display motion features or a compass on RH2.
The ESP32 and STM32 V3 communications share the same I2C bus.

Horse motion motivates the features. The example extracts signal measurements;
it supplies no trained model, gait labels, stride identification or lameness
assessment. Device placement and real recordings are needed to establish what
these measurements mean for a particular application.

Read [VALUES.md](VALUES.md) for every displayed value, CSV column, quality
indicator and optional diagnostic. Start with Time domain and magnetic heading
off; add calibration and frequency analysis once the basic signals make sense.

## Run

From the repository root, with Jaguar and a compatible RH2 Toit image installed:

```sh
cd examples
jag pkg install
jag toit analyze motion/rh2.toit
jag run --device <your-device> motion/rh2.toit
```

Stop any other container owning GPIO6/7 or the screen first. Run this launcher
as the sole bus/screen owner. The installed STM32 firmware must support RH2
Home/menu pages, buffered drawing, partial refresh, button subscriptions, V3
OPEN/heartbeats and charger settings. This example does not update that firmware.

Home → **Right / Actions** opens Motion apps. Left/Right move through the menu;
Middle opens the selected app. Hold Right in the menu to return Home.

| App | Live processing | Display |
| --- | --- | --- |
| Time domain | Statistics, crossings, adaptive peaks, autocorrelation | Vector RMS, vertical RMS, repetition rate, regularity |
| Frequency Domain | Statistics, crossings, FFT and band power | Strongest spectral bin, vertical RMS, two power bands |
| Compass | Quaternion fusion and magnetic heading reference | North arrow, roll, pitch and bearing |

In either analysis app, Left/Right cycle the feature, orientation and quality
pages. **Middle returns to Motion apps.** Compass uses Middle to return too.
Sensors stop in Home and menus. Switching apps reuses the completed gyro bias
and magnetic calibration choice during this container session.

## Calibration

Setup starts when the first app opens, not at boot.

1. Choose **Left** to skip magnetic calibration and keep heading off, or
   **Middle** to calibrate. If saved coefficients exist, Middle reuses them
   and Right starts a new calibration.
2. Turn slowly through all orientations, showing each face upward. Allow at
   least 20 seconds. X/Y/Z bars show axis-span progress; full bars alone do
   not establish good coverage. Left cancels.
3. Review the **0–100 quality score**, then save/use, redo or skip. The fit
   estimates a hard-iron offset and diagonal axis scales. It can accept an
   imperfect result; the score measures field-norm consistency, not heading
   accuracy. There is no full cross-axis soft-iron fit.
4. Hold still for roughly two seconds for gyro bias, followed by two seconds
   of fusion warmup. Analysis then collects its first 256-sample window;
   Compass starts without waiting for an analysis window.

The device sets the charge-current limit to zero during a new magnetic capture,
then restores and verifies the original limit on success, cancel or error.
There is no need to unplug. Zero current does not guarantee that charger
switching stops; changing charging state can still affect the measured field.

Before pausing charging, calibration saves the original current limit in flash.
Normal completion, cancel and error restore and verify that limit, then clear
the recovery record. If the container is forcibly stopped, opening a motion app
on the next run restores the pending limit before setup continues. There is no
separate restoration program. Failed recovery stops setup and keeps its saved
limit for another attempt after restarting the container.

A new magnetic capture needs writable flash for this recovery record; if
storage is unavailable, skip magnetic calibration and use six-axis fusion.
Calibration coefficients and recovery state share the `lightbug/motion` bucket.
Legacy coefficients can have an unknown quality score. A new container learns
its own startup gyro bias; sensor gaps and app switching never relearn that bias.

## Hardware and coordinate contract

| Connection | RH2 setting |
| --- | --- |
| Shared I2C | GPIO6 SDA, GPIO7 SCL, 100 kHz |
| STM32 V3 target | `0x1b` |
| LSM6DS3 target / identity | `0x6b` / `WHO_AM_I = 0x69` |
| LIS2MDL target / identity | `0x1e` / `WHO_AM_I = 0x40` |
| IMU profile | 104 Hz nominal, ±8 g, ±1000 degrees/s; polled FIFO |
| Magnetometer profile | 10 Hz continuous with block-data update |

One ESP I2C controller owns all three targets. The SDK transaction lock protects
sensor register operations and V3 transfers; waits, fusion, FFT and display
ACK waits occur outside sensor transactions. IRQ wires are not needed here.

The drivers return **m/s²**, **rad/s** and **µT**. Accelerometer values are
specific force: a stationary sensor reports roughly 9.80665 m/s² upward.
The RH2 body frame defaults to LSM6DS3 axes: **+X down, +Y right, +Z forward**
when held upright. Upright specific force is therefore approximately
`(-9.80665, 0, 0)`. Face-up, it is approximately `(0, 0, +9.80665)`.

The LIS2MDL's native axes are left-handed; its RH2 Y direction is opposite the
IMU's. `settings.magnetic-to-imu` converts `(mx,my,mz)` to `(mx,-my,mz)` before
applying the common mounting rotation. Keep this handedness conversion separate
from `AxisMap`, which accepts only proper rotations. Confirm the mapping on
another board/revision. [ST's axis explanation](https://community.st.com/mems-sensors-48/lis2mdl-axis-directions-37653)
describes the native magnetometer convention.

Quaternions are Hamilton **(w,x,y,z)** and rotate **body into world**.
World +Z is up; with magnetic reference, +X is magnetic north and +Y is west.
Without magnetic reference, horizontal yaw is arbitrary and drifts.
Linear acceleration is `q.rotate(specific_force) - (0,0,9.80665)`.

## Processing choices and limits

The fusion package uses gyro integration with proportional gravity and optional
magnetic yaw feedback. It is a small complementary filter, not an implementation
of Madgwick, Mahony or x-io Fusion. Gravity feedback is accepted when acceleration
magnitude is within 15% of gravity. Sustained acceleration can still produce
incorrect tilt; magnitude gating cannot identify every disturbance.

The analysis apps use 256 samples (2.462 s) with a 128-sample hop (1.231 s).
FFT spacing is 0.40625 Hz. Repetition estimates use signed, demeaned world-vertical
acceleration; vector RMS also includes the other two axes. Autocorrelation
averages/decimates four samples to 26 Hz before searching 0.5–5 Hz. Its limited
anti-alias filtering and short overlap at low frequencies need evaluation on
impact-rich recordings. Thresholds are example noise floors, not gait boundaries.

Time domain omits the FFT; Frequency Domain omits peaks and autocorrelation.
Compass offers live poses up to 10 times/s and bypasses analysis windows.
It seeds yaw from the first accepted field, then blends magnetic corrections
with a 0.3 s time constant while the gyro tracks intervening motion. Analysis
apps retain the fusion package's slower, sparse-sample magnetic feedback.
Both paths reject clipped/overrun readings, relative field strengths outside
60–140% of the fitted radius, and nearly vertical magnetic reference fields.
Neither applies declination or provides validated magnetic-disturbance detection.

The FIFO retains sample order and uses nominal 104 Hz time steps. Sensor clock
error affects frequency estimates. FIFO errors, saturation and stale backlog
invalidate the window; missing samples are not stitched together. Startup bias
is retained, but orientation cannot reconstruct motion missed during a gap or
while browsing menus. Feedback must settle it again, especially unreferenced yaw.

Analysis and drawing run separately from acquisition. The report queue holds
one pending window and the display holds one pending frame; newer work replaces
older pending work. FFT/correlation yield to acquisition. Display frames use
buffered commands and a partial flush, with all acknowledgements checked.
Compass caches dial images and sends only changed pixel rectangles, each within
V3's 255-byte field limit. Its two-request ACK window bounds in-flight traffic.
A page transition uses a separate clear command and full refresh.

Visible latency includes acquisition/windowing, command ACKs, STM32 scheduling
and panel refresh. Faster pose production is not a panel refresh-rate guarantee.
The Toit app cannot control installed STM32 waveform or RAM-sync costs.
An e-ink ACK can precede physical refresh completion. Field use still needs
sustained shared-bus testing, heading verification and mounting-specific recordings.

## Read and adapt the code

```text
rh2.toit → session.toit → acquisition.toit → analysis.toit
                      ↘ calibration.toit
acquisition → drivers → axis conversion → gyro bias → quaternion fusion
            → analysis results or live Compass pose → display.toit
```

| File | Subsystem |
| --- | --- |
| `rh2.toit` | Startup wiring, Home/menu flow and app selection |
| `session.toit` | Shared sensor initialization, lifecycle and calibration choice |
| `acquisition.toit` | FIFO draining, startup gyro bias, fusion, gaps and bounded reporting |
| `analysis.toit` | Time-domain features and FFT/PSD workspace |
| `calibration.toit` | Magnetic calibration, fit quality, persistence and charging pause/recovery |
| `display.toit` | Display worker, button-event inbox and incremental sparklines |
| `compass.toit` | North projection, tilt geometry and incremental dial graphics |
| `settings.toit` | App identities, mounting, logging and startup/backlog limits |

`packages/lsm6ds3`, `packages/lis2mdl` and `packages/motion-fusion` are independent
local packages, each with its own README, license, example and tests. They remain
path dependencies while we prepare the sensor drivers for publication in the
Toit registry. We also intend to publish the fusion package if validation supports
it; see [package notes](../../packages/README.md).

For another mounting, edit `imu-axes` and verify signs before interpreting
vertical features. Compass screen geometry assumes the default RH2 axes.
To add an app, extend the app identities in `settings.toit`, select its processing
in acquisition, and provide its display path. Keep sampling independent from slow rendering.
`LOG-FEATURES` enables analysis CSV. `LOG-DIAGNOSTICS` enables detailed calibration,
Compass health and display timings; it defaults off. Errors always remain visible.

## Build a customer motion app

Start with Time domain and six-axis fusion. Use the native sensor packages alone
when an application only needs acceleration magnitude, impacts or angular rate;
quaternion fusion is useful when features need a world-vertical direction.
Magnetic heading adds a calibration and interference dependency and is only
necessary when the application needs an absolute horizontal reference.

Keep new feature calculations in the reporting task (`analysis.toit` and
`Sampler.report_`), outside `with-i2c`. Select the required calculations in
`Sampler.configure-app`; Compass demonstrates bypassing the window/FFT path.
The single pending report is deliberately replaceable: acquisition takes
priority over displaying every result. An application requiring lossless capture
needs a separately budgeted storage/export path, not a larger display queue.

For a new deployment:

1. Fix and record mounting, units, sensor ranges/rates and firmware revision.
   Check all six stationary faces and rotation signs. Keep body and screen
   frames distinct if changing mounting; Compass assumes RH2 screen axes.
2. Record labelled motion sessions and static baselines. The feature CSV is
   useful for inspecting this demo, but cannot reproduce fusion or retune filters:
   retain raw accel/gyro/magnetic samples with timing, discontinuities and
   calibration coefficients when collecting a development dataset. Avoid
   synchronous per-sample console output in the acquisition task.
3. Compare candidate features with those recordings before choosing thresholds.
   Keep each acquisition generation separate, and split evaluation by recording
   or animal rather than treating overlapping windows as independent examples.
4. Measure end-to-end latency and dropped data with the intended display,
   communications and power state. Calculation time alone is not responsiveness.

`settings.SAMPLE-RATE` is the shared nominal time base for integration and
analysis. Session checks that the selected IMU ODR matches it. Changing rate also
requires changing the explicit hardware settings, checking window duration,
frequency resolution, magnetic polling and FIFO/bus load. A lower rate requires
appropriate sensor bandwidth to avoid aliasing; software downsampling alone
does not remove frequencies above the new Nyquist limit.

The existing signal features are a suitable starting set. Displacement from
double integration, gait labels and harmonic symmetry scores need additional
assumptions and validation; adding them without reference recordings would make
the demo harder to interpret. The current fusion uses a simple proportional
correction and first-order integration. Applications requiring validated dynamic
heading or navigation should evaluate a more complete estimator against the same
recordings (see the public AHRS references below).

## Check changes

From the repository root:

```sh
cd tests
jag pkg install
cd ..
for test in tests/motion/*.test.toit; do jag toit run "$test" || exit 1; done
jag toit analyze examples/motion/rh2.toit
jag toit compile --snapshot -O2 -o /tmp/rh2-motion.snapshot examples/motion/rh2.toit
```

Host tests exercise synthetic rhythms, PSD normalization, coordinate signs,
calibration/charger failures, FIFO recovery, app navigation, queue bounds and
real V3 serialization/ACK behavior with a simulated peer. They do not establish
physical sensor accuracy, horse-gait validity or panel performance.
On RH2, check six stationary faces, positive rotations, saved/skip calibration,
app switching without repeated gyro calibration, charging restoration and a
sustained moving run. Evaluate raw recordings separately before using summary
features for a field application.

## Related public examples

These are useful comparisons; this demo does not copy or depend on their code.

- [x-io Fusion](https://github.com/xioTechnologies/Fusion): explicit frame conventions,
  calibration, rejection/recovery states and gravity-removed acceleration. It
  provides a more complete AHRS than this example's small proportional filter.
- [Adafruit calibrated orientation](https://github.com/adafruit/Adafruit_AHRS/blob/master/examples/calibrated_orientation/calibrated_orientation.ino):
  calibration before fusion, explicit gyro-unit conversion, and separate filter
  and output cadences. Here the fusion input is rad/s and output has its own task.
- [Arduino Madgwick visualization](https://github.com/arduino-libraries/MadgwickAHRS/blob/master/examples/Visualize101/Visualize101.ino):
  fixed sensor/filter rates and raw-unit conversion. Its six-axis heading output
  should not be treated as an absolute north reference.
- [Seeed LSM6DS3 example](https://github.com/Seeed-Studio/Seeed_Arduino_LSM6DS3/blob/master/examples/HighLevelExample/HighLevelExample.ino):
  a small sensor bring-up example. This driver additionally uses coherent FIFO
  frames so gyro and acceleration order are explicit during motion processing.
- [arduinoFFT's synthetic example](https://github.com/kosme/arduinoFFT/blob/master/Examples/FFT_05/FFT_05.ino):
  controlled sinusoidal input, windowing, FFT and dominant-peak extraction. Here
  synthetic tests additionally check normalized PSD/band power, rather than
  treating FFT magnitude as acceleration variance.
