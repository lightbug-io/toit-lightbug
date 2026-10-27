import io
import lightbug.protocol as protocol
import lightbug.cust.vending_protocol show VendingProtocol
import lightbug.modules.comms.serial-framing show SerialFrameReader

class FeedReader extends io.Reader with io.InMixin:
  bytes /ByteArray := #[]
  constructor .bytes:
  read_ -> ByteArray?:
    if bytes.size == 0:
      sleep --ms=2000
      return #[]
    // Fragment every byte independently of protocol boundaries.
    result := bytes[..1]
    bytes = bytes[1..]
    return result

main:
  vending := VendingProtocol.build-command-frame VendingProtocol.Cmd_GetStat
  data := protocol.Data
  data.add-data 99 (vending + #[0x4c, 0x42, 3])
  v3 := protocol.Message.with-data 123 data
  scanner := SerialFrameReader
  reader := FeedReader (vending + #[0x4c, 0x42] + v3.bytes + vending)
  first := scanner.read-next reader
  check "vending frame" first.bytes vending
  check "vending classification" first.v3 false
  second := scanner.read-next reader
  check "V3 classification" second.v3 true
  check "payload headers not interpreted" second.bytes v3.bytes
  check "next frame retained" (scanner.read-next reader).bytes vending
  bad := v3.bytes.copy
  bad[bad.size - 1] ^= 1
  reader = FeedReader (#[0x4c, 0x42] + bad + vending)
  check "invalid CRC discarded" (scanner.read-next reader) null
  check "recovery after invalid CRC" (scanner.read-next reader).bytes vending
  optional := SerialFrameReader --require-prefix=false
  check "optional bare V3" (optional.read-next (FeedReader v3.bytes)).bytes v3.bytes
  check "bare V3 rejected by default" (scanner.read-next (FeedReader v3.bytes)) null
  check "bounded legacy partial frame" (scanner.read-next (FeedReader #[0x3e, 0x0d, 0xa3])) null
  check "partial frame releases busy flag" scanner.busy false
  check "bounded V3 partial frame" (scanner.read-next (FeedReader #[0x4c, 0x42, 3, 20, 0])) null
  check "V3 timeout releases busy flag" scanner.busy false
  check "recovery after timeout" (scanner.read-next (FeedReader vending)).bytes vending
  print "Mixed serial framing tests passed"

check label/string actual expected:
  if actual != expected: throw "$label: expected $expected, got $actual"
