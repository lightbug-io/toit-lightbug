import ...protocol as protocol
import ...devices as devices
import ...services as services
import ...messages as messages
import ...util.resilience show catch-and-restart
import ...util.docs show docsUrl
import ...util.bytes show stringify-all-bytes
import .msgs show sample-messages
import .html
import http
import net
import log
import monitor show Channel
import crypto.crc
import io
import io.byte-order show LITTLE-ENDIAN

// Hosts a small HTTP server that serves a page for directly sending bytes or messages to a Lightbug device
class HttpMsg:

  static DEFAULT_PORT /int := 80
  serve-port /int
  default-messages_ /Map
  hide-screen_ /bool
  custom-actions_ /Map
  custom-handlers_ /Map
  response-message-formatter_ /Lambda
  listen-and-log-all_/bool
  inbox /Channel
  device_/devices.Device
  logger_ /log.Logger

  constructor
      device/devices.Device
      --defaults/Map?=sample-messages // A map of default messages to show on the page, similar to the messages map
      --hide-screen/bool=false // Hide the screen input...
      --custom-actions/Map={:} // A map of maps, similar to the messages map. Top level are groups, second level are the actions
      --custom-handlers/Map={:} // A map of handlers for custom actions. The key is the action name, and the value is a function that takes a writer which can be used to write a response.
      --response-message-formatter/Lambda?=null // A function that takes a writer and message and returns a string to be displayed in the response. Otherwise bytes will be shown...
      --port/int=DEFAULT_PORT
      --serve/bool=true
      --logger/log.Logger=(log.default.with-name "lb-httpmsg")
      --subscribe-lora/bool=false
      --listen-and-log-all/bool=false:
    logger_ = logger
    default-messages_ = defaults
    hide-screen_ = hide-screen
    serve-port = port
    device_ = device
    custom-actions_ = custom-actions
    custom-handlers_ = custom-handlers
    if device.strobe.available:
      custom-actions_["Strobe"] = {
        "Off": "custom:strobe:OFF",
        "R": "custom:strobe:R",
        "G": "custom:strobe:G",
        "B": "custom:strobe:B",
        "C": "custom:strobe:C",
        "M": "custom:strobe:M",
        "Y": "custom:strobe:Y",
        "W": "custom:strobe:W",
        "Party": "custom:strobe:PARTY",
      }
      if not custom-handlers_.get "strobe:OFF":
        custom-handlers_["strobe:OFF"] = (:: | writer |
          writer.write "Strobe: Off\n"
          device.strobe.off
        )
      if not custom-handlers_.get "strobe:R":
        custom-handlers_["strobe:R"] = (:: | writer |
          writer.write "Strobe: Red\n"
          device.strobe.red
        )
      if not custom-handlers_.get "strobe:G":
        custom-handlers_["strobe:G"] = (:: | writer |
          writer.write "Strobe: Green\n"
          device.strobe.green
        )
      if not custom-handlers_.get "strobe:B":
        custom-handlers_["strobe:B"] = (:: | writer |
          writer.write "Strobe: Blue\n"
          device.strobe.blue
        )
      if not custom-handlers_.get "strobe:C":
        custom-handlers_["strobe:C"] = (:: | writer |
          writer.write "Strobe: Cyan\n"
          device.strobe.cyan
        )
      if not custom-handlers_.get "strobe:M":
        custom-handlers_["strobe:M"] = (:: | writer |
          writer.write "Strobe: Magenta\n"
          device.strobe.magenta
        )
      if not custom-handlers_.get "strobe:Y":
        custom-handlers_["strobe:Y"] = (:: | writer |
          writer.write "Strobe: Yellow\n"
          device.strobe.yellow
        )
      if not custom-handlers_.get "strobe:W":
        custom-handlers_["strobe:W"] = (:: | writer |
          writer.write "Strobe: White\n"
          device.strobe.white
        )
      if not custom-handlers_.get "strobe:PARTY":
        custom-handlers_["strobe:PARTY"] = (:: | writer |
          writer.write "Strobe: Party\n"
          device.strobe.sequence --speed-ms=10 --colors=device.strobe.RAINBOW-SEQUENCE
        )
    if response-message-formatter != null:
      response-message-formatter_ = response-message-formatter
    else:
      response-message-formatter_ = (:: | writer msg prefix |
        e := catch:
          writer.write "$(prefix) $(stringify-all-bytes msg.bytes-for-protocol --short=true --commas=false --hex=false)\n"
        if e:
          // do nothing for now (is this needed or caught higher up?)
      )

    // Create an inbox to receive all messages on, that can be shown to the user via /poll logging
    listen-and-log-all_ = listen-and-log-all
    if listen-and-log-all:
      inbox = device.comms.inbox "httpmsg" --size=20
    else:
      inbox = Channel 1

    if subscribe-lora:
      device.comms.send (messages.LORA.subscribe-msg --ms=1000)

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
    html := html-page device_ docsUrl default-messages_ hide-screen_ custom-actions_
    writer.headers.set "Content-Type" "text/html"
    writer.headers.set "Content-Length" html.size.stringify
    writer.write_headers 200
    writer.out.write html
    writer.close

  handle-post request/http.RequestIncoming writer/http.ResponseWriter:
    try:
      writer.headers.set "Content-Type" "text/plain"
      writer.headers.set "Access-Control-Allow-Origin" "*"
      writer.write_headers 200
      handle-post-string request.body.read-all.to-string writer.out
    finally:
      writer.close
  
  handle-post-string input/string writer/io.Writer:
    e := catch --trace=true:
        // Split into lines
        lines := ((input.replace "," " ").replace "  " " ").split "\n"

        // Check for custom: lines, and process and remove them...
        lines.do: |line|
          if line.starts_with "custom:":
            if custom-handlers_.get (line.replace "custom:" ""):
              custom-handlers_[line.replace "custom:" ""].call writer
            lines.remove line

        // Strings to bytes, with checksum injection
        byteCount := 0
        lines.do: |line|
          byteCount += (line.split " ").size
        b := ByteArray byteCount
        written := 0
        lines.do: |line|
          lineParts := line.split " "
          lineStartPos := written
          for i := 0; i < lineParts.size; i++:
            b[written] = int.parse lineParts[i]
            written++
          // Checksum injection
          // lineParts is longer than 2, and the last 2 bytes written are 255 255, calc a checksum and replace them
          if lineParts.size > 2 and b[written - 2] == 255 and b[written - 1] == 255:
            checksum := crc.crc16-xmodem (b.byte-slice lineStartPos (written - 2) )
            LITTLE-ENDIAN.put-uint16 b (written - 2) checksum
            logger_.debug "Checksum injected: $(checksum) as bytes $(b[written - 2]) $(b[written - 1])"

        // Send it (RAW), if there are multiple messages to send (speed optimization)
        if lines.size > 1:
          device_.comms.send-raw-bytes b
          lines.do: |line|
            l := []
            ((line.split " ").do: |s| l.add (int.parse s))
            msg := protocol.Message.from-list l // TODO account for if the bytes are not a msg....
            writer.try-write "Sent (raw): $(stringify-all-bytes msg.bytes-for-protocol --short=true --commas=false --hex=false)\n"
            if not listen-and-log-all_:
              // TODO listen to the responses and output them? (wait max 5s?)
              // if not response:
              //   writer.out.write "$(msg.msgId) No response in $(wait-for-response)ms...\n"
              // else:
              //   write-msg-out writer response "Received"
        if lines.size == 1:
          tasksWaiting := 0
          tasksDone := 0
          lines.do: |line|
            l := []
            ((line.split " ").do: |s| l.add (int.parse s))
            msg := protocol.Message.from-list l
            wait-for-response := 5000
            msgLatch := device_.comms.send msg
              --withLatch=true
              --timeout=(Duration --ms=wait-for-response) // 5s timeout so that /post requests don't need to remain open for ages
              --preSend=(:: writer.write "$(it.msgId) Sending: $(stringify-all-bytes (list-to-byte-array l) --short=true --commas=false --hex=false)\n")
              --postSend=(:: writer.write "$(it.msgId) Sent: $(stringify-all-bytes msg.bytes-for-protocol --short=true --commas=false --hex=false)\n")
            // Wait for the response (async), so that we can still send the next message
            tasksWaiting++
            task::
              e := catch:
                try:
                  response := msgLatch.get
                  if not response:
                    writer.write "$(msg.msgId) No response in $(wait-for-response)ms...\n"
                  else:
                    // Only write out the response if we are not listening to all messages, as then it will be logged anyway
                    if not listen-and-log-all_:
                      write-msg-out writer response "Received"
                finally:
                  tasksDone++
              if e:
                logger_.error "Error in handle-post task: $e"
          while tasksDone < tasksWaiting:
            sleep (Duration --ms=100)
    if e:
      logger_.error "Error in handle-post: $e"

  write-msg-out writer/io.Writer msg/protocol.Message prefix/string="":
    prefix = "$(prefix) $(msg.msgId)"
    if msg.response-to:
        prefix = "$(prefix) Response $(msg.response-to):"

    if response-message-formatter_ != null:
      response-message-formatter_.call writer msg prefix
    else:
      writer.write "$(prefix) $(stringify-all-bytes msg.bytes-for-protocol --short=true --commas=false --hex=false)\n"

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
      write-msg-out writer.out polling-messages.receive "Received"
    while inbox.size > 0:
      msg := inbox.receive
      write-msg-out writer.out msg "Received"
    writer.close


list-to-byte-array l/List -> ByteArray:
  b := ByteArray l.size
  for i := 0; i < l.size; i++:
    b[i] = l[i]
  return b