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

    // Test the WiFi...
    print "Testing WiFi"
    print "Performing WiFi scan for 3s..."
    wifi-results := device_.wifi.scan --duration=3000
    if wifi-results.size <= 0:
      print "❌ No WiFi networks found."
      failed = true
    else:
      print "✅ Found $(wifi-results.size) WiFi networks"
    
    // Enumerate I2C devices when supported by the current device implementation.
    if device_ is devices.I2C:
      print "Enumerating I2C devices..."
      device-with-i2c := device_ as devices.I2C
      i2c-bus := device-with-i2c.i2c-bus
      found-devices := i2c-bus.scan
      if found-devices.size < 3:
        print "❌ Not enough I2C devices found, got: $(found-devices.size), expected at least 3"
        failed = true
      else:
        print "✅ Found $(found-devices.size) I2C devices"

    if failed:
      print "❌❌❌"
      print "Some tests failed."
      print "❌❌❌"
    else:
      print "✅✅✅"
      print "Test complete."
      print "✅✅✅"
