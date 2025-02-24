import ..protocol.Message
import .bytes
import system.assets
import encoding.tison
import encoding.url

messageToDocsUrl msg/Message -> string:
  return messageBytesToDocsURL msg.bytes

/*
Can be used to print a link to parse a message, or bytes of a message on the docs site.
You can choose to use the local docs site by setting the lb-localdocs define to any value.
eg. jag run --device 192.168.1.181 ./src/foo.toit -D lb-localdocs=1
*/
messageBytesToDocsURL msgBytes/ByteArray -> string:
  // XXX: This could also be added as part of a log viewer, rather than the app, which saves build bytes, comms bytes, etc
  baseUrl := "https://docs.lightbug.io"
  if shouldDocsBeLocal_:
    baseUrl = "http://localhost:8093"
  return baseUrl + "/devices/api/parse?bytes=" + ((url.encode ((stringifyAllBytes msgBytes).replace " " "" --all=true)).replace "0x" "" --all=true)

shouldDocsBeLocal/bool? := null
shouldDocsBeLocal_ -> bool:
  if shouldDocsBeLocal != null:
    return shouldDocsBeLocal
  defines := assets.decode.get "jag.defines"
    --if-present=: tison.decode it
    --if-absent=: {:}
  if defines is not Map:
    throw "defines are malformed"
  shouldDocsBeLocal = defines.get "lb-localdocs" --if-absent=(:false) --if-present=(:true)
  return shouldDocsBeLocal
