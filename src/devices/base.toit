import i2c
import gpio
import uart
import io
import .i2c

/*
An interface representing a Lightbug device
*/
interface Device extends Comms:
  // A name identifying the type of device
  name -> string
  // A list of ints, mapping to supported Lightbug message typess
  messages-supported -> List

/*
An interface for communicationg to and from a Lightbug device
*/
interface Comms:
  // Reader reading from the device
  in -> io.Reader
  // Writer writing to the device
  out -> io.Writer

/*
A base class for Lightbug devices
Containing the common I2C implementation
*/
abstract class LightbugDevice implements Device:
  static I2C_SDA := 6
  static I2C_SCL := 7

  i2c-device_ /i2c.Device
  i2c-reader_ /Reader
  i2c-writer_ /Writer

  name_ /string

  constructor name/string i2c-sda/int=I2C_SDA i2c-scl/int=I2C_SCL:
    name_ = name
    i2c-device_ = LBI2CDevice --sda=i2c-sda --scl=i2c-scl
    i2c-reader_ = Reader i2c-device_
    i2c-writer_ = Writer i2c-device_

  name -> string:
    return name_
  messages-supported -> List:
    return []
  i2c-device -> i2c.Device:
    return i2c-device_
  in -> io.Reader:
    return i2c-reader_
  out -> io.Writer:
    return i2c-writer_