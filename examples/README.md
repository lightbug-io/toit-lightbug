# Examples

## Dependencies and compilation

The examples have their own `package.yaml` and `package.lock`.
Install their dependencies in the `examples` directory before compiling or installing a container:

```sh
jag pkg install
jag toit analyze containers/base-apps.toit
jag toit compile --snapshot -O2 -o /tmp/base-apps.snapshot containers/base-apps.toit
```

## Troubleshooting

Missing-package errors usually mean the dependency installation step above has been missed.