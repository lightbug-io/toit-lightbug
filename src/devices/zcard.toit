import i2c
import io
import .base
import .i2c
import ..messages

ZCARD-MESSAGES := [
    // TODO
]

// The first ZCard devices
// Introduced Feb 2025
class ZCard extends LightbugDevice:
  constructor:
    super "ZCard"
  messages-supported -> List:
    return ZCARD-MESSAGES