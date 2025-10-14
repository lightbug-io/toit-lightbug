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
import crypto.crc
import io
import io.byte-order show LITTLE-ENDIAN
import encoding.json

// Hosts a small HTTP server that serves a page for directly sending bytes or messages to a Lightbug device
class HttpMsg:

  static DEFAULT_PORT /int := 80
  serve-port /int
  response-message-formatter_ /Lambda
  listen-and-log-all_/bool
  inbox /Channel
  device_/devices.Device
  logger_ /log.Logger

  constructor
      device/devices.Device
      --response-message-formatter/Lambda?=null // A function that takes a writer and message and returns a string to be displayed in the response. Otherwise bytes will be shown...
      --port/int=DEFAULT_PORT
      --serve/bool=true
      --logger/log.Logger=(log.default.with-name "lb-httpmsg")
      --subscribe-lora/bool=false
      --listen-and-log-all/bool=false:
    logger_ = logger
    serve-port = port
    device_ = device
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
      device.comms.send (messages.LORA.subscribe-msg --interval=1000)

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
    else if resource == "/post-receive":
      handle-post-receive request writer
    else if resource == "/poll":
      handle-poll request writer
    else :
      writer.headers.set "Content-Type" "text/plain"
      writer.write_headers 404
      writer.out.write "Not found\n"
    writer.close

  handle-page request/http.RequestIncoming writer/http.ResponseWriter:
    html := html-page device_ docsUrl
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
      // Support text, binary, and form-encoded JSON formats.
      ctype := request.headers.get "Content-Type"
      ctype-str := ctype ? ctype[0] : ""
      if ctype-str.starts-with "application/x-www-form-urlencoded":
        // Parse form data to extract JSON payload.
        body-str := request.body.read-all.to-string
        bytes := parse-form-json-bytes_ body-str
        if bytes:
          handle-post-bytes bytes writer.out
        else:
          writer.out.write "Error: Could not parse form payload\n"
      else if ctype-str == "application/octet-stream":
        buf := request.body.read-all
        handle-post-bytes buf writer.out
      else:
        handle-post-string request.body.read-all.to-string writer.out
    finally:
      writer.close

  handle-post-receive request/http.RequestIncoming writer/http.ResponseWriter:
    try:
      writer.headers.set "Content-Type" "text/plain"
      writer.headers.set "Access-Control-Allow-Origin" "*"
      writer.write_headers 200
      // Support text, binary, and form-encoded JSON formats.
      ctype := request.headers.get "Content-Type"
      ctype-str := ctype ? ctype[0] : ""
      if ctype-str.starts-with "application/x-www-form-urlencoded":
        // Parse form data to extract JSON payload.
        body-str := request.body.read-all.to-string
        bytes := parse-form-json-bytes_ body-str
        if bytes:
          handle-post-receive-bytes bytes writer.out
        else:
          writer.out.write "Error: Could not parse form payload\n"
      else if ctype-str == "application/octet-stream":
        buf := request.body.read-all
        handle-post-receive-bytes buf writer.out
      else:
        handle-post-receive-string request.body.read-all.to-string writer.out
    finally:
      writer.close
  
  handle-post-string input/string writer/io.Writer:
    e := catch --trace=true:
        // Split into lines
        lines := ((input.replace "," " ").replace "  " " ").split "\n"

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
            msg := protocol.Message.from-bytes (list-to-byte-array l) // TODO account for if the bytes are not a msg....
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
            msg := protocol.Message.from-bytes (list-to-byte-array l)
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

  handle-post-bytes input/ByteArray writer/io.Writer:
    e := catch --trace=true:
        // Treat the input as raw protocol message bytes.
        // Split on newline (0x0A) if present, otherwise treat as single message.
        parts := []
        start := 0
        for i := 0; i < input.size; i++:
          if input[i] == 10: // LF
            if i > start:
              parts.add (input.copy start i)
            start = i + 1
        if start < input.size:
          parts.add (input.copy start input.size)

        if parts.size > 1:
          // Send raw combined when there are multiple parts for efficiency.
          device_.comms.send-raw-bytes input
          parts.do: |p/ByteArray|
            if p.size == 0: continue.do
            msg := protocol.Message.from-bytes p
            writer.try-write "Sent (raw): $(stringify-all-bytes msg.bytes-for-protocol --short=true --commas=false --hex=false)\n"
        else if parts.size == 1:
          // Single message.
          p := parts[0]
          if p.size == 0: return
          msg := protocol.Message.from-bytes p
          wait-for-response := 5000
          msgLatch := device_.comms.send msg
            --withLatch=true
            --timeout=(Duration --ms=wait-for-response)
            --preSend=(:: writer.write "$(it.msgId) Sending: $(stringify-all-bytes p --short=true --commas=false --hex=false)\n")
            --postSend=(:: writer.write "$(it.msgId) Sent: $(stringify-all-bytes msg.bytes-for-protocol --short=true --commas=false --hex=false)\n")
          e2 := catch:
            response := msgLatch.get
            if not response:
              writer.write "$(msg.msgId) No response in $(wait-for-response)ms...\n"
            else:
              if not listen-and-log-all_:
                write-msg-out writer response "Received"
          if e2:
            logger_.error "Error sending raw message: $e2"
    if e:
      logger_.error "Error in handle-post-bytes: $e"


  handle-post-receive-string input/string writer/io.Writer:
    e := catch --trace=true:
        // Split into lines.
        lines := ((input.replace "," " ").replace "  " " ").split "\n"

        // Strings to bytes, with checksum injection.
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
          // Checksum injection.
          // lineParts is longer than 2, and the last 2 bytes written are 255 255, calc a checksum and replace them.
          if lineParts.size > 2 and b[written - 2] == 255 and b[written - 1] == 255:
            checksum := crc.crc16-xmodem (b.byte-slice lineStartPos (written - 2) )
            LITTLE-ENDIAN.put-uint16 b (written - 2) checksum
            logger_.debug "Checksum injected: $(checksum) as bytes $(b[written - 2]) $(b[written - 1])"

        // Simulate receiving the messages.
        lines.do: |line|
          l := []
          ((line.split " ").do: |s| l.add (int.parse s))
          msg := protocol.Message.from-bytes (list-to-byte-array l)
          writer.write "Simulated receive: $(stringify-all-bytes msg.bytes-for-protocol --short=true --commas=false --hex=false)\n"
          device_.comms.simulate-receive msg
    if e:
      logger_.error "Error in handle-post-receive: $e"

  handle-post-receive-bytes input/ByteArray writer/io.Writer:
    e := catch --trace=true:
        // Split on newlines if present, otherwise treat as single message.
        start := 0
        for i := 0; i < input.size; i++:
          if input[i] == 10: // LF
            if i > start:
              p := input.copy start i
              msg := protocol.Message.from-bytes p
              writer.write "Simulated receive: $(stringify-all-bytes msg.bytes-for-protocol --short=true --commas=false --hex=false)\n"
              device_.comms.simulate-receive msg
            start = i + 1
        if start < input.size:
          p := input.copy start input.size
          msg := protocol.Message.from-bytes p
          writer.write "Simulated receive: $(stringify-all-bytes msg.bytes-for-protocol --short=true --commas=false --hex=false)\n"
          device_.comms.simulate-receive msg
    if e:
      logger_.error "Error in handle-post-receive-bytes: $e"


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

  /**
  Parses form-encoded data to extract JSON payload with bytes array.
  Expected format: "payload=%7B%22bytes%22%3A%5B1%2C2%2C3%5D%7D"
  Returns ByteArray or null if parsing fails.
  */
  parse-form-json-bytes_ body/string -> ByteArray?:
    e := catch:
      // URL decode and extract payload field.
      // Simple approach: find "payload=" and extract the value.
      payload-prefix := "payload="
      idx := body.index-of payload-prefix
      if idx == -1: return null
      
      // Extract the URL-encoded JSON (up to next & or end of string).
      start := idx + payload-prefix.size
      end-idx := body.index-of "&"
      end := end-idx == -1 ? body.size : end-idx
      
      encoded-json := body[start..end]
      
      // URL decode the JSON string.
      decoded-json := url-decode_ encoded-json
      
      // Parse JSON.
      parsed := json.decode decoded-json.to-byte-array
      if parsed is not Map: return null
      
      bytes-array := parsed.get "bytes"
      if bytes-array is not List: return null
      
      // Convert to ByteArray.
      result := ByteArray bytes-array.size
      for i := 0; i < bytes-array.size; i++:
        result[i] = bytes-array[i]
      
      return result
    if e:
      log.error "Error parsing form JSON: $e"
      return null
    return null

  /**
  URL decodes a string (handles %XX encoding).
  */
  url-decode_ str/string -> string:
    result := ""
    i := 0
    while i < str.size:
      if str[i] == '%' and i + 2 < str.size:
        // Decode %XX
        hex := str[i + 1..i + 3]
        byte-val := int.parse hex --radix=16
        result += string.from-rune byte-val
        i += 3
      else if str[i] == '+':
        result += " "
        i++
      else:
        result += str[i..i + 1]
        i++
    return result


list-to-byte-array l/List -> ByteArray:
  b := ByteArray l.size
  for i := 0; i < l.size; i++:
    b[i] = l[i]
  return b