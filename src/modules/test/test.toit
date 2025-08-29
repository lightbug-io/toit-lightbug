import ...devices as devices

class TestModule:
  device_/devices.Device

  constructor .device_:

  run-test:
    // Test the strobe...
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
    print "Test complete."
