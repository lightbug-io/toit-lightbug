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

  constructor:
    pinR = gpio.Pin 21 --output=true
    pinG = gpio.Pin 22 --output=true
    pinB = gpio.Pin 23 --output=true

  available -> bool:
    return true

  set r/bool g/bool b/bool:
    pinR.set (if r: 1 else: 0)
    pinG.set (if g: 1 else: 0)
    pinB.set (if b: 1 else: 0)