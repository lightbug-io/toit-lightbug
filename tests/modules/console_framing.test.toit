import io
import lightbug.modules.comms.console-framing show HexLineReader HexLineWriter

class ChunkReader extends io.Reader with io.InMixin:
  chunks_ /List
  index_ /int := 0

  constructor .chunks_:

  read_ -> ByteArray?:
    if index_ == chunks_.size:
      return null
    result := chunks_[index_]
    index_++
    return result

class MemoryWriter extends io.Writer with io.OutMixin:
  bytes /ByteArray := #[]

  try-write_ data/io.Data from/int to/int -> int:
    value := data is ByteArray ? (data as ByteArray) : ByteArray.from data
    bytes += value[from..to]
    return to - from

assert-equals label/string actual expected:
  if actual != expected:
    throw "$label: expected $expected, got $actual"

main:
  test-writer
  test-reader-ignores-console-output
  test-reader-buffering-api
  print "console framing tests passed"

test-writer:
  destination := MemoryWriter
  writer := HexLineWriter destination
  writer.write #[0x03, 0x0a, 0x00, 0xff] --flush=true
  assert-equals "encoded line" destination.bytes.to-string "LBV3:030a00ff\n"

test-reader-ignores-console-output:
  // Include a literal LF inside the original V3 bytes; hex framing must keep
  // it safely inside an ordinary text line.
  reader := HexLineReader (ChunkReader [
      "boot output\r\nLBV3:030".to-byte-array,
      "a00ff\nmore logs\n".to-byte-array,
    ])
  assert-equals "decoded line" reader.read #[0x03, 0x0a, 0x00, 0xff]

test-reader-buffering-api:
  // Comms uses Reader.peek-byte/peek-bytes rather than Reader.read directly.
  // This also guards against accidentally shadowing io.Reader's own buffer.
  reader := HexLineReader (ChunkReader ["LBV3:030a00ff\n".to-byte-array])
  assert-equals "buffered frame" (reader.try-ensure-buffered 4) true
  assert-equals "peeked frame" (reader.peek-bytes 4) #[0x03, 0x0a, 0x00, 0xff]
