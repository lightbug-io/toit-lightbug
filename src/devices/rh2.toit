import i2c
import io
import .base
import .i2c

RH2-MESSAGES := [
    // TODO
]

// The RH2 device, currently at revision 3
// Introduced Feb 2025
class RH2 extends LightbugDevice:
  constructor:
    super "RH2"
  messages-supported -> List:
    return RH2-MESSAGES

// A previous version of the RH2 device, that had a different I2C setup
// Retired Feb 2025
class RH2rev2 extends LightbugDevice:
  static I2C_SDA := 0
  static I2C_SCL := 1
  constructor:
    super "RH2 rev2" I2C_SDA I2C_SCL
  messages-supported -> List:
    return RH2-MESSAGES