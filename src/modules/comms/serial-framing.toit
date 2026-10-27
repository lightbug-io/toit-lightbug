import io
import ...protocol as protocol
import ...cust.vending_protocol show VendingProtocol

class SerialFrame:
  v3 /bool
  bytes /ByteArray
  started-us /int
  constructor .v3 .bytes .started-us:

// One reader owns the physical stream. Prefixes are recognised only between
// frames; payload bytes can contain either protocol's header or CR/LF.
class SerialFrameReader:
  require-prefix_ /bool
  busy /bool := false
  last-activity-us /int := 0

  constructor --require-prefix/bool=true:
    require-prefix_ = require-prefix

  read-next reader/io.Reader -> SerialFrame?:
    byte := reader.read-byte
    if byte != 0x3e and byte != 'L' and (require-prefix_ or byte != 3): return null
    started-us := Time.monotonic-us --since-wakeup
    last-activity-us = started-us
    busy = true
    frame := null
    try:
      error := catch:
        if byte == 0x3e:
          with-timeout --ms=250:
            length := reader.read-byte
            if length < 4 or length > VendingProtocol.BUFFER_SIZE: return null
            bytes := ByteArray length + 2
            bytes[0] = byte
            bytes[1] = length
            length.repeat: bytes[it + 2] = reader.read-byte
            if (VendingProtocol.command-payload-from-frame bytes) != null:
              frame = SerialFrame false bytes started-us
        else:
          // A maximum-size 1000-byte V3 frame takes about 1.04 s at 9600 baud.
          with-timeout --ms=1500:
            if byte == 'L':
              if reader.read-byte != 'B' or reader.read-byte != 3: return null
            low := reader.read-byte
            high := reader.read-byte
            length := low | (high << 8)
            if length < 11 or length > 1000: return null
            bytes := ByteArray length
            bytes[0] = 3
            bytes[1] = low
            bytes[2] = high
            (length - 3).repeat: bytes[it + 3] = reader.read-byte
            msg := protocol.Message.from-bytes bytes
            // Materialise both TLV sections before delivery, not just the CRC.
            msg.header
            msg.data
            if msg.checksum-calc == (bytes[length - 2] | (bytes[length - 1] << 8)):
              frame = SerialFrame true bytes started-us
      if error != null and error != DEADLINE-EXCEEDED-ERROR:
        // Structurally malformed V3 is noise; underlying reader failures must
        // still reach its owner rather than spinning forever on a closed port.
        if not ("$error".starts-with "V3 OOB"): throw error
      return frame
    finally:
      busy = false
      last-activity-us = Time.monotonic-us --since-wakeup
