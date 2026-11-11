# What the motion values mean

This reference covers the [RH2 demo](README.md). Values describe device motion
and signal repetition. Mounting and gait determine their physical interpretation;
a repetition can represent a step, half-stride, full stride, impact or harmonic.
No value here establishes a gait class, hoof strike, symmetry or lameness.

## Displayed motion features

| Display | Meaning | Unit / interpretation |
| --- | --- | --- |
| RMS | Root mean square length of estimated gravity-removed 3D acceleration | m/s². Includes all axes and any remaining DC/fusion error; low while still, larger during movement |
| Vertical | RMS of **demeaned** world-vertical acceleration | m/s². Measures vertical fluctuation, with the window's mean removed |
| ACF | Repetition frequency inferred from an accepted autocorrelation peak | Hz, cycles/s; not a verified stride rate |
| Regularity | Overlap-normalized correlation at the accepted ACF lag | 0–1. Higher means that this waveform repeated more similarly at that lag; not a health score or probability |
| FFT | Strongest Hann-windowed spectral bin in the 0.5–5 Hz search range | Hz. Can be a harmonic; bin spacing is 0.40625 Hz |
| 0.5–3 Hz | Integrated power in the vertical acceleration band [0.5,3) Hz | m²/s⁴, a variance-like quantity; not a frequency or RMS |
| 3–10 Hz | Integrated power in [3,10) Hz | m²/s⁴. Larger high-band power can reflect sharper impacts or vibration |
| Number ending in `ms` | Latest analysis window's calculation wall time | Includes scheduling/yields; excludes sensor acquisition, fusion and display work |

`--` means unavailable. ACF and regularity both stay unavailable when no peak is
accepted, including quiet windows. FFT peak output is suppressed below the same
example vertical RMS floor of 0.15 m/s², but computed band powers remain available.
A tiny power may round to `0.00` on screen without being exactly zero.

Analysis windows contain 256 samples at nominal 104 Hz, or 2.462 s. A new window
starts every 128 samples, about 1.231 s. Overlap makes adjacent results correlated.
A transition affects more than one result, and a short window contains few cycles
near 0.5 Hz. Accepted ACF peaks require correlation ≥0.4; the first peak within
90% of the strongest candidate is preferred to reduce period-multiple ambiguity.
Frequency ranges overlap between real activities; there are no universal
walk/trot/canter/gallop thresholds in this example.

The FFT uses a one-sided, Hann-normalized power spectral density (PSD), in
m²/s⁴/Hz. Band power sums PSD × bin width. Hann weighting and excluded frequencies
mean that the two displayed powers need not sum to the unweighted time-domain
vertical variance. The first FFT bin inside the search range is 0.8125 Hz; the
nominal 0.5 Hz boundary is not an FFT bin. For offline comparison,
[SciPy's periodogram reference](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.periodogram.html)
describes density scaling and one-sided power. To match this implementation,
use `fs=104`, constant detrending, density scaling, and an explicit symmetric
Hann window `0.5−0.5*cos(2*pi*n/(N−1))`; a library's default window can differ.

## Sparklines and display state

A sweep plots one point/segment per successfully displayed result, not per IMU
sample. It has 96 adjacent pixel columns, about two minutes at the nominal
analysis cadence if every result is displayed. Skipped pending results can make the sweep span more time and miss brief changes;
column spacing is not a fixed wall-time interval when drawing is irregular.
Missing values break the trace. A new sample generation clears the plot.

| Trace | Fixed linear range |
| --- | --- |
| Vector RMS and vertical RMS | 0–40 m/s² |
| ACF and FFT frequency | 0–5 Hz |
| Regularity | 0–1 |
| Either power band | 0–1000 m²/s⁴ |

Above-range values clip graphically; the number still shows the measurement.
Small values may look flat at these scales. Change `display.PLOT-RANGES` for a
deployment; graph heights for different units are not comparable.
`GAP` marks a discontinuity in acquisition; `STALE` marks a pose/result too old
for live presentation. Neither means the gyro bias is being recalibrated.

## Compass and quaternion orientation

The left dial's **North** arrow projects magnetic north into the screen plane.
Screen up is body **−X**, right is **+Y**, and outward normal is **+Z**.
The arrow can point in a different direction from the bearing number when tilted:
the arrow is a screen projection; bearing is a horizontal projection.

| Value | Definition |
| --- | --- |
| Bearing | Clockwise magnetic bearing of the screen's top edge, projected horizontally; 0–359°, north = 0°, east = 90° |
| Roll | `atan2(up.y, up.z)` in degrees, where `up` is world-up expressed in the body frame; side-to-side tilt, −180° to +180° |
| Pitch | `atan2(-up.x, sqrt(up.y²+up.z²))` in degrees; top-edge tilt, −90° to +90° |
| `q w/x/y/z` | Unit Hamilton quaternion `(w,x,y,z)` rotating body vectors into world axes, sampled at the end of the reported window |
| Field | Calibrated magnetic-vector length in µT if coefficients are active; raw length if skipped |
| Mag cal: active | Coefficients are available. It does not mean that every magnetic reading was accepted or that heading accuracy is known |

Both roll and pitch are zero with the screen flat and face up. Pitch increases
when its top edge tilts upward. Roll increases when gravity-up tilts toward its
right edge. Roll is unavailable near vertical pitch; bearing is unavailable when
the top edge is nearly vertical. If north points nearly through the screen,
its screen arrow is unavailable. These are projection singularities, not sensor
failures. Roll can wrap between +180° and −180° when face down.

Without magnetic reference, yaw is arbitrary; tilt still uses gyro/gravity.
Compass hides north if it has not accepted a magnetic correction for two seconds.
`No magnetic reference`, `Tilt to show north arrow` and `STALE` explain why a
needle is missing. This is magnetic north; there is no true-north/declination
correction. A calibrated field can still be disturbed by device electronics,
charging, nearby objects or changing surroundings.

World +Z is up. With heading referenced, +X is magnetic north and +Y is west.
Without heading, world X/Y are arbitrary. Quaternion signs `q` and `−q` describe
the same rotation; individual components are not independent angle readings.

## Calibration and quality page

| Indicator | Meaning |
| --- | --- |
| X/Y/Z bars | Native magnetic axis span; each of five blocks represents 4 µT, reaching full at 20 µT. This is progress, not proof of complete orientation coverage |
| Calibration quality 0–100 | Heuristic from held-out field-norm RMS residual: approximately `max(0,100−200×relative_RMS_error)`; 100 is a consistent fitted field, not 100% heading accuracy |
| `Dir n/r` | Observed signed-axis caps versus the required coverage for that check. Training requires six caps; the smaller held-out set requires four |
| `Err n%` | RMS relative difference between corrected field length and fitted radius |
| `Bad n/m` | Number of checked readings whose relative length error exceeds 20%, out of the checked sample count |
| Generation | Sample-timeline ID, incremented after acquisition discontinuities and sessions. It is not a calibration count |
| `G n/256` | Samples in that window accepting gravity feedback |
| `M n` | Samples in that window accepting magnetic feedback; this is not magnetometer sample rate |
| Drops | Completed analysis windows replaced in the one-item pending report queue |
| MagOV | Cumulative reads reporting overwritten magnetometer data; not an exact count of lost samples |

Magnetic calibration uses four of every five readings for its fit and checks the
remaining readings without refitting. Samples are temporally related, so this
is a consistency check rather than independent accuracy validation. Imperfect
field consistency can be accepted after sufficient samples and coverage; inspect
the score and verify heading externally. Unknown saved quality appears as `null`.
The fit does not calibrate accelerometer scale, gyro scale or cross-axis errors.

## Analysis CSV

Enable `LOG-FEATURES` in `settings.toit`. Each analysis app prints a header when
opened and one row per reported window. Compass does not generate feature CSV.
Lines beginning with `#` are status/diagnostics, not CSV data.

| Column | Unit and definition |
| --- | --- |
| `generation` | Integer timeline ID described above |
| `first_sample` | First sample index of the window within that generation; may include indices consumed by startup calibration/warmup |
| `time_s` | `first_sample / 104`; nominal start-of-window sample time, not UTC or wall time since boot |
| `qw,qx,qy,qz` | Body-to-world quaternion at the **end** of this window; unitless |
| `gravity_updates` | Per-window accepted gravity feedback count, 0–256 |
| `magnetic_updates` | Per-window accepted magnetic feedback count |
| `mag_uT` | Latest field-vector length at the end of the window; may be retained from an earlier read |
| `mag_overruns` | Cumulative magnetometer overrun-read counter |
| `dropped_windows` | Cumulative replaced/unsent report count |
| `analysis_ms` | Feature calculation wall time in milliseconds, including task yields |
| `vector_rms_m_s2` | `sqrt(mean(ax²+ay²+az²))` for gravity-removed world acceleration; m/s² |
| `vertical_ac_rms_m_s2` | RMS of demeaned world-vertical acceleration; m/s² |
| `vertical_variance_m2_s4` | Population mean square of that demeaned signal; m²/s⁴; equals vertical RMS squared |
| `mean_svm_m_s2` | Mean raw specific-force magnitude; m/s²; includes gravity and is approximately 9.81 while still |
| `zcr_crossings_s` | Vertical zero crossings per second, using ±0.1 m/s² hysteresis; a sinusoid normally crosses twice per cycle |
| `peak_hz` | Rate from mean interval between adaptive vertical maxima; Hz; requires at least two intervals |
| `peak_interval_cv` | Population standard deviation of peak intervals divided by their mean; unitless |
| `acf_hz` | Accepted autocorrelation repetition frequency; Hz |
| `acf_regularity` | Normalized correlation at the accepted lag; unitless |
| `fft_hz` | Strongest Hann-windowed spectral bin in the search range; Hz |
| `power_0p5_3_m2_s4` | Integrated vertical PSD in [0.5,3) Hz; m²/s⁴ |
| `power_3_10_m2_s4` | Integrated vertical PSD in [3,10) Hz; m²/s⁴ |

`null` means uncomputed or unavailable, never zero. Frequency Domain leaves peaks
and ACF null; Time domain leaves FFT and band powers null. Quiet windows can also
suppress peak/frequency estimates. Overlapping counts/values must not be summed
as independent samples. SVM is acceleration magnitude, not kinetic energy.
Adaptive peaks use a moving mean/variance threshold, a 0.3 m/s² minimum margin
and a 150 ms refractory period; they are candidate signal events, not hoof strikes.

## Optional diagnostic lines

Set `LOG-DIAGNOSTICS = true` in `settings.toit`. Errors and charge-restoration
messages are printed regardless of this flag. Extra logging consumes time.

| Field / log | Meaning |
| --- | --- |
| `calibrated` | Magnetic coefficients are present; separate from completed startup gyro bias |
| `quality` | Saved magnetic fit score, or `null` if unknown/unavailable |
| `field_uT` | Latest corrected magnetic-vector norm, or raw norm when coefficients are absent |
| `magnetic_age_ms` | Wall time since the last **accepted** magnetic correction; −1 before the first |
| `overruns` | Cumulative magnetic overrun-read count |
| `sample_to_ack_ms` | Estimated newest pose/sample time to display ACK; not physical panel completion |
| `draw_ms` | Complete display-worker wall time for that frame |
| `compose_ms` | Whole preparation phase before the final panel-flush request |
| `batch_wait_ms` | Time waiting for exclusive use of the e-ink command batch |
| `build_ms` | Time constructing dial images, patches and commands |
| `buffer_ack_ms` | Time sending buffered commands and awaiting their responses |
| `flush_ms` | Time for the final flush request/ACK; visible panel refresh can finish later |
| `mag raw ms/x/y/z/norm` | Native uncalibrated magnetic readings during calibration; milliseconds since capture start and µT |
| `gyro bias rad/s` | Body-frame gyro offset after the configured mounting map, estimated once from quiet startup samples |

Timers use monotonic wall time, include scheduling effects, and are rounded to
milliseconds, so component sums can differ slightly. A zero time can mean no
changed commands or a duration below 1 ms. Sensor clock error, FIFO backlog and
the panel's ACK/physical-update relationship limit latency accuracy. Error logs
identify failed buffer element index/type/page and status or timeout; a failed
frame is not committed as a valid new baseline for incremental drawing.
