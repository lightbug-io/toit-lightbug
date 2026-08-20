import io

/**
Frames V3 console messages as `LBV3:<hex>\n` and ignores other console lines.
*/
V3-CONSOLE-PREFIX ::= "LBV3:"
MAX-CONSOLE-LINE-BYTES ::= 8_192

class HexLineWriter extends io.Writer with io.OutMixin:
  destination_ /io.Writer

  constructor destination/io.Writer:
    destination_ = destination

  try-write_ data/io.Data from/int to/int -> int:
    bytes := data is ByteArray ? (data as ByteArray) : ByteArray.from data
    payload := bytes[from..to]
    line := V3-CONSOLE-PREFIX
    payload.do: | byte |
      line += "$(%02x byte)"
    line += "\n"
    destination_.write line.to-byte-array --flush=true
    return to - from

class HexLineReader extends io.Reader with io.InMixin:
  source_ /io.Reader
  // Do not call this `buffered_`: io.Reader already owns that field for its
  // parsed-byte buffer. Reusing its name corrupts Reader.peek-byte.
  line-buffer_ /ByteArray := #[]

  constructor source/io.Reader:
    source_ = source

  read_ -> ByteArray?:
    while true:
      decoded := extract-line_
      if decoded != null:
        return decoded

      chunk := source_.read
      if chunk == null:
        return null
      line-buffer_ += chunk

      // A stream of binary garbage without a line ending must not grow the
      // host/device buffer forever. Keep only the possible start of a prefix.
      if line-buffer_.size > MAX-CONSOLE-LINE-BYTES:
        line-buffer_ = line-buffer_[line-buffer_.size - V3-CONSOLE-PREFIX.size..]

  extract-line_ -> ByteArray?:
    line-end := -1
    line-buffer_.size.repeat: | i |
      if line-end == -1 and line-buffer_[i] == 0x0a:
        line-end = i
    if line-end == -1:
      return null

    line := line-buffer_[0..line-end]
    line-buffer_ = line-buffer_[line-end + 1..]
    if line.size > 0 and line[line.size - 1] == 0x0d:
      line = line[0..line.size - 1]
    if not has-prefix_ line:
      return null
    return decode-hex_ line[V3-CONSOLE-PREFIX.size..]

  has-prefix_ line/ByteArray -> bool:
    if line.size < V3-CONSOLE-PREFIX.size:
      return false
    V3-CONSOLE-PREFIX.size.repeat: | i |
      if line[i] != V3-CONSOLE-PREFIX[i]:
        return false
    return true

  decode-hex_ encoded/ByteArray -> ByteArray?:
    if encoded.size == 0 or encoded.size % 2 != 0:
      return null
    decoded := ByteArray encoded.size / 2
    for i := 0; i < encoded.size; i += 2:
      high := hex-value_ encoded[i]
      low := hex-value_ encoded[i + 1]
      if high < 0 or low < 0:
        return null
      decoded[i / 2] = (high << 4) + low
    return decoded

  hex-value_ byte/int -> int:
    if byte >= '0' and byte <= '9':
      return byte - '0'
    if byte >= 'a' and byte <= 'f':
      return byte - 'a' + 10
    if byte >= 'A' and byte <= 'F':
      return byte - 'A' + 10
    return -1
