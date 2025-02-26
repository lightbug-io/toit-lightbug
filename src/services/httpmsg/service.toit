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

  static DEFAULT_PORT /int := 18019
  srvPort /int
  deviceComms_ /services.Comms
  deviceName_ /string // TODO could pass in the whole device?

  constructor deviceName/string deviceComms/services.Comms --port/int=DEFAULT_PORT:
    srvPort = port
    deviceComms_ = deviceComms
    deviceName_ = deviceName
    task:: catchAndRestart "lightbug-HtmlMsgServer::serveHttp" (:: serveHttp)

  serveHttp:
    log.debug "Starting lightbug-HtmlMsgServer on port $srvPort"
    network := net.open
    tcp_socket := network.tcp_listen srvPort
    // Only log INFO level server messages (especially as these come back through this log server..)
    server := http.Server --logger=(log.Logger log.INFO-LEVEL log.DefaultTarget) --max-tasks=20
    server.listen tcp_socket:: | request/http.RequestIncoming writer/http.ResponseWriter |
      resource := request.query.resource
      // TODO factor the page out into its own file
      if resource == "/":
        html := html-page deviceName_ docsUrl
        writer.headers.set "Content-Type" "text/html"
        writer.headers.set "Content-Length" html.size.stringify
        writer.write-headers 200
        writer.out.write html
      else if resource == "/post":
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
          msgLatch := deviceComms_.send msg
            --now=true
            --withLatch=true
            --timeout=(Duration --ms=5000) // 5s timeout so that /post requests don't need to remain open for ages
            --preSend=(:: writer.out.write "$(it.msgId) Sending: $(stringifyAllBytes (listToByteArray byteList) --short=true --commas=false --hex=false)\n")
            --postSend=(:: writer.out.write "$(it.msgId) Sent: $(stringifyAllBytes msg.bytesForProtocol --short=true --commas=false --hex=false)\n")
          // Wait for the response (async), so that we can still send the next message
          tasksWaiting++
          task::
            response := msgLatch.get
            if response == false:
              writer.out.write "$(msg.msgId) Error: No response\n"
            else:
              writer.out.write "$(msg.msgId) Response $(response.msgId): $(stringifyAllBytes response.bytesForProtocol --short=true --commas=false --hex=false)\n"
            tasksDone++
        while tasksDone < tasksWaiting:
          sleep (Duration --ms=100)
        writer.close
      else :
        writer.headers.set "Content-Type" "text/plain"
        writer.write_headers 404
        writer.out.write "Not found\n"
      writer.close

listToByteArray l/List -> ByteArray:
  b := ByteArray l.size
  for i := 0; i < l.size; i++:
    b[i] = l[i]
  return b