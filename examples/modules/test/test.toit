import lightbug.devices as devices
import lightbug.modules.test.test as testmod

main:
  device := devices.RtkHandheld2
  tester := testmod.TestModule device
  tester.run-test
