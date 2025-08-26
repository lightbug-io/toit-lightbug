import gpio

/**
Some devices support a strobe light.
This light is one or more RGB LEDs that can be controlled to display different colors.
*/
abstract class Strobe:
  /**
  Set the strobe to be the requested RGB colour mix
  Will stop any sequence that is running
  */
  abstract set r/bool g/bool b/bool

  /**
  Start a sequence of colors, changing at the specified interval
    If colors is not specified, a rainbow sequence is used
    --colors is a list of color values, see RED, GREEN, BLUE etc.
    For example, flashing red, [device.strobe.RED, device.strobe.OFF]
  */
  abstract sequence --speed-ms/int=100 --colors/List?=RAINBOW-SEQUENCE

  // Color constants for RGB LED control.
  RED := [true, false, false]
  GREEN := [false, true, false]
  BLUE := [false, false, true]
  YELLOW := [true, true, false]
  MAGENTA := [true, false, true]
  CYAN := [false, true, true]
  WHITE := [true, true, true]
  OFF := [false, false, false]

  /**
  Common color sequences for convenience.
  */
  RGB-SEQUENCE -> List:
    return [RED, GREEN, BLUE]
  RAINBOW-SEQUENCE -> List:
    return [RED, YELLOW, GREEN, CYAN, BLUE, MAGENTA]
  POLICE-SEQUENCE -> List:
    return [RED, BLUE]

  available -> bool:
    return true

  // Common colors.
  red:
    set RED[0] RED[1] RED[2]
  green:
    set GREEN[0] GREEN[1] GREEN[2]
  blue:
    set BLUE[0] BLUE[1] BLUE[2]
  yellow:
    set YELLOW[0] YELLOW[1] YELLOW[2]
  magenta:
    set MAGENTA[0] MAGENTA[1] MAGENTA[2]
  cyan:
    set CYAN[0] CYAN[1] CYAN[2]
  white:
    set WHITE[0] WHITE[1] WHITE[2]
  off:
    set OFF[0] OFF[1] OFF[2]

class FakeStrobe extends Strobe:
  set r/bool g/bool b/bool:
    print "Strobe: Setting R:$r G:$g B:$b"
  sequence --speed-ms/int=100 --colors/List?=null:
    print "Starting strobe sequence"

class NoStrobe extends Strobe:
  available -> bool:
    return false
  set r/bool g/bool b/bool:
  sequence --speed-ms/int=100 --colors/List?=null:

/**
Gpio Based Strobe implementation with configurable pins and initial value.
Supports both normal and inverted logic through the initial-value parameter.
*/
class GpioBasedStrobe extends Strobe:
  pinR_/ gpio.Pin
  pinG_/ gpio.Pin
  pinB_/ gpio.Pin
  initial-value_/ int

  constructor pin-r/int pin-g/int pin-b/int --initial-value/int=0:
    initial-value_ = initial-value
    pinR_ = gpio.Pin pin-r --output=true --value=initial-value
    pinG_ = gpio.Pin pin-g --output=true --value=initial-value
    pinB_ = gpio.Pin pin-b --output=true --value=initial-value

  /**
  Set the strobe color directly, will stop any running sequence.
  */
  set r/bool g/bool b/bool:
    stop-sequence_
    set_ r g b

  set_ r/bool g/bool b/bool:
    pinR_.set (if r != (initial-value_ == 1): 1 else: 0)
    pinG_.set (if g != (initial-value_ == 1): 1 else: 0)
    pinB_.set (if b != (initial-value_ == 1): 1 else: 0)

  sequence-mode_/ bool := false
  sequence-task_/ Task? := null

  sequence --speed-ms/int=100 --colors/List?=null:
    if sequence-mode_:
      stop-sequence_

    color-sequence/List := colors ? colors : RAINBOW-SEQUENCE
    
    sequence-mode_ = true
    sequence-task_ = task --background=true::
      try:
        while sequence-mode_:
          color-sequence.do: |color/List|
            if not sequence-mode_:
              break
            r := color[0]
            g := color[1]
            b := color[2]
            set_ r g b
            sleep (Duration --ms=speed-ms)
      finally:
        set_ OFF[0] OFF[1] OFF[2]  // Turn off when done.

  /**
  Internal method to stop sequence mode.
  */
  stop-sequence_:
    if not sequence-mode_:
      return  // Not running.
    sequence-mode_ = false
    if sequence-task_:
      sequence-task_.cancel
      sequence-task_ = null
      yield // Ensure the task is fully cancelled before proceeding.

/**
Standard strobe implementation using pins 21, 22, 23 with normal logic (init value 0)
*/
class StandardStrobe extends GpioBasedStrobe:
  constructor --initial-value/int=0:
    super 21 22 23 --initial-value=initial-value