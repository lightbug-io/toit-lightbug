import ..protocol as protocol
import io.byte-order show LITTLE-ENDIAN

class Heartbeat extends protocol.Data:
  static MT := 13

  constructor:
    super

  static msg -> protocol.Message:
    msg := protocol.Message MT
    return msg
