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

format-mac mac -> string:
  // Formats a MAC address represented as a ByteArray or string into
  // the canonical colon-separated lowercase hex form.
  if not mac:
    return "<unknown>"
  if mac is ByteArray:
    // Some addresses may include a leading length byte; handle 7-byte cases.
    start := mac.size > 6 ? 1 : 0
    result := ""
    for i := start; i < mac.size and i < start + 6; i++:
      if i > start:
        result += ":"
      result += "$(%02x mac[i])"
    return result
  if mac is string:
    return mac
  return "<unknown>"