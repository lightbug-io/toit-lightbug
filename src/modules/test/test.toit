import ...devices as devices

class TestModule:
  device_/devices.Device

  constructor .device_:

  // TODO: don't actually build in these verbose strings into the binary

  run-test:
    failed := false

    // Test the strobe...
    print "Testing Strobe"
    strobe := device_.strobe
    strobe.red
    sleep --ms=500
    strobe.green
    sleep --ms=500
    strobe.blue
    sleep --ms=500
    strobe.white
    sleep --ms=500
    strobe.off
    print "✅ Strobe test completed..."

    // Test the BLE...
    print "Testing BLE"
    print "Performing BLE scan for 2s..."
    scan-results := device_.ble.scan --duration=2000
    if scan-results.size <= 0:
      print "❌ No BLE devices found."
    else:
      print "✅ Found $(scan-results.size) BLE devices"

    if failed:
      print "❌❌❌"
      print "Some tests failed."
      print "❌❌❌"
    else:
      print "✅✅✅"
      print "Test complete."
      print "✅✅✅"
