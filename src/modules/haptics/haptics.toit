import ...protocol as protocol
import ...messages as messages
import ...devices as devices
import log

/**
Haptics module to control vibration motors by sending protocol messages to the device.
Provides helpers for simple patterns and intensity presets.
*/
class Haptics:
  logger_/log.Logger
  device_/devices.Device?

  constructor --device/devices.Device?=null --logger/log.Logger=(log.default.with-name "lb-haptics"):
    device_ = device
    logger_ = logger

  available -> bool:
    // Always available as it simply sends messages via comms.
    return true

  // Send a haptics control with explicit pattern and intensity.
  send --pattern/int --intensity/int:
    msg := messages.HapticsControl.msg --data=(messages.HapticsControl.data --pattern=pattern --intensity=intensity)
    device_.comms.send msg --now=true

  // Convenience presets for patterns 1..3 and intensities 0..2
  pattern1 --intensity/int=1:
    send --pattern=1 --intensity=intensity
  pattern2 --intensity/int=1:
    send --pattern=2 --intensity=intensity
  pattern3 --intensity/int=1:
    send --pattern=3 --intensity=intensity

  low --pattern/int=1:
    send --pattern=pattern --intensity=0
  med --pattern/int=1:
    send --pattern=pattern --intensity=1
  high --pattern/int=1:
    send --pattern=pattern --intensity=2

  stringify -> string:
    return "Haptics controller"
