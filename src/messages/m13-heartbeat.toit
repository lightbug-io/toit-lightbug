import ..protocol as protocol
import io.byte-order show LITTLE-ENDIAN

class Heartbeat extends protocol.Data:
  static MT := 13
  // static GSM_SIGNAL := 4
  // static FIRMWARE_VERSION := 5
  // static BATTERY_PERCENT := 6

  constructor:
    super

  msg -> protocol.Message:
    return protocol.Message.withData MT this

  // // First byte is CSQ [0-31]. Recommended to x4 to get a percentage. Byte 2 and 3 are uint16 LE network info.
  // gsmSignal -> ByteArray:
  //   return getData GSM_SIGNAL
  // csq -> int:
  //   return gsmSignal[0]
  // csqAsPercent -> int:
  //   return csq * 4
  // networkInfo -> int:
  //   return LITTLE-ENDIAN.uint16 gsmSignal 1
  
  // firmwareVersion -> int:
  //   return getDataUint16 FIRMWARE_VERSION

  // batteryPercent -> int:
  //   return getDataUint8 BATTERY_PERCENT
