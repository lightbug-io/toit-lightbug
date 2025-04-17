import i2c
import gpio
import uart
import io
import log
import .i2c
import .strobe
import .devices

/*
An interface representing a Lightbug device
*/
interface Device extends Comms:
  // A name identifying the type of device
  name -> string
  // Device strobe. You can use strobe.available to see if the device has a strobe
  strobe -> Strobe
  // Reinit the device and communications
  reinit -> bool
  // CURRENTLY NOT USED: A list of ints, mapping to supported Lightbug message types
  messages-supported -> List
  // CURRENTLY NOT USED: A list of ints, mapping to not supported Lightbug message types
  messages-not-supported -> List

/*
An interface for communicationg to and from a Lightbug device
*/
interface Comms:
  // Reader reading from the device
  in -> Reader
  // Writer writing to the device
  out -> io.Writer

/*
A base class for Lightbug devices
Containing the common I2C implementation
*/
abstract class LightbugDevice implements Device:
  static I2C-SDA := 6
  static I2C-SCL := 7

  i2c-device_ /i2c.Device
  i2c-reader_ /Reader
  i2c-writer_ /Writer

  name_ /string
  strobe_ /Strobe
  logger_ /log.Logger

  constructor name/string i2c-sda/int=I2C-SDA i2c-scl/int=I2C-SCL
      --strobe/Strobe=NoStrobe
      --logger/log.Logger=(log.default.with-name "lb-device"):
    // TODO if more than one device is instantiated, things will likely break due to gpio / i2c conflicts, so WARN / throw in this case
    name_ = name
    strobe_ = strobe
    logger_ = logger
    i2c-device_ = LBI2CDevice --sda=i2c-sda --scl=i2c-scl
    i2c-reader_ = Reader i2c-device_ --logger=logger_
    i2c-writer_ = Writer i2c-device_ --logger=logger_

  name -> string:
    return name_
  strobe -> Strobe:
    return strobe_
  messages-supported -> List:
    return []
  messages-not-supported -> List:
    return []
  i2c-device -> i2c.Device:
    return i2c-device_
  reinit -> bool:
    logger_.info "Lightbug I2C: Reinitializing device"
    i2c-device_.write #[I2C-COMMAND-LIGHTBUG-REINIT, 0xf0]
    return true
  in -> io.Reader:
    return i2c-reader_
  out -> io.Writer:
    return i2c-writer_