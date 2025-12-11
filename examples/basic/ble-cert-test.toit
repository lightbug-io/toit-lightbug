import ble

// A basic BLE peripheral that advertises a custom name and manufacturer-specific data.
// Used for testing RH2 certificate functionality.
// Does not require or make use of any Lightbug specific features.
main:
  print "Starting BLE Certificate Test Peripheral"
  adapter := ble.Adapter
  peripheral := adapter.peripheral

  data := ble.Advertisement --name="RH2 Cert test" --manufacturer-specific=#[0xFF, 0xFF, 'L', 'B', 'T', 'E', 'S', 'T']

  peripheral.start-advertise data --interval=(Duration --ms=500)

  while true:
    sleep --ms=1_000