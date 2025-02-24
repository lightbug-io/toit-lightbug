import io
import system.assets
import encoding.tison
import encoding.url
import ..protocol.Message

messageToDocsUrl msg/Message -> string:
  return messageBytesToDocsURL msg.bytes

messageBytesToDocsURL msgBytes/ByteArray -> string:
  // XXX: This could also be added as part of a log viewer, rather than the app, which saves build bytes, comms bytes, etc
  baseUrl := "https://docs-next.lightbug.io"
  if shouldDocsBeLocal_:
    baseUrl = "http://localhost:8093"
  return baseUrl + "/devices/api/parse?bytes=" + ((( url.encode (stringifyAllBytes_ msgBytes) ).replace " " "").replace "0x" "")

shouldDocsBeLocal/bool? := null
shouldDocsBeLocal_ -> bool:
  if shouldDocsBeLocal != null:
    return shouldDocsBeLocal
  defines := assets.decode.get "jag.defines"
    --if-present=: tison.decode it
    --if-absent=: {:}
  if defines is not Map:
  throw "defines are malformed"
  return defines["lb-localdocs"] != ""

stringifyAllBytes_ bytes/ByteArray -> string:
  buffer := io.Buffer
  is-first := true
  bytes.do:
    if is-first: is-first = false
    else: buffer.write ", "
    buffer.write "0x$(%02x it)"
  return buffer.to-string