import ..protocol as protocol
import io.byte-order show LITTLE-ENDIAN

class Heartbeat extends protocol.Data:
  static MT := 13
  // static GSM-SIGNAL := 4
  // static FIRMWARE-VERSION := 5
  // static BATTERY-PERCENT := 6

  constructor:
    super

  msg -> protocol.Message:
    return protocol.Message.with-data MT this

  // // First byte is CSQ [0-31]. Recommended to x4 to get a percentage. Byte 2 and 3 are uint16 LE network info.
  // gsmSignal -> ByteArray:
  //   return get-data GSM-SIGNAL
  // csq -> int:
  //   return gsmSignal[0]
  // csqAsPercent -> int:
  //   return csq * 4
  // networkInfo -> int:
  //   return LITTLE-ENDIAN.uint16 gsmSignal 1
  
  // firmwareVersion -> int:
  //   return get-data-uint16 FIRMWARE-VERSION

  // batteryPercent -> int:
  //   return get-data-uint8 BATTERY-PERCENT
