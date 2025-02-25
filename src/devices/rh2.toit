import i2c
import io
import .base
import .i2c

// Needs more information. Can't say if abbreviating is OK or not.
// Most likely, it should be `Rh2`.
// The RH2 device, currently at revision 3.
class RH2 implements Device:
  static I2C-SDA := 6
  static I2C-SCL := 7
  // Feels weird to have a static and instance way of accessing the in/out.
  static I2C-DEVICE := lb-i2c-device --sda=RH2.I2C-SDA --scl=RH2.I2C-SCL
  static I2C-READER := Reader I2C-DEVICE
  static I2C-WRITER := Writer I2C-DEVICE
  in -> io.Reader:
    return I2C-READER
  out -> io.Writer:
    return I2C-WRITER
