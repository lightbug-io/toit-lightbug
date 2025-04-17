import io

stringify-all-bytes bytes/ByteArray --short=false --commas=true --hex=true -> string:
  buffer := io.Buffer
  is-first := true
  bytePrefix := ""
  if not short: bytePrefix = "0x"
  separator := " "
  if commas: separator = ", "
  bytes.do:
    if is-first: is-first = false
    else: buffer.write separator
    if hex: buffer.write "$(bytePrefix)$(%02x it)"
    else: buffer.write "$(bytePrefix)$(%02d it)"
  return buffer.to-string

byte-array-to-list ba/ByteArray -> List:
  l := []
  ba.do: | byte |
    l.add byte
  return l