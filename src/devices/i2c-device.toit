import gpio
import i2c
import io
import log
import monitor
import ble as ble-sdk
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

  i2c-sda_ /int
  i2c-scl_ /int
  i2c-frequency_ /int

  i2c-bus_ /i2c.Bus? := null
  i2c-device_ /i2c.Device? := null
  i2c-sda-pin_ /gpio.Pin? := null
  i2c-scl-pin_ /gpio.Pin? := null
  i2c-reader_ /Reader? := null
  i2c-writer_ /Writer? := null
  connected_ /bool := false
  pending-reinit_ /bool := false

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
  ble-advertisement_ /ble-sdk.Advertisement? := null

  constructor
      // Should the device be connected (I2C bus initialized) immediately on creation,
      // or should this be deferred until later?
      // This is likely only needed to be false in very specific cases, and care should be taken in combination with other initialization params.
      --connect-now/bool=true

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

      // Optional BLE advertisement to start on device creation.
      // If provided, BLE advertising will be started automatically.
      --ble-advertisement/ble-sdk.Advertisement?=null

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
    ble-advertisement_ = ble-advertisement

    // Store I2C pin parameters so the bus can be reconnected later.
    // And optionally connect immediately if requested.
    // TODO if more than one device is instantiated, things will likely break due to gpio / i2c conflicts, so WARN / throw in this case
    i2c-sda_ = i2c-sda
    i2c-scl_ = i2c-scl
    i2c-frequency_ = i2c-frequency
    logger_.debug "I2C Device created with SDA pin $i2c-sda_, SCL pin $i2c-scl_, frequency $i2c-frequency_ Hz, connect immediately: $connect-now"
    if connect-now:
      connect

      // Start things if needed
      if startComms:
        comms

    // Start BLE advertising if advertisement data was provided.
    if ble-advertisement_:
      ble.start-advertise ble-advertisement_
  
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

  /** Returns the raw I2C bus. Throws if disconnected. */
  i2c-bus -> i2c.Bus:
    if not i2c-bus_: throw "I2C device not connected"
    return i2c-bus_

  i2c-device -> i2c.Device:
    if not i2c-device_: throw "I2C device not connected"
    return i2c-device_

  /** Returns whether the I2C bus is currently connected. */
  connected -> bool:
    return connected_

  /**
  Connects the I2C bus and creates fresh reader/writer instances.
  No-op if already connected.
  */
  connect -> none:
    if connected_: return
    logger_.debug "Connecting I2C bus (SDA=$i2c-sda_, SCL=$i2c-scl_ at $i2c-frequency_ Hz)"
    sda-pin := gpio.Pin i2c-sda_
    scl-pin := gpio.Pin i2c-scl_
    i2c-bus_ = i2c.Bus
        --sda=sda-pin
        --scl=scl-pin
        --frequency=i2c-frequency_
        --pull-up=true
    sleep --ms=10
    i2c-sda-pin_ = sda-pin
    i2c-scl-pin_ = scl-pin
    i2c-device_ = LBI2CDevice i2c-bus_
    i2c-reader_ = Reader i2c-device_ --logger=(logger_.with-name "i2c.read")
    i2c-writer_ = Writer i2c-device_ --logger=(logger_.with-name "i2c.write")
    connected_ = true
    if pending-reinit_:
      pending-reinit_ = false
      reinit

  /**
  Disconnects the I2C bus, releasing the underlying hardware resource.
  No-op if already disconnected.
  */
  disconnect -> none:
    if not connected_: return
    logger_.debug "Disconnecting I2C bus"
    i2c-bus_.close
    // Explicitly close the gpio.Pin wrappers so the Toit resource system
    // marks those pins free before the next connect. Without this the pins
    // remain "in use" until GC runs, causing ALREADY_IN_USE on reconnect.
    i2c-sda-pin_.close
    i2c-scl-pin_.close
    i2c-bus_ = null
    i2c-sda-pin_ = null
    i2c-scl-pin_ = null
    i2c-device_ = null
    i2c-reader_ = null
    i2c-writer_ = null
    connected_ = false

  in -> io.Reader:
    if not i2c-reader_: throw "I2C device not connected"
    return i2c-reader_

  out -> io.Writer:
    if not i2c-writer_: throw "I2C device not connected"
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
    // Defer the reinit until the bus is actually connected.
    if not connected_:
      pending-reinit_ = true
      logger_.debug "Lightbug I2C: Reinit deferred until bus is connected"
      return true
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
        i2c-device.write #[I2C-COMMAND-LIGHTBUG-REINIT, 0xf0]
    
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
