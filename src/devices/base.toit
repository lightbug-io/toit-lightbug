import i2c
import gpio
import uart
import log
import .i2c
import .devices
import ..modules.eink
import ..modules.strobe
import ..modules.comms
import ..modules.buttons
import ..modules.ble
import ..modules.piezo
import ..modules.haptics
import ..modules.gnss show GNSS
import ..modules.lora show LoraRadio
import ..modules.comms.message-handler show MessageHandler
import ..modules.comms.transport show V3Transport
import ..modules.ble.handler show BLEHandler
import ..modules.wifi.handler show WiFiHandler
import ..modules.wifi
import ..util.backoff as backoff

/*
An interface representing a Lightbug device
*/
interface Device extends V3Transport:
  // A name identifying the type of device
  name -> string
  /// E-ink
  eink -> Eink
  // Device strobe. You can use strobe.available to see if the device has a strobe
  strobe -> Strobe
  // Piezo buzzer controller. Use to send buzzer messages to the device.
  piezo -> Piezo
  // Haptics vibration controller. Use to send haptics messages to the device.
  haptics -> Haptics
  // Communications service for this device
  comms -> Comms
  // Button press handling service for this device
  buttons -> Buttons
  // BLE scanning service for this device
  ble -> BLE
  // WiFi scanning service for this device
  wifi -> WiFi
  // GNSS service (optional). Use to access GNSS helpers like subscribe/get-position.
  gnss -> GNSS
  // LoRa radio service.
  lora -> LoraRadio
