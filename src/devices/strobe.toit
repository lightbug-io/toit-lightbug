import gpio

interface Strobe:
  available -> bool
  set r/bool g/bool b/bool
  // Common colors.
  red
  green
  blue
  yellow
  magenta
  cyan
  white
  off

class NoStrobe implements Strobe:
  available -> bool:
    return false
  set r/bool g/bool b/bool:
  red:
  green:
  blue:
  yellow:
  magenta:
  cyan:
  white:
  off:

/**
Base strobe implementation with configurable pins and initial value.
Supports both normal and inverted logic through the initial-value parameter.
*/
class BaseStrobe implements Strobe:
  pinR_/ gpio.Pin
  pinG_/ gpio.Pin
  pinB_/ gpio.Pin
  initial-value_/ int

  constructor pin-r/int pin-g/int pin-b/int --initial-value/int=0:
    initial-value_ = initial-value
    pinR_ = gpio.Pin pin-r --output=true --value=initial-value
    pinG_ = gpio.Pin pin-g --output=true --value=initial-value
    pinB_ = gpio.Pin pin-b --output=true --value=initial-value

  available -> bool:
    return true

  set r/bool g/bool b/bool:
    pinR_.set (if r != (initial-value_ == 1): 1 else: 0)
    pinG_.set (if g != (initial-value_ == 1): 1 else: 0)
    pinB_.set (if b != (initial-value_ == 1): 1 else: 0)
  
  // Convenience methods for common colors.
  red:
    set true false false
  green:
    set false true false
  blue:
    set false false true
  yellow:
    set true true false
  magenta:
    set true false true
  cyan:
    set false true true
  white:
    set true true true
  off:
    set false false false

/**
Standard strobe implementation using pins 21, 22, 23 with normal logic (init value 0)
*/
class StandardStrobe extends BaseStrobe:
  constructor --initial-value/int=0:
    super 21 22 23 --initial-value=initial-value