import i2c
import io
import .base
import .i2c
import .strobe

RtkHandheld2-MESSAGES := [
    // TODO
]

// The latest revision of the RtkHandheld2 device
class RtkHandheld2 extends RtkHandheld2Rev5:

// The RtkHandheld2 device, currently at revision 5
class RtkHandheld2Rev5 extends LightbugDevice:
  constructor:
    super "RtkHandheld2" --strobe=StandardStrobe --i2c-frequency=400_000
  messages-supported -> List:
    return RtkHandheld2-MESSAGES

// Rev 3 and 4 of the RtkHandheld2 device (slower I2C speed)
// Introduced Feb 2025
class RtkHandheld2Rev3 extends LightbugDevice:
  constructor:
    super "RtkHandheld2" --strobe=StandardStrobe
  messages-supported -> List:
    return RtkHandheld2-MESSAGES

// Rev 2 of the RtkHandheld2 device, with different I2C pins
// Retired Feb 2025
class RtkHandheld2Rev2 extends LightbugDevice:
  static I2C-SDA := 0
  static I2C-SCL := 1
  constructor:
    super "RtkHandheld2 rev2" I2C-SDA I2C-SCL --strobe=LegacyStrobe
  messages-supported -> List:
    return RtkHandheld2-MESSAGES