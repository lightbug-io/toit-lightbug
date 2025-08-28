import i2c
import gpio
import uart
import io
import log
import .i2c
import .devices
import ..modules.strobe
import ..modules.comms
import ..modules.buttons
import ..modules.ble
import ..modules.ble.handler show BLEHandler
import ..util.backoff as backoff

/*
An interface representing a Lightbug device
*/
interface Device extends HasInOut:
  // A name identifying the type of device
  name -> string
  // Device strobe. You can use strobe.available to see if the device has a strobe
  strobe -> Strobe
  // Communications service for this device
  comms -> Comms
  // Button press handling service for this device
  buttons -> Buttons
  // BLE scanning service for this device
  ble -> BLE
  // Reinit the device and communications
  reinit -> bool
  // Should messages be sent with a Lightbug message prefix, LB
  prefix -> bool
  // CURRENTLY NOT USED: A list of ints, mapping to supported Lightbug message types
  messages-supported -> List
  // CURRENTLY NOT USED: A list of ints, mapping to not supported Lightbug message types
  messages-not-supported -> List

/*
An interface for combining a Reader and Writer for a device.
*/
interface HasInOut:
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
  comms_ /Comms? := null
  buttons_ /Buttons? := null
  ble_ /BLE? := null
  open_ /bool

  constructor name/string i2c-sda/int=I2C-SDA i2c-scl/int=I2C-SCL --i2c-frequency/int=100_000
      --strobe/Strobe=NoStrobe
      --open/bool=true
      --logger/log.Logger=(log.default.with-name "lb-device"):
    // TODO if more than one device is instantiated, things will likely break due to gpio / i2c conflicts, so WARN / throw in this case
    name_ = name
    strobe_ = strobe
    logger_ = logger
    open_ = open
    i2c-device_ = LBI2CDevice --sda=i2c-sda --scl=i2c-scl --frequency=i2c-frequency
    i2c-reader_ = Reader i2c-device_ --logger=logger_
    i2c-writer_ = Writer i2c-device_ --logger=logger_

  name -> string:
    return name_
  strobe -> Strobe:
    return strobe_
  comms -> Comms:
    if not comms_:
      comms_ = Comms 
          --device=this
          --open=open_
      // Auto-register BLE handler for all devices with BLE support
      auto-register-ble-handler_
    return comms_
  buttons -> Buttons:
    if not buttons_:
      buttons_ = Buttons comms
    return buttons_
  ble -> BLE:
    if not ble_:
      ble_ = BLE
    return ble_
  messages-supported -> List:
    return []
  messages-not-supported -> List:
    return []
  i2c-device -> i2c.Device:
    return i2c-device_
  reinit -> bool:
    logger_.info "Lightbug I2C: Reinitializing device"
    
    e := catch:
      backoff.do-with-backoff
        --onSuccess=(:: logger_.info "Lightbug I2C: Device reinitialized successfully")
        --onError=(:: |error|
          logger_.warn "Lightbug I2C: Reinitialization attempt failed: $error"
        )
        --initial-delay=(Duration --ms=50)
        --max-retries=5
        --backoff-factor=2.0:
        i2c-device_.write #[I2C-COMMAND-LIGHTBUG-REINIT, 0xf0]
    
    if e:
      logger_.error "Lightbug I2C: Failed to reinitialize device after retries: $e"
      return false
    
    return true
  prefix -> bool:
    return false
  in -> io.Reader:
    return i2c-reader_
  out -> io.Writer:
    return i2c-writer_

  /**
   * Automatically register the BLE handler if the device supports BLE.
   * This is called when comms is first created.
   */
  auto-register-ble-handler_:
    e := catch:
      ble-handler := BLEHandler this comms_
      comms_.register-handler ble-handler
      logger_.debug "Auto-registered BLE message handler"
    if e:
      logger_.warn "Failed to register BLE handler: $e"