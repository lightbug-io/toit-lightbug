import gpio

interface Strobe:
  available -> bool
  set r/bool g/bool b/bool

class NoStrobe implements Strobe:
  available -> bool:
    return false
  set r/bool g/bool b/bool:
    // Do nothing

class StandardStrobe implements Strobe:

  pinR/ gpio.Pin
  pinG/ gpio.Pin
  pinB/ gpio.Pin
  initial-value_/ int

  constructor --initial-value=0:
    initial-value_ = initial-value
    pinR = gpio.Pin 21 --output=true --value=initial-value
    pinG = gpio.Pin 22 --output=true --value=initial-value
    pinB = gpio.Pin 23 --output=true --value=initial-value

//

  available -> bool:
    return true

  set r/bool g/bool b/bool:
    pinR.set (if r != (initial-value_ == 1): 1 else: 0)
    pinG.set (if g != (initial-value_ == 1): 1 else: 0)
    pinB.set (if b != (initial-value_ == 1): 1 else: 0)

// Used on RH2 rev2 (only?)
class LegacyStrobe implements Strobe:

  pinR/ gpio.Pin
  pinG/ gpio.Pin
  pinB/ gpio.Pin

  constructor:
    pinR = gpio.Pin 18 --output=true
    pinG = gpio.Pin 19 --output=true
    pinB = gpio.Pin 20 --output=true

  available -> bool:
    return true

  set r/bool g/bool b/bool:
    pinR.set (if r: 1 else: 0)
    pinG.set (if g: 1 else: 0)
    pinB.set (if b: 1 else: 0)