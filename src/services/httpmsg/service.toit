import ...protocol as protocol
import ...devices as devices
import ...services as services
import ...messages as messages
import ...util.resilience show catch-and-restart
import ...util.docs show docsUrl
import ...util.bytes show stringify-all-bytes
import .html
import http
import net
import log
import monitor show Channel

// Hosts a small HTTP server that serves a page for directly sending bytes or messages to a Lightbug device
class HttpMsg:

  static DEFAULT_PORT /int := 80
  serve-port /int
  custom-actions_ /Map
  response-message-formatter_ /Lambda
  device-comms_ /services.Comms
  listen-and-log-all_/bool
  inbox /Channel
  device_/devices.Device
  logger_ /log.Logger

  constructor
      device/devices.Device
      device-comms/services.Comms
      --custom-actions/Map={:} // A map of maps, similar to the messages map. Top level are groups, second level are the actions
      --response-message-formatter/Lambda?=null // A function that takes a writer and message and returns a string to be displayed in the response. Otherwise bytes will be shown...
      --port/int=DEFAULT_PORT
      --serve/bool=true
      --logger/log.Logger=(log.default.with-name "lb-httpmsg")
      --subscribe-lora/bool=false
      --listen-and-log-all/bool=false:
    logger_ = logger
    serve-port = port
    device_ = device
    device-comms_ = device-comms
    custom-actions_ = custom-actions
    if response-message-formatter != null:
      response-message-formatter_ = response-message-formatter
    else:
      response-message-formatter_ = (:: | writer msg prefix |
        writer.out.write "$(prefix) $(stringify-all-bytes msg.bytes-for-protocol --short=true --commas=false --hex=false)\n"
      )

    // Create an inbox to receive all messages on, that can be shown to the user via /poll logging
    listen-and-log-all_ = listen-and-log-all
    if listen-and-log-all:
      inbox = device-comms_.inbox "httpmsg" --size=20
    else:
      inbox = Channel 1

    if subscribe-lora:
      device-comms.send messages.Lora.subscribe-msg

    if serve:
      service-http-catch-and-restart

  service-http-catch-and-restart:
    catch-and-restart "lightbug-HttpMsg::serve-http" (:: serve-http)

  serve-http:
    logger_.debug "Starting lightbug-HtmlMsgServer on port $serve-port"
    network := net.open
    tcp_socket := network.tcp_listen serve-port
    // Only log INFO level server messages (especially as these come back through this log server..)
    server := http.Server --logger=logger_ --max-tasks=25
    server.listen tcp_socket:: | request/http.RequestIncoming writer/http.ResponseWriter |
      handle-http-request request writer
  
  handle-http-request request/http.RequestIncoming writer/http.ResponseWriter?:
    resource := request.query.resource
    if resource == "/" or resource == "/index.html" or resource == "index.html":
      handle-page request writer
    else if resource == "/post":
      handle-post request writer
    else if resource == "/poll":
      handle-poll request writer
    else :
      writer.headers.set "Content-Type" "text/plain"
      writer.write_headers 404
      writer.out.write "Not found\n"
    writer.close

  handle-page request/http.RequestIncoming writer/http.ResponseWriter:
    html := html-page device_ docsUrl custom-actions_
    writer.headers.set "Content-Type" "text/html"
    writer.headers.set "Content-Length" html.size.stringify
    writer.write_headers 200
    writer.out.write html
    writer.close

  handle-post request/http.RequestIncoming writer/http.ResponseWriter:
    body := request.body.read-all
    bodyS := body.to-string
    try:
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
        msg := protocol.Message.from-list byteList
        // TODO detect invalid msg and let the user know..
        wait-for-response := 5000
        msgLatch := device-comms_.send msg
          --withLatch=true
          --timeout=(Duration --ms=wait-for-response) // 5s timeout so that /post requests don't need to remain open for ages
          --preSend=(:: writer.out.write "$(it.msgId) Sending: $(stringify-all-bytes (list-to-byte-array byteList) --short=true --commas=false --hex=false)\n")
          --postSend=(:: writer.out.write "$(it.msgId) Sent: $(stringify-all-bytes msg.bytes-for-protocol --short=true --commas=false --hex=false)\n")
        // Wait for the response (async), so that we can still send the next message
        tasksWaiting++
        task::
          response := msgLatch.get
          if not response:
            writer.out.write "$(msg.msgId) No response in $(wait-for-response)ms...\n"
          else:
            // Only write out the response if we are not listening to all messages, as then it will be logged anyway
            if not listen-and-log-all_:
              write-msg-out writer response "Received"
          tasksDone++
      while tasksDone < tasksWaiting:
        sleep (Duration --ms=100)
    finally:
      writer.close

  write-msg-out writer/http.ResponseWriter msg/protocol.Message prefix/string="":
    prefix = "$(prefix) $(msg.msgId)"
    if msg.response-to:
        prefix = "$(prefix) Response $(msg.response-to):"

    if response-message-formatter_ != null:
      response-message-formatter_.call writer msg prefix
    else:
      writer.out.write "$(prefix) $(stringify-all-bytes msg.bytes-for-protocol --short=true --commas=false --hex=false)\n"

  // It might be more efficient to store messages that have been received, to send
  // TODO having a "force-send" on monitor would be nice..
  polling-queue /Channel := Channel 10
  queue-output-for-polling line/string:
    if polling-queue.size > 10:
      logger_.warn "Dropping line from queue as it is full"
      polling-queue.receive
      polling-queue.send line
    else:
      polling-queue.send line
  polling-messages /Channel := Channel 10
  queue-messages-for-polling msg/protocol.Message:
    if polling-messages.size > 10:
      logger_.warn "Dropping message from queue as it is full"
      polling-messages.receive
      polling-messages.send msg
    else:
      polling-messages.send msg

  handle-poll request/http.RequestIncoming writer/http.ResponseWriter:
    writer.headers.set "Content-Type" "text/plain"
    writer.headers.set "Access-Control-Allow-Origin" "*"
    writer.write_headers 200
    while polling-queue.size > 0:
      writer.out.write polling-queue.receive
    while polling-messages.size > 0:
      write-msg-out writer polling-messages.receive "Received"
    while inbox.size > 0:
      msg := inbox.receive
      write-msg-out writer msg "Received"
    writer.close


list-to-byte-array l/List -> ByteArray:
  b := ByteArray l.size
  for i := 0; i < l.size; i++:
    b[i] = l[i]
  return b