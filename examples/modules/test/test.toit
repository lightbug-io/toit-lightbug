import lightbug.devices as devices
import lightbug.modules.test.test as testmod

main:
  device := devices.I2C

  // Make sure we are on the RH2, as currently the tests are RH2 specific.
  device.request-type
  if device.type != devices.TYPE-RH2 and device.type != devices.TYPE-RH2M and device.type != devices.TYPE-RH2Z:
    throw "This test module is designed to run with the RH2, RH2M or RH2Z device. Detected device type: $(device.type)"

  tester := testmod.TestModule device
  tester.run-test
