import ..protocol as protocol
import io.byte-order show LITTLE-ENDIAN

class Heartbeat extends protocol.Data:
  static MT := 13

  constructor:
    super

  msg -> protocol.Message:
    return protocol.Message.with-data MT this
