import ..protocol.message
import .bytes
import system.assets
import encoding.tison
import encoding.url

/*
You can choose to use the local docs site by setting the lb-localdocs define to any value.
eg. jag run --device 192.168.1.181 ./src/foo.toit -D lb-localdocs=1
*/

// Returns the URL of the Lightbug docs site.
docsUrl -> string:
  baseUrl := "https://docs.lightbug.io"
  if shouldDocsBeLocal_:
    baseUrl = "http://localhost:8093"
  return baseUrl

// Returns a link to parse a message on the Lightbug docs site.
messageToDocsUrl msg/Message -> string:
  return messageBytesToDocsURL msg.bytes

// Returns a link to parse bytes of a message on the Lightbug docs site.
messageBytesToDocsURL msgBytes/ByteArray -> string:
  // XXX: This could also be added as part of a log viewer, rather than the app, which saves build bytes, comms bytes, etc
  baseUrl := docsUrl
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
