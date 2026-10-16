// Install once as a separate Jaguar container for development update cycles.
// Keeping the provider alive lets jag run replace app programs without also
// tearing down their watchdog service.
import watchdog.provider

main:
  provider.main
