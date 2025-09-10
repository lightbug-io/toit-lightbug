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
    // Build payload using generated helper to ensure field numbers/constants are correct.
    msg := messages.HapticsControl.msg --data=(messages.HapticsControl.data --pattern=pattern --intensity=intensity)
    device_.comms.send msg --now=true

  // Convenience named presets for patterns and intensities using generated constants.
  fade --intensity/int=(messages.HapticsControl.INTENSITY_MEDIUM):
    send --pattern=messages.HapticsControl.PATTERN_FADE --intensity=intensity

  pulse --intensity/int=(messages.HapticsControl.INTENSITY_MEDIUM):
    send --pattern=messages.HapticsControl.PATTERN_PULSE --intensity=intensity

  drop --intensity/int=(messages.HapticsControl.INTENSITY_MEDIUM):
    send --pattern=messages.HapticsControl.PATTERN_DROP --intensity=intensity

  // Intensity helpers that allow specifying which pattern to use (default: FADE).
  low --pattern/int=messages.HapticsControl.PATTERN_FADE:
    send --pattern=pattern --intensity=messages.HapticsControl.INTENSITY_LOW

  med --pattern/int=messages.HapticsControl.PATTERN_FADE:
    send --pattern=pattern --intensity=messages.HapticsControl.INTENSITY_MEDIUM

  high --pattern/int=messages.HapticsControl.PATTERN_FADE:
    send --pattern=pattern --intensity=messages.HapticsControl.INTENSITY_HIGH

  stringify -> string:
    return "Haptics controller"
