# Examples

## Dependencies and compilation

The examples have their own `package.yaml` and `package.lock`.
Install their dependencies in the `examples` directory before compiling or installing a container:

```sh
jag pkg install
jag toit analyze containers/base-apps.toit
jag toit compile --snapshot -O2 -o /tmp/base-apps.snapshot containers/base-apps.toit
```

## Motion processing

[The RH2 motion example](motion/README.md) combines shared-bus V3 communications,
LSM6DS3/LIS2MDL acquisition, quaternion fusion, and time/frequency features.
It includes guided e-ink magnetometer calibration, Time domain, Frequency Domain
and Compass apps, and reusable sensor/fusion packages. Run `motion/rh2.toit` and
press Home → Right / Actions to select an app. See the demo's
[value reference](motion/VALUES.md) for units, conventions and interpretation.

## Troubleshooting

Missing-package errors usually mean the dependency installation step above has been missed.
