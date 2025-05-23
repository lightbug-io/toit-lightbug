import i2c
import io
import .base
import .i2c
import .strobe

// A fake device, that might be useful sometimes while testing
class Fake implements Device:
  name -> string:
    return "Fake"
  strobe -> Strobe:
    return NoStrobe
  messages-supported -> List:
    return []
  messages-not-supported -> List:
    return []
  reinit -> bool:
    return true
  in -> io.Reader:
    return FakeReader
  out -> io.Writer:
    return FakeWriter

class FakeReader extends io.Reader with io.InMixin:
  constructor:

  read_ -> ByteArray?:
      return #[]

class FakeWriter extends io.Writer with io.OutMixin:
  try-write_ data/io.Data from/int to/int -> int:
    bytes/ByteArray := ?
    if data is ByteArray:
      bytes = data as ByteArray
    else:
      bytes = ByteArray.from data
    print "FakeWriter: Simulating write: $bytes"
    return bytes.size
