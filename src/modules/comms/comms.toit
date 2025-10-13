import ...protocol as protocol
import ...devices as devices
import ...messages as messages
import ...util.docs show message-bytes-to-docs-url
import ...util.resilience show catch-and-restart
import ...util.idgen show IdGenerator SequentialIdGenerator
import ...util.bytes show stringify-all-bytes byte-array-to-list
import .message-handler show MessageHandler
import io.reader show Reader
import io.writer show Writer
import encoding.url
import log
import io
import monitor
import monitor show Channel
import .heartbeats show Heartbeats CommsHeartbeats

class Comms:
  logger_/log.Logger
  device_ /devices.Device
  msgIdGenerator /IdGenerator
  background_ /bool

  outbox_ /Channel
  outboxTaskStarted_ /bool := false
  inboxesEnabled_ /bool := false
  heartbeats_ /Heartbeats? := null
  messageHandlers_ /List/*<MessageHandler>*/ := []  // List of message handlers

  LBSyncBytes_ /ByteArray

  TimeoutCheckEvery_ /Duration := Duration --s=2

  lastMsgId_ /int := 0
  inboxesByName /Map := Map
  latchForMessage /Map := Map
  lambdasForGoodAck /Map := Map
  lambdasForBadAck /Map := Map
  lambdasForGoodResponse /Map := Map
  lambdasForBadResponse /Map := Map
  lambdasForTimeout /Map := Map
  waitTimeouts /Map := Map

  constructor
      --device/devices.Device? = null
      // Allow passing in handlers to register on creation
      --handlers/List?/*<MessageHandler>*/ = []
      // Customizable id generator for message ids
      // Defaults to a sequential generator starting at 1, max 4_294_967_295 (uint32 max)
      --idGenerator/IdGenerator = (SequentialIdGenerator --start=1 --maxId=4_294_967_295)
      --startInbound/bool = true // Start the inbound reader (polling the device on I2C for messages)
      --open/bool = true // Send Open message and heartbeats to keep connection alive
      --reinitOnStart/bool = true // Reinitialize the device on start. Clearing buffers and subscriptions. Primarily for high throughput cases.
      --background/bool = true // Run primairy tasks as background (non-blocking) tasks
      
      --logger=(log.default.with-name "lb-comms"):

    logger_ = logger
    device_ = device
    messageHandlers_ = handlers
    msgIdGenerator = idGenerator
    background_ = background

    if device_.prefix:
      LBSyncBytes_ = #[0x4c, 0x42] // LB
    else:
      LBSyncBytes_ = #[]

    // TODO allow optional injection of an outbox?!
    outbox_ = Channel 100

    heartbeats_ = CommsHeartbeats this logger_
    start open startInbound false reinitOnStart

  heartbeats -> Heartbeats:
    return heartbeats_

  /**
   * Register a message handler.
   * Handlers should implement the MessageHandler interface.
   */
  register-handler handler/MessageHandler -> none:
    messageHandlers_.add handler
    logger_.info "Registered message handler"

  /**
   * Unregister a message handler.
   */
  unregister-handler handler/MessageHandler -> none:
    messageHandlers_.remove handler
    logger_.info "Unregistered message handler"

  start sendOpen/bool startInbound/bool startOutbox/bool reinitOnStart/bool:
    logger_.info "Comms starting"

    if reinitOnStart:
      logger_.info "Reinitializing"
      if not device_.reinit:
        logger_.error "Failed to reinitialize , but continuing..."

    if startInbound:
      task --background=background_:: catch-and-restart "processInbound_" (:: processInbound_) --logger=logger_
    if startOutbox:
      task --background=background_:: catch-and-restart "processOutbox_" (:: processOutbox_) --logger=logger_
    task --background=background_:: catch-and-restart "processAwaitTimeouts_" (:: processAwaitTimeouts_) --logger=logger_

    // In order for the Lightbug device to talk back to us, we have to open the conn
    // and keep it open with heartbeats
    if sendOpen:
      catch-and-restart "sendOpen" (:: sendOpen ) --limit=5 --restart-always=false --logger=logger_
      // Start heartbeats after successful open
      heartbeats_.start
    
    logger_.info "Comms started"

  sendOpen:
    if not (send (messages.Open.msg --data=null) --now=true --withLatch=true --timeout=(Duration --s=10)).get:
      throw "Failed to open device link"
    logger_.info "Opened device link"

  // Creates or gets an inbox by name
  // A single inbox will only deliver messages once
  inbox name/string --size/int? = 15 -> Channel:
    // Enable inboxes on first use
    if not inboxesEnabled_:
      inboxesEnabled_ = true
      logger_.info "Inboxes enabled on first use"
      
    if not inboxesByName.contains name:
      logger_.info "Created new inbox $(name)"
      inboxesByName[name] = Channel size
    else if inboxesByName[name].capacity != size:
      logger_.warn "Tried to get already created inbox $(name), now with different size"
    return inboxesByName[name]

  // Prints a report on the state and usage of inboxes
  // Can be useful for debugging inbox usage
  inbox-report:
    print "Inboxes report:"
    if not inboxesEnabled_:
      print "  Inboxes not enabled"
      return
    inboxesByName.do: | name inbox |
      print "  Inbox '$(name)': size=$(inbox.size) capacity=$(inbox.capacity)"

  // Perform a single pass of inbound processing and return a parsed message if available.
  processInboundOnce_ -> protocol.Message?:
    // Look for the next byte that is 3, which could indicate our protocol version
    if device_.in.peek-byte != 3:
      // if we don't find a 3, we can skip this byte
      device_.in.read-byte
      return null

    // Wait for a total of 3 bytes, which would also give us the length
    while not device_.in.try-ensure-buffered 3:
      logger_.debug "Inbound reader waiting for 3 bytes"
      yield
    // Peek all 3 bytes, which is protocol + message length
    b3 := device_.in.peek-bytes 3

    // last to bytes of b3 are the uint16 LE message length
    messageLength := (b3[2] << 8) + b3[1]
    // If the msgLength looks too long (over 1000, just advance, as its probably garbage)
    if messageLength > 1000:
        logger_.error "Message length probably too long, skipping: $(messageLength)"
        device_.in.read-byte
        return null

    // Try and make sure that we have enough bytes buffered to read the full potential message
    while not device_.in.try-ensure-buffered messageLength:
      logger_.debug "Inbound reader waiting for message length: $(messageLength)"
      yield

    messageBytes := device_.in.peek-bytes messageLength
    // TODO remove once we are sure its good?
    if messageBytes.size != messageLength: // Fail safe, but shouldn't happen due to the try-enure-buffered above
      logger_.error "Message length mismatch, no more bytes available? skipping message"
      device_.in.read-byte
      throw "Message length mismatch, no more bytes available? skipping message"
      return null

    e := catch --trace:
      // Extract the expected checksum from the last 2 bytes of the message (LE)
      expectedChecksumBytes := [messageBytes[messageLength - 2], messageBytes[messageLength - 1]]

      // And parse it as a protocol.Message directly from the ByteArray
      v3 := protocol.Message.from-bytes messageBytes

      // Calculate the checksum of the message data
      calculatedChecksum := v3.checksum-calc
      // calculatedChecksumBytes is LE uint16 of calculatedChecksum
      calculatedChecksumBytes := [calculatedChecksum & 0xFF, calculatedChecksum >> 8]

      // if they match, we have a message, return it
      if expectedChecksumBytes == calculatedChecksumBytes:
          // read the bytes we peeked
          device_.in.read-bytes messageLength
          return v3
      else:
        logger_.error "Checksum mismatch, skipping message"

        // Read a byte, and continue looking for a message
        device_.in.read-byte
        return null
    if e:
      // output a row of red cross emojis
      logger_.error " ❌ " * 20
      logger_.error "Error parsing message (probably garbled): $(e) $(stringify-all-bytes messageBytes)"
      logger_.error " ❌ " * 20
      // Read a byte, and continue looking for a message
      device_.in.read-byte
      return null
    // Fallback return if nothing matched
    return null

  processInbound_:
    // Keep going until we find a message
    while true:
      yield
      m := processInboundOnce_
      if m:
        processReceivedMessage_ m

  processReceivedMessage_ msg/protocol.Message:
    logger_.with-level log.DEBUG-LEVEL:
      logger_.debug "RCV: $(msg)"

    // Let any registered message handlers try and handle the message
    messageHandlers_.do: | handler |
      task:: handler.handle-message msg

    // Add to any registered inboxes (only if inboxes are enabled)
    if inboxesEnabled_:
      inboxesByName.do: | name inbox |
        if inbox.size >= inbox.capacity:
          dropped := inbox.receive
          logger_.warn "Inbox full '$name', Dropped msg type: $(dropped.type) for new type: $(msg.type)"
        logger_.debug "Inbox add '$name': $(msg.type)"
        inbox.send msg

    // Find waiting lambdas, based on the response
    isResponse := msg.header.data.has-data protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID
    isAck := msg.header.message-type == messages.MSGTYPE_GENERAL_ACK // Otherwise it is a response

    // Ack messages that are not a response or an ack, and have a msg id
    // In the future, we likely want to push some of the ack decisions, and types of ack to the message handlers (when defined?!)
    if msg.msgId and not isResponse and not isAck:
      // ACK these messages...
      ack-msg := messages.ACK.msg --data=null
      ack-msg.header.data.add-data-uint32 protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID msg.msgId
      ack-msg.header.data.add-data-uint32 protocol.Header.TYPE_MESSAGE_STATUS protocol.Header.STATUS_OK
      send-via-outbox ack-msg

    isBad := msg.header.data.has-data protocol.Header.TYPE-MESSAGE-STATUS and msg.msg-status > 0

    // If the device returned a non-OKish message status, emit a concise warning.
    logger_.with-level log.WARN-LEVEL:
      if isBad:
        statusNumStr := "n/a"
        statusName := "unknown"
        if msg.header.data.has-data protocol.Header.TYPE-MESSAGE-STATUS:
          statusNum := msg.msg-status
          statusNumStr = "$(statusNum)"
          statusName = protocol.Header.STATUS_MAP.get statusNum --if-absent=(: "unknown")
        logger_.warn "Received non-OKish message: status=$(statusNumStr) ($(statusName)) $(msg)"

    if isResponse:
      respondingTo := msg.header.data.get-data-uint protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID
      lambda := null
      if isAck:
        if isBad:
          if lambdasForBadAck.contains respondingTo:
            lambda = lambdasForBadAck[respondingTo]
        else:
          if lambdasForGoodAck.contains respondingTo:
            lambda = lambdasForGoodAck[respondingTo]
      else:
        if isBad:
          if lambdasForBadResponse.contains respondingTo:
            lambda = lambdasForBadResponse[respondingTo]
        else:
          if lambdasForGoodResponse.contains respondingTo:
            lambda = lambdasForGoodResponse[respondingTo]
      
      // And call the lambda if it exists
      if lambda:
        task::
          // Call the waiting lambda, and pass the message
          logger_.debug "Calling lambda for message: $(msg.type) responding to: $(respondingTo)"
          lambda.call msg

      // Removing any other lambdas or tracking for this message id
      waitTimeouts.remove respondingTo
      lambdasForBadAck.remove respondingTo
      lambdasForGoodAck.remove respondingTo
      lambdasForBadResponse.remove respondingTo
      lambdasForGoodResponse.remove respondingTo
      lambdasForTimeout.remove respondingTo

      // If we have a latch for this message id, set it to the responding message
      if latchForMessage.contains respondingTo:
        latchForMessage[respondingTo].set msg
      latchForMessage.remove respondingTo // And stop tracking it

  processOutbox_:
    while true:
      sendSwitching_ outbox_.receive --now=true
      yield // on each message sent


  // Send a message, and possibly do advanced things before after and during sending
  send msg/protocol.Message
      --now/bool = false // Should it be send now, of via the outbox
      --preSend/Lambda? = null
      --postSend/Lambda? = null
      --onAck/Lambda? = null
      --onNack/Lambda? = null
      --onResponse/Lambda? = null
      --onError/Lambda? = null
      --onTimeout/Lambda? = null
      --withLatch/bool = false
      --timeout/Duration = (Duration --s=60) -> monitor.Latch?:
  
    // Ensure the message has a known message id
    if not (msg.header.data.has-data protocol.Header.TYPE-MESSAGE-ID):
      msg.header.data.add-data-uint32 protocol.Header.TYPE-MESSAGE-ID msgIdGenerator.next

    logger_.with-level log.DEBUG-LEVEL:
      logger_.debug "SEND: $(msg)"

    latch := monitor.Latch
    
    // add the lambdas (if set)
    // TODO add a timeout for ack and or response too!
    shouldTrack := false
    if onAck != null:
      lambdasForGoodAck[msg.msgId] = onAck
      shouldTrack = true
    if onNack != null:
      lambdasForBadAck[msg.msgId] = onNack
      shouldTrack = true
    if onResponse != null:
      lambdasForGoodResponse[msg.msgId] = onResponse
      shouldTrack = true
    if onError != null:
      lambdasForBadResponse[msg.msgId] = onError
      shouldTrack = true
    if onTimeout != null:
      lambdasForTimeout[msg.msgId] = onTimeout
      shouldTrack = true

    if shouldTrack or withLatch:
      latchForMessage[msg.msgId] = latch
      waitTimeouts[msg.msgId] = Time.now + timeout
    
    if preSend != null:
      preSend.call msg

    sendSwitching_ msg --now=now

    if postSend != null:
      postSend.call msg

    if shouldTrack or withLatch:
      return latch
    return null

  send-new msg/protocol.Message
      --flush/bool = false
      --timeout/Duration = (Duration --s=60) -> protocol.Message?:
    // Ensure the message has a known message id
    if not (msg.header.data.has-data protocol.Header.TYPE-MESSAGE-ID):
      msg.header.data.add-data-uint32 protocol.Header.TYPE-MESSAGE-ID msgIdGenerator.next

    logger_.with-level log.DEBUG-LEVEL:
      logger_.debug "SEND: $(msg)"

    latch := monitor.Latch
    latchForMessage[msg.msgId] = latch
    waitTimeouts[msg.msgId] = Time.now + timeout

    sendSwitching_ msg --now=flush

    return latch.get

  send-new msg/protocol.Message --async 
      --callback/Lambda? = null
      --flush/bool = false
      --timeout/Duration = (Duration --s=60) -> monitor.Latch?:
    // Ensure the message has a known message id
    if not (msg.header.data.has-data protocol.Header.TYPE-MESSAGE-ID):
      msg.header.data.add-data-uint32 protocol.Header.TYPE-MESSAGE-ID msgIdGenerator.next

    logger_.with-level log.DEBUG-LEVEL:
      logger_.debug "SEND: $(msg)"

    latch := monitor.Latch
    latchForMessage[msg.msgId] = latch
    waitTimeouts[msg.msgId] = Time.now + timeout

    sendSwitching_ msg --now=flush

    if callback:
      task::
        callback.call latch.get
    return latch

  // Send directly, or via the outbox
  sendSwitching_ msg/protocol.Message --now/bool?=false:
    // TODO don't call this on both the outbox and regular paths, as it is messy
    if now:
      // Ensure the message has a known message id
      if not (msg.header.data.has-data protocol.Header.TYPE-MESSAGE-ID):
        msg.header.data.add-data-uint32 protocol.Header.TYPE-MESSAGE-ID msgIdGenerator.next

      m := LBSyncBytes_ + msg.bytes

      // Send the message
      device_.out.write m --flush=true
      logger_.with-level log.DEBUG-LEVEL:
        logger_.debug "SNT msg: $(stringify-all-bytes m) $(message-bytes-to-docs-url m)"
    else:
      // TODO: It might be nice to allow the outbox to dedeuplicate messages sometimes?
      send-via-outbox msg
      logger_.with-level log.DEBUG-LEVEL:
        logger_.debug "SNT (outbox) msg of type: $(msg.type) $(message-bytes-to-docs-url msg.bytes)"

  // Send a message via the outbox
  send-via-outbox msg/protocol.Message:
    // Start the outbox task if it hasn't been started yet
    if not outboxTaskStarted_:
      outboxTaskStarted_ = true
      task --background=background_:: catch-and-restart "processOutbox_" (:: processOutbox_) --logger=logger_
      
    // If the outbox is full, remove the oldest message, and add the new one
    // XXX TODO or do we want to actually force send a bunch of them in this case?!
    if outbox_.size == outbox_.capacity:
      // TODO should cleanup the lambdas for the removed message, or wait for them to timeout?
      droppedMsg := outbox_.receive
      logger_.warn "Outbox full, Dropped message of type: $(droppedMsg.type) in favour of new message of type: $(msg.type)"
    // We don't log the send here, as it will be sent later when the outbox is processed
    outbox_.send msg

  // Send raw bytes, without any protocol wrapping
  send-raw-bytes bytes/ByteArray --flush=true:
    device_.out.write bytes --flush=flush
    // If there are less than 500 bytes, log them
    logger_.with-level log.DEBUG-LEVEL:
      if bytes.size < 500:
        logger_.debug "SNT raw: $(stringify-all-bytes bytes) $(message-bytes-to-docs-url bytes)"
      else:
        logger_.debug "SNT raw: $(bytes.size) bytes"

  processAwaitTimeouts_:
    while true:
      yield
      sleep TimeoutCheckEvery_
      waitTimeouts.do --keys=true: | key |
        durationSinceTimeout := Duration.since waitTimeouts[key]
        if (durationSinceTimeout > (Duration --s=0)):
          logger_.debug "Timeout for message: $(key) expired $(durationSinceTimeout) ago"
          
          // Call timeout callback if it exists
          if lambdasForTimeout.contains key:
            task --background=true::
              logger_.debug "Calling timeout lambda for message: $(key)"
              lambdasForTimeout[key].call
          
          // Remove the timeout key, complete the latch, and remove all callbacks
          waitTimeouts.remove key
          latchForMessage[key].set null // null, indicating there was no message received before the timeout
          latchForMessage.remove key
          lambdasForBadAck.remove key
          lambdasForGoodAck.remove key
          lambdasForBadResponse.remove key
          lambdasForGoodResponse.remove key
          lambdasForTimeout.remove key
        else:
          // not yet timed out
          // logger_.debug "Not yet timed out: $(key) $(durationSinceTimeout) left"
