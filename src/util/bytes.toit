import io

stringifyAllBytes bytes/ByteArray -> string:
  buffer := io.Buffer
  is-first := true
  bytes.do:
    if is-first: is-first = false
    else: buffer.write ", "
    buffer.write "0x$(%02x it)"
  return buffer.to-string

byte-array-to-list ba/ByteArray -> List:
  l := []
  ba.do: | byte |
    l.add byte
  return l