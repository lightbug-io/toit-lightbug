import i2c
import io
import .base
import .i2c

// The RH2 device, currently at revision 3
class RH2 implements Device:
  static I2C_SDA := 6
  static I2C_SCL := 7
  static I2C_DEVICE := LBI2CDevice --sda=RH2.I2C_SDA --scl=RH2.I2C_SCL
  static I2C_READER := Reader I2C_DEVICE
  static I2C_WRITER := Writer I2C_DEVICE
  name -> string:
    return "RH2"
  in -> io.Reader:
    return I2C_READER
  out -> io.Writer:
    return I2C_WRITER

class RH2rev2 implements Device:
  static I2C_SDA := 0
  static I2C_SCL := 1
  static I2C_DEVICE := LBI2CDevice --sda=RH2.I2C_SDA --scl=RH2.I2C_SCL
  static I2C_READER := Reader I2C_DEVICE
  static I2C_WRITER := Writer I2C_DEVICE
  name -> string:
    return "RH2 rev2"
  in -> io.Reader:
    return I2C_READER
  out -> io.Writer:
    return I2C_WRITER