// Tests both reusable sensor driver suites.
// Run as part of the RH2 motion host test suite.

import ...packages.lsm6ds3.tests.driver-test as imu
import ...packages.lis2mdl.tests.driver-test as mag

main:
  imu.main
  mag.main
