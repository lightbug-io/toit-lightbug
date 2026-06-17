import io

// The normal casting of ByteArray to string limits to 50 bytes
// For example:
//
// print "$(some-bytes)"
// #[0x00, 0x01, 0x02, 0x03, 0x04, 0x00, 0x01, 0x02, 0x03, 0x04, 0x00, 0x01, 0x02, 0x03, 0x04, 0x00, 0x01, 0x02, 0x03, 0x04, 0x00, 0x01, 0x02, 0x03, 0x04, 0x00, 0x01, 0x02, 0x03, 0x04, 0x00, 0x01, 0x02, 0x03, 0x04, 0x00, 0x01, 0x02, 0x03, 0x04, 0x00, 0x01, 0x02, 0x03, 0x04, 0x00, 0x01, 0x02, 0x03, 0x04, ...]
//
// If you want to see more, this method is useful.
// It will print them all, in the same format
stringify-all-bytes bytes/ByteArray-> string:
  // As we know it is 50 bytes, we can just use the normal casting of ByteArray to string
  // For each group of 50 bytes, concatenate them together in to a buffer of our known size
  // and then return the buffer as a string
  
  // Note that the start of each stringification will be "#["
  // The end will normally be "]", but if we are not short, it will be ", ...]"

  // Calculate buffer capacity to prevent reallocations
  // Default format is "0xXX, ". 6 characters per byte + 1 (for the brackets and lack of trailing comma)
  capacity := bytes.size == 0 ? 3 : (bytes.size * 6) + 1
  buffer := io.Buffer.with-capacity capacity
  buffer.write "#["
  
  is-first := true
  for i := 0; i < bytes.size; i += 50:
    end := i + 50
    if end > bytes.size: end = bytes.size
    
    chunk := bytes[i..end]
    chunk-str := "$chunk"
    
    // Strip the prefix "#["
    start-idx := 2
    
    // Strip the suffix "]" or ", ...]"
    end-idx := chunk-str.size - 1
    if chunk-str.ends-with ", ...]":
      end-idx = chunk-str.size - 6
      
    if is-first:
      is-first = false
    else:
      buffer.write ", "
      
    buffer.write chunk-str[start-idx..end-idx]
    
  buffer.write "]"
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