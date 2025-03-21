import i2c
import io
import .base
import .i2c
import .strobe

RtkHandheld2-MESSAGES := [
    // TODO
]

// The RtkHandheld2 device, currently at revision 3
// Introduced Feb 2025
class RtkHandheld2 extends LightbugDevice:
  constructor:
    super "RtkHandheld2" --strobe=StandardStrobe
  messages-supported -> List:
    return RtkHandheld2-MESSAGES

// A previous version of the RtkHandheld2 device, that had a different I2C setup
// Retired Feb 2025
class RtkHandheld2Rev2 extends LightbugDevice:
  static I2C-SDA := 0
  static I2C-SCL := 1
  constructor:
    super "RtkHandheld2 rev2" I2C-SDA I2C-SCL
  strobe -> Strobe:
    return NoStrobe // Probably didnt have a strobe, and probably doesnt matter
  messages-supported -> List:
    return RtkHandheld2-MESSAGES