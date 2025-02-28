import ...protocol as protocol
import ...devices as devices
import ...services as services
import ...messages as messages
import ...util.resilience show catchAndRestart
import ...util.docs show docsUrl
import ...util.bytes show stringifyAllBytes
import .html
import http
import net
import log

// Hosts a small HTTP server that serves a page for directly sending bytes or messages to a Lightbug device
class HttpMsg:

  static DEFAULT_PORT /int := 80
  serve-port /int
  custom-actions_ /Map
  device-comms_ /services.Comms
  device-name_ /string // TODO could pass in the whole device?

  constructor
      device-name/string
      device-comms/services.Comms
      --custom-actions/Map={:} // A map of maps, similar to the messages map. Top level are groups, second level are the actions
      --port/int=DEFAULT_PORT
      --serve/bool=true:
    serve-port = port
    device-comms_ = device-comms
    device-name_ = device-name
    custom-actions_ = custom-actions
    if serve:
      service-http-catchAndRestart

  service-http-catchAndRestart:
    catchAndRestart "lightbug-HttpMsg::serve-http" (:: serve-http)

  serve-http:
    log.debug "Starting lightbug-HtmlMsgServer on port $serve-port"
    network := net.open
    tcp_socket := network.tcp_listen serve-port
    // Only log INFO level server messages (especially as these come back through this log server..)
    server := http.Server --logger=(log.Logger log.INFO-LEVEL log.DefaultTarget) --max-tasks=25
    server.listen tcp_socket:: | request/http.RequestIncoming writer/http.ResponseWriter |
      handle-http-request request writer
  
  handle-http-request request/http.RequestIncoming writer/http.ResponseWriter?:
    resource := request.query.resource
    if resource == "/" or resource == "/index.html" or resource == "index.html":
      handle-page request writer
    else if resource == "/post":
      handle-post request writer
    else :
      writer.headers.set "Content-Type" "text/plain"
      writer.write_headers 404
      writer.out.write "Not found\n"
    writer.close

  handle-page request/http.RequestIncoming writer/http.ResponseWriter:
    html := html-page device-name_ docsUrl custom-actions_
    writer.headers.set "Content-Type" "text/html"
    writer.headers.set "Content-Length" html.size.stringify
    writer.write_headers 200
    writer.out.write html
    writer.close

  handle-post request/http.RequestIncoming writer/http.ResponseWriter:
    body := request.body.read-all
    bodyS := body.to-string
    writer.headers.set "Content-Type" "text/plain"
    writer.headers.set "Access-Control-Allow-Origin" "*"
    writer.write_headers 200
    tasksDone := 0
    tasksWaiting := 0
    // Assume each line is a message
    (bodyS.split "\n").do: |line|
      line = line.replace "," " "
      line = line.replace "  " " "
      byteList := []
      ((line.split " ").do: |s| byteList.add (int.parse s))
      msg := protocol.Message.fromList byteList
      // TODO detect invalid msg and let the user know..
      msgLatch := device-comms_.send msg
        --now=true
        --withLatch=true
        --timeout=(Duration --ms=5000) // 5s timeout so that /post requests don't need to remain open for ages
        --preSend=(:: writer.out.write "$(it.msgId) Sending: $(stringifyAllBytes (list-to-byte-array byteList) --short=true --commas=false --hex=false)\n")
        --postSend=(:: writer.out.write "$(it.msgId) Sent: $(stringifyAllBytes msg.bytesForProtocol --short=true --commas=false --hex=false)\n")
      // Wait for the response (async), so that we can still send the next message
      tasksWaiting++
      task::
        response := msgLatch.get
        if response == false:
          writer.out.write "$(msg.msgId) No response...\n"
        else:
          writer.out.write "$(msg.msgId) Response $(response.msgId): $(stringifyAllBytes response.bytesForProtocol --short=true --commas=false --hex=false)\n"
        tasksDone++
    while tasksDone < tasksWaiting:
      sleep (Duration --ms=100)
    writer.close

list-to-byte-array l/List -> ByteArray:
  b := ByteArray l.size
  for i := 0; i < l.size; i++:
    b[i] = l[i]
  return b