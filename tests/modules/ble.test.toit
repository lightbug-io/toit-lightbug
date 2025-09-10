import lightbug.modules.ble as ble_mod
import log

// Shared variables set by main to indicate availability and instance
b := null
skipMsg := null

main:
  // Attempt BLE constructor once here so we can skip early for unsupported platforms
  e := catch:
    b = ble_mod.BLE --logger=(log.default.with-name "test.ble")

  if e:
    msg := e.stringify
    if msg.contains "Unsupported platform" or msg.contains "unsupported" or msg.contains "not supported" or msg.contains "no BLE":
      skipMsg = "⚠️ SKIPPED: BLE not available on this platform: $(msg)"
      print skipMsg
      return
    print "❌ BLE constructor errored: $(msg)"
    return

  // If BLE available, continue to run the tests
  testBleScan


testBleScan:
  // Perform a 1 second scan (1000 ms)
  results := []
  err := catch:
    results = b.scan --duration=1000

  if err:
    print "❌ BLE scan errored: $(err.stringify)"
    return

  // Ensure the scan completed and found at least one device
  if results.size >= 1:
    print "✅ BLE scan returned $(results.size) devices"
  else:
    print "❌ BLE scan returned no devices (found=$(results.size))"
