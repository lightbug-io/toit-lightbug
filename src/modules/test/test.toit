import ...devices as devices
import gpio
import spi
import gpio
import io.byte-order show LITTLE-ENDIAN

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
    print "Performing WiFi scan for 2s..."
    wifi-results := device_.wifi.scan --duration=2000
    if wifi-results.size <= 0:
      print "❌ No WiFi networks found."
      failed = true
    else:
      print "✅ Found $(wifi-results.size) WiFi networks"
    
    // If the device is an RH2...
    // Then test for UWB....
    // TODO RH2 actually needs a common interface...?! maybe
    if device_ is devices.RtkHandheld2:
      print "Testing UWB chip"
      pinEnableUWB := gpio.Pin 1 --output=true
      pinEnableUWB.set 0
      sleep --ms=250
      pinEnableUWB.set 1
      spi-bus := spi.Bus
        --miso=gpio.Pin 5
        --mosi=gpio.Pin 4
        // --clock=gpio.Pin 8
        --clock=gpio.Pin 2
      spi-bus-device := spi-bus.device
        // --cs=gpio.Pin 3 // chip select
        --frequency=10_000 // higher was bad
      pinCS := gpio.Pin 3 --output=true
      pinCS.set 1
      sleep --ms=100
      last := 0
      // test
      pinCS.set 0
      spi-bus-device.write #[0x00]
      a := spi-bus-device.read 4
      if a != #[0x02, 0x03, 0xca, 0xde]:
        print "❌ UWB chip did not respond as expected, got: "
        print (a)
        failed = true
      else:
        print "✅ UWB chip responded correctly."
      pinCS.set 1
      sleep --ms=250

    // Enumerate I2C devices... (On RH2 only)
    if device_ is devices.RtkHandheld2 and device_ is devices.LightbugDevice:
      print "Enumerating I2C devices..."
      device-with-i2c := device_ as devices.LightbugDevice
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
