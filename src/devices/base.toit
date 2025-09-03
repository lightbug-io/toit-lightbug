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
import ..modules.comms.message-handler show MessageHandler
import ..modules.ble.handler show BLEHandler
import ..modules.wifi.handler show WiFiHandler
import ..modules.wifi
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
  // WiFi scanning service for this device
  wifi -> WiFi
  // Reinit the device and communications
  reinit -> bool
  // Should messages be sent with a Lightbug message prefix, LB
  prefix -> bool

/*
An interface for combining a Reader and Writer for a device.
*/
interface HasInOut:
  // Reader reading from the device
  in -> Reader
  // Writer writing to the device
  out -> io.Writer
