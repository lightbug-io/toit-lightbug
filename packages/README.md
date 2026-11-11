# Reusable motion packages

`lsm6ds3`, `lis2mdl`, and `motion-fusion` are independent local Toit packages.
Each has `src/`, an MIT `LICENSE`, API documentation, a standalone example,
and standalone host tests. None depends on Lightbug or on another local package.
The top-level test suite also runs their tests, and `make analyze-examples`
analyzes their examples alongside the Lightbug examples.

| Package | General-purpose API |
| --- | --- |
| [lsm6ds3](lsm6ds3/README.md) | Named rates/ranges/power/bandwidth; immediate three/six-axis SI measurements; decoded or raw FIFO; temperature, interrupts and self-test stimulus |
| [lis2mdl](lis2mdl/README.md) | Named rates/modes/power/filter; continuous or single-shot magnetic vectors; temperature, hardware offsets, threshold interrupts and self-test stimulus; no hardware FIFO |
| [motion-fusion](motion-fusion/README.md) | Quaternion attitude estimation, explicit frames/units and optional magnetic feedback |

The drivers return standard `math.Point3f` vectors and retain native sensor axes.
Their named configuration values follow the conventions of existing Toit sensor
drivers. Configuration and acquisition are separate: IMU FIFO is started
explicitly, while the magnetometer can be configured continuous, single or idle.
The RH2 demo selects its own acquisition profile above these reusable APIs.

We intend to publish the LSM6DS3 and LIS2MDL drivers as independent Toit
packages, and to publish motion-fusion separately if validation supports it.
The [combined RH2 example](../examples/motion/README.md) uses path dependencies
to exercise these packages before publishing them. A Toit public package is
identified by its own Git repository URL and version tag; these folders are
staging locations, not three packages already available from the registry.

To publish each package independently:

1. Complete the documented board validation and review the API. Host tests cover
   the expanded configurations, but additional rates, interrupt wiring and
   single-shot/FIFO modes still need hardware validation. Avoid promising support
   for untested chip-family variants or transports.
2. Copy the package directory into its own Git repository, retaining its
   LICENSE, README, examples, and tests. This layout needs no source import
   rewrites. Regenerate its example/test lockfiles with `jag pkg install`.
3. Run its host tests and analyze/compile its example in that independent
   checkout. For drivers, exercise the example on the supported sensor.
4. Commit, tag a semantic version, push the repository, and submit it to the
   Toit registry following the [official package guide](https://docs.toit.io/language/package/pkgguide/).
5. Replace the combined example's path dependencies with the published URLs and
   version constraints; reinstall to regenerate its lockfile.

Registry publication and repository creation are separate release actions; no
public repositories, tags, releases, or registry submissions are created here.

## Release evidence

The package layout, permissive licenses, separate example/test projects and
named APIs follow the [Toit package guidance](https://docs.toit.io/language/package/pkgguide/).
This is an engineering starting point, not a certification against an IMU or
navigation standard. Register-fake tests establish software behavior; they do
not establish sensor accuracy or electrical timing.

Before the first public tag, record these results in each package README:

| Check | Evidence to retain |
| --- | --- |
| Compatibility | Exact chip identity/part, board, bus speed, Toit/Jaguar versions; distinguish tested settings from exposed API settings |
| Accelerometer | Six stationary faces at each supported range: expected dominant axis/sign, norm near local gravity, bias/noise and clipping observations |
| Gyroscope | Stationary bias/noise and independently measured positive/negative rotations; output units and range scaling |
| Magnetometer | Continuous and single-shot readiness/overrun behavior, repeatability at fixed poses, offset subtraction and independent heading reference after calibration |
| FIFO | Single/paired channels, supported rates, decimation/raw pattern, watermark/full behavior, delayed reader and overrun recovery |
| Interrupts/self-test | Physical pin polarity/routing and the manufacturer's self-test procedure and limits; enabling stimulus alone is not a self-test result |
| Failure recovery | NACK, reset and interrupted configuration; no stale scaling/decoder state after retry |
| RH2 endurance | Suggested 30-minute moving run with app switching and V3/display active: gaps, drops, latency distribution, charging restoration and stable memory usage |

Compare measurements with the manufacturer's limits for the selected mode and
operating conditions. Preserve raw results and test conditions; do not turn a
single board's observed noise into a promised accuracy specification.

The current repository CI runs host tests and analyzes examples. When splitting
these packages into their own repositories, carry those checks across and pin a
validated SDK version. Validate an independent checkout using only that package's
example/test dependencies. Record the oldest tested SDK rather than claiming
compatibility from successful compilation on one newer SDK. The RH2 bench runs
in this development session used alpha.199; the repository CI currently targets
alpha.198, which still needs a passing run for these changes.

Before freezing version 1.0, review naming/return contracts, raw versus converted
units, supported transports and error recovery. The primary methods are
`read-now` (snapshot) and `read-if-ready` (nullable poll) on both drivers.
`read` aliases the fresh-data poll on both. SPI setup and chip-family variants are not established by I2C tests.
