import i2c
import io
import .base
import .i2c

// A fake device, that might be useful sometimes while testing.
class Fake implements Device:
  in -> io.Reader:
    return FakeReader
  out -> io.Writer:
    return FakeWriter

// The FakeReader doesn't need an additional `.in` method.
class FakeReader extends io.Reader:
  constructor:

  read_ -> ByteArray?:
      // log.debug "FakeReader: Simulating read operation"
      return #[]

// The FakeWriter doesn't need an additional `.out` method.
class FakeWriter extends io.Writer:
  try-write_ data/io.Data from/int to/int -> int:
    bytes/ByteArray := ?
    if data is ByteArray:
      bytes = data as ByteArray
    else:
      bytes = ByteArray.from data
    print "FakeWriter: Simulating write: $bytes"
    return bytes.size
