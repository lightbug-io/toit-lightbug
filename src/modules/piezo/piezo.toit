import ...protocol as protocol
import ...messages as messages
import ...devices as devices
import log

/**
Piezo module to control the buzzer by sending protocol messages to the device.
Provides helpers for single-tone control, named sound types, and sequences.
*/
class Piezo:
  logger_/log.Logger
  device_/devices.Device?

  constructor --device/devices.Device?=null --logger/log.Logger=(log.default.with-name "lb-piezo"):
    device_ = device
    logger_ = logger

  available -> bool:
    // Always available as it simply sends messages via comms.
    return true

  // Play a single tone by specifying frequency in KHz (float) and duration in ms (int).
  play-tone --khz/float --ms/int:
    msg := messages.BuzzerControl.msg --data=(messages.BuzzerControl.data --duration=ms --frequency=khz)
    device_.comms.send msg --now=true

  // Shortcut tones: low, med, high. Default duration 100 ms.
  low --ms/int=100:
    play-tone --khz=0.1 --ms=ms
  med --ms/int=100:
    play-tone --khz=5.0 --ms=ms
  high --ms/int=100:
    play-tone --khz=10.0 --ms=ms

  // Control buzzer using duration (ms), sound-type and intensity (e.g., ambulance preset)
  control --ms/int --sound-type/int?=null --intensity/int?=null:
    msg := messages.BuzzerControl.msg --data=(messages.BuzzerControl.data --duration=ms --sound-type=sound-type --intensity=intensity)
    device_.comms.send msg --now=true

  // Play a sequence of frequencies (float KHz) and timings (int ms list).
  sequence --frequencies/List --timings/List:
    // Build a protocol.Data payload with list fields as expected by the device.
    data := protocol.Data
    // frequencies expected as list of floats
    data.add-data-list-float32 messages.BuzzerSequence.FREQUENCIES frequencies
    // timings expected as list of uint16
    data.add-data-list-uint16 messages.BuzzerSequence.TIMINGS timings
    msg := messages.BuzzerSequence.msg --data=data
    device_.comms.send msg --now=true

  // Convenience methods for common presets using the generated SOUND-TYPE constants
  solid --ms/int=500 --intensity/int?=null:
    control --ms=ms --sound-type=messages.BuzzerControl.SOUND-TYPE_SOLID --intensity=intensity
  siren --ms/int=2000 --intensity/int?=null:
    control --ms=ms --sound-type=messages.BuzzerControl.SOUND-TYPE_SIREN --intensity=intensity
  beep-beep --ms/int=500 --intensity/int?=null:
    control --ms=ms --sound-type=messages.BuzzerControl.SOUND-TYPE_BEEP-BEEP --intensity=intensity
  ambulance --ms/int=2000 --intensity/int?=1:
    control --ms=ms --sound-type=messages.BuzzerControl.SOUND-TYPE_AMBULANCE --intensity=intensity
  firetruck --ms/int=2000 --intensity/int?=null:
    control --ms=ms --sound-type=messages.BuzzerControl.SOUND-TYPE_FIRETRUCK --intensity=intensity
  positive1 --ms/int=500 --intensity/int?=null:
    control --ms=ms --sound-type=messages.BuzzerControl.SOUND-TYPE_POSITIVE1 --intensity=intensity
  slowbeep --ms/int=1000 --intensity/int?=null:
    control --ms=ms --sound-type=messages.BuzzerControl.SOUND-TYPE_SLOWBEEP --intensity=intensity
  alarm --ms/int=3000 --intensity/int?=null:
    control --ms=ms --sound-type=messages.BuzzerControl.SOUND-TYPE_ALARM --intensity=intensity

  stringify -> string:
    return "Piezo controller"
