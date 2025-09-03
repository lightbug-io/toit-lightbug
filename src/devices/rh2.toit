import i2c
import io
import log
import .base
import .i2c
import ..modules.strobe

RtkHandheld2-MESSAGES := [
    // TODO
]

// The latest revision of the RtkHandheld2 device
class RtkHandheld2 extends RtkHandheld2Rev5:
  constructor --open/bool=true --logger/log.Logger=((log.default.with-name "lb").with-level log.ERROR-LEVEL):
    super --open=open --logger=logger

// The RtkHandheld2 device, currently at revision 5
class RtkHandheld2Rev5 extends LightbugI2CDevice:
  constructor --open/bool=true --logger/log.Logger=((log.default.with-name "lb").with-level log.ERROR-LEVEL):
    super "RtkHandheld2" --strobe=StandardStrobe --i2c-frequency=100_000 --open=open --logger=logger
  messages-supported -> List:
    return RtkHandheld2-MESSAGES

// Rev 3 and 4 of the RtkHandheld2 device (slower I2C speed)
// Introduced Feb 2025
class RtkHandheld2Rev3 extends LightbugI2CDevice:
  constructor --open/bool=true:
    super "RtkHandheld2" --strobe=StandardStrobe --open=open
  messages-supported -> List:
    return RtkHandheld2-MESSAGES

// Rev 2 of the RtkHandheld2 device, with different I2C pins
// Retired Feb 2025
class RtkHandheld2Rev2 extends LightbugI2CDevice:
  static I2C-SDA := 0
  static I2C-SCL := 1
  constructor --open/bool=true:
    super "RtkHandheld2 rev2" I2C-SDA I2C-SCL --strobe=(GpioBasedStrobe 18 19 20 --initial-value=0) --open=open
  messages-supported -> List:
    return RtkHandheld2-MESSAGES