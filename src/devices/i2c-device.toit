import i2c
import io
import log
import monitor
import .base
import .i2c
import .types show *
import ..modules.strobe show Strobe StandardStrobe NoStrobe
import ..modules.buttons show Buttons
import ..modules.ble show BLE
import ..modules.wifi show WiFi
import ..modules.piezo show Piezo
import ..modules.haptics show Haptics
import ..modules.eink show Eink
import ..modules.gnss show GNSS
import ..messages show *
import ..protocol as protocol
import ..modules.comms show Comms
import ..util.backoff as backoff
import ..modules.comms.message-handler show MessageHandler
import ..modules.ble.handler show BLEHandler
import ..modules.wifi.handler show WiFiHandler
import ..modules.strobe.handler show StrobeHandler

/*
A class for a generic Lightbug I2C device
Containing the common I2C implementation
*/
class I2C implements Device:
  static I2C-SDA := 6
  static I2C-SCL := 7

  i2c-bus /i2c.Bus
  i2c-device_ /i2c.Device
  i2c-reader_ /Reader
  i2c-writer_ /Writer

  name_ /string
  background_ /bool
  type_ /int? := null
  open_ /bool
  with-default-handlers_ /bool
  logger_ /log.Logger

  comms_ /Comms? := null
  strobe_ /Strobe?:= null
  piezo_ /Piezo?:= null
  haptics_ /Haptics?:= null
  eink_ /Eink? := null
  buttons_ /Buttons? := null
  ble_ /BLE? := null
  wifi_ /WiFi? := null
  gnss_ /GNSS? := null

  constructor
      // Default to sending an open on start
      // Assuming the user will want to keep the connection open, unless explicitly closed
      --open/bool=true

      // Run the primary device loops as background tasks, so that the main program
      // exits, the device will not keep the program alive.
      // If true, and you don't keep your program running, no previously scheduled messages,
      // handlers, etc will be guaranteed to run before the program exits.
      // Using this with startComms=false is unlikely to be useful, as comms contains the main
      // device loops.
      --background/bool=true

      // Default to starting comms when the device is created
      // But allow this to be disabled if needed
      // Calling .comms will start it anyway
      --startComms/bool=true
      // Enabled default Lightbug firmware handlers
      // Such as WiFi and BLE scan request handlers
      // You may want to disable this while developing with logging, as this can cause slowness
      --with-default-handlers/bool=true

      // Default to a logger named "lb" with ERROR level
      // This means we will only see critical stuff
      --logger/log.Logger=(log.default.with-name "lb")
      --log-level/int=log.ERROR-LEVEL

      // INTERNAL USE
      // We allow overriding I2C for easy internal development
      // But users are unlikely to need this
      --i2c-sda/int=I2C-SDA
      --i2c-scl/int=I2C-SCL
      --i2c-frequency/int=100_000:

    name_ = "I2C Device" // TODO look this up from a map eventually, so it could be used..
    background_ = background
    logger_ = logger.with-level log-level
    with-default-handlers_ = with-default-handlers
    open_ = open

    // Initialize I2C
    // TODO if more than one device is instantiated, things will likely break due to gpio / i2c conflicts, so WARN / throw in this case
    logger_.debug "Lightbug I2C pins SDA=$i2c-sda, SCL=$i2c-scl at $i2c-frequency Hz"
    i2c-bus = LBI2CBus --sda=i2c-sda --scl=i2c-scl --frequency=i2c-frequency
    i2c-device_ = LBI2CDevice i2c-bus
    i2c-reader_ = Reader i2c-device_ --logger=(logger_.with-name "i2c.read")
    i2c-writer_ = Writer i2c-device_ --logger=(logger_.with-name "i2c.write")

    // Start things if needed
    if startComms:
      comms
  
  name -> string:
    return name_
  
  type -> int?:
    return type_
  type-known -> bool:
    return type_ != null
  set-type_ new-type/int:
    type_ = new-type
  request-type:
    if not type-known:
      // Ask for and wait for the device type to be known
      (this.comms.send DeviceStatus.get-msg --withLatch=true --now=true).get

  prefix -> bool:
    return false

  i2c-device -> i2c.Device:
    return i2c-device_

  in -> io.Reader:
    return i2c-reader_

  out -> io.Writer:
    return i2c-writer_

  comms -> Comms:
    if not comms_:
      handlers := [
              // We need to be able to detect the device type, at least once
              DeviceDetectionHandler this --logger=(logger_.with-name "h.detect"),
      ]
      if with-default-handlers_:
        handlers = handlers + [
            // TODO add a reset msg handler
            BLEHandler this --logger=(logger_.with-name "h.ble"),
            WiFiHandler this --logger=(logger_.with-name "h.wifi"),
            StrobeHandler this --logger=(logger_.with-name "h.strobe"),
        ]
      else :
        logger_.warn "Default message handlers disabled"
      comms_ = Comms 
          --device=this
          --open=open_
          --background=background_
          --handlers=handlers
          --logger=(logger_.with-name "comms")
    return comms_

  reinit -> bool:
    logger_.info "Lightbug I2C: Reinitializing device"
    
    e := catch:
      backoff.do-with-backoff
        --onSuccess=(:: logger_.info "Lightbug I2C: Device reinitialized successfully")
        --onError=(:: |error|
          logger_.warn "Lightbug I2C: Reinitialization attempt failed: $error"
        )
        --initial-delay=(Duration --ms=50)
        --backoff-factor=2.0
        --max-delay=(Duration --s=1):
        i2c-device_.write #[I2C-COMMAND-LIGHTBUG-REINIT, 0xf0]
    
    if e:
      logger_.error "Lightbug I2C: Failed to reinitialize device after retries: $e"
      return false
    
    return true

  request-type-mutex_ := monitor.Mutex
  strobe -> Strobe:
    // DO this in a mutex for now, ALL things that request-type likely should be in a single mutex
    request-type-mutex_.do:
      // TODO: this pattern of service check, type check, status request and construction should
      // be refactored into a common utility, as it will be needed for all conditionally available services
      if not strobe_:
        request-type
        if type_ == TYPE-ZCARD:
          strobe_ = (StandardStrobe --initial-value=1)
        else if type_ == TYPE-RH2 or type_ == TYPE-RH2Z or type_ == TYPE-RH2M:
          strobe_ = StandardStrobe
        else:
          strobe_ = NoStrobe
    return strobe_

  piezo -> Piezo:
    if not piezo_:
      piezo_ = Piezo --device=this --logger=(logger_.with-name "piezo")
    return piezo_

  eink -> Eink:
    if not eink_:
      eink_ = Eink --device=this --logger=(logger_.with-name "eink")
    return eink_

  haptics -> Haptics:
    if not haptics_:
      haptics_ = Haptics --device=this --logger=(logger_.with-name "haptics")
    return haptics_

  buttons -> Buttons:
    if not buttons_:
      buttons_ = Buttons comms --logger=(logger_.with-name "buttons")
    return buttons_

  ble -> BLE:
    if not ble_:
      ble_ = BLE --logger=(logger_.with-name "ble")
    return ble_

  wifi -> WiFi:
    if not wifi_:
      wifi_ = WiFi --logger=(logger_.with-name "wifi")
    return wifi_

  gnss -> GNSS:
    if not gnss_:
      gnss_ = GNSS --device=this --logger=(logger_.with-name "gnss")
    return gnss_

class DeviceDetectionHandler implements MessageHandler:
  device_ /I2C
  logger_ /log.Logger
  configured_ /bool := false
  
  constructor device/I2C --logger/log.Logger:
    device_ = device
    logger_ = logger
  
  handle-message msg/protocol.Message -> bool:
    if device_.type-known or (msg.type != Open.MT and msg.type != DeviceStatus.MT):
      return false
    // The device type should be in field 10 for both Open and Status messages
    // This is thus an optimization
    type := msg.data.get-data-uint8 Open.DEVICE-TYPE
    logger_.info "🔍 Detected Open or Status message $(msg.type), device type: $type"
    device_.set-type_ type
    return true
