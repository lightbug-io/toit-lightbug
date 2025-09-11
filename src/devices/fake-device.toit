import i2c
import io
import log
import .base
import .i2c
import ..modules.strobe
import ..modules.comms
import ..modules.buttons
import ..modules.ble
import ..modules.wifi
import ..modules.piezo show Piezo
import ..modules.haptics show Haptics
import ..modules.gnss show GNSS

// A fake device, that might be useful sometimes while testing
class Fake implements Device:
  comms_ /Comms? := null
  buttons_ /Buttons? := null
  ble_ /BLE? := null
  wifi_ /WiFi? := null
  piezo_ /Piezo? := null
  haptics_ /Haptics? := null
  gnss_ /GNSS? := null
  open_ /bool
  in_/io.Reader? := ?
  out_/io.Writer? := ?

  constructor --open/bool=true --in/io.Reader? = null --out/io.Writer? = null:
    open_ = open
    in_ = in
    out_ = out

  name -> string:
    return "Fake"
  strobe -> Strobe:
    return FakeStrobe
  comms -> Comms:
    if not comms_:
      comms_ = Comms 
          --device=this
          --open=open_
    return comms_
  buttons -> Buttons:
    if not buttons_:
      buttons_ = Buttons comms
    return buttons_
  ble -> BLE:
    if not ble_:
      ble_ = BLE --logger=(log.default.with-name "lb.ble")
    return ble_
  wifi -> WiFi:
    if not wifi_:
      wifi_ = WiFi --logger=(log.default.with-name "lb.wifi")
    return wifi_
  piezo -> Piezo:
    if not piezo_:
      piezo_ = Piezo --device=this --logger=(log.default.with-name "lb.piezo")
    return piezo_
  haptics -> Haptics:
    if not haptics_:
      haptics_ = Haptics --device=this --logger=(log.default.with-name "lb.haptics")
    return haptics_
  gnss -> GNSS:
    if not gnss_:
      gnss_ = GNSS --device=this --logger=(log.default.with-name "lb.gnss")
    return gnss_
  reinit -> bool:
    return true
  prefix -> bool:
    return false
  in -> io.Reader:
    if in_:
      return in_
    return FakeReader
  out -> io.Writer:
    if out_:
      return out_
    return FakeWriter

class FakeReader extends io.Reader with io.InMixin:
  buffer_/ByteArray := #[]

  constructor --bytes/ByteArray? = #[]:
    buffer_ = bytes

  push-bytes bytes/ByteArray -> none:
    // append bytes to the internal buffer
    if buffer_.size == 0:
      buffer_ = bytes
    else:
      b := ByteArray buffer_.size + bytes.size
      b.replace 0 buffer_ 0 buffer_.size
      b.replace buffer_.size bytes 0 bytes.size
      buffer_ = b

  read_ -> ByteArray?:
    if buffer_.size == 0:
      return null
    b := buffer_
    buffer_ = #[]
    return b

class FakeWriter extends io.Writer with io.OutMixin:
  try-write_ data/io.Data from/int to/int -> int:
    bytes/ByteArray := ?
    if data is ByteArray:
      bytes = data as ByteArray
    else:
      bytes = ByteArray.from data
    print "FakeWriter: Simulating write: $bytes"
    return bytes.size
