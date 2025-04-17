import ...protocol as protocol
import ...devices as devices
import ...messages as messages
import ...util.docs show message-bytes-to-docs-url
import ...util.resilience show catch-and-restart
import ...util.idgen show IdGenerator RandomIdGenerator SequentialIdGenerator
import ...util.bytes show stringify-all-bytes byte-array-to-list
import io.reader show Reader
import io.writer show Writer
import encoding.url
import log
import io
import monitor
import monitor show Channel

class Comms:
  logger_/log.Logger
  device_ /devices.Device
  msgIdGenerator /IdGenerator

  outbox_ /Channel

  LBSyncBytes_ /ByteArray

  TimeoutCheckEvery_ /Duration := Duration --s=2

  lastMsgId_ /int := 0
  inboxesByName /Map := Map
  latchForMessage /Map := Map
  lambdasForGoodAck /Map := Map
  lambdasForBadAck /Map := Map
  lambdasForGoodResponse /Map := Map
  lambdasForBadResponse /Map := Map
  waitTimeouts /Map := Map

  constructor
      --device/devices.Device? = null
      --startInbound/bool = true // Start the inbound reader (polling the device on I2C for messages)
      --startOutbox/bool = true // Start the outbox (waiting for outbox messages to send over I2C)
      --sendOpen/bool = true // An Open is required to start comms and get responses ot messages. Only set to false if you will control the Open in your own code.
      --sendHeartbeat/bool = true // Send a heartbeat message every now and again to keep the connection open. Only set to false if you will control the heartbeat in your own code.
      --idGenerator/IdGenerator? = null
      --logger=(log.default.with-name "lb-comms"):

    logger_ = logger
    device_ = device
    if idGenerator == null:
      msgIdGenerator = RandomIdGenerator --lowerBound=1 --upperBound=4_294_967_295 // uint32 max
    else:
      msgIdGenerator = idGenerator

    // TODO add into the toit LB package if devices need sync bytes or not?
    // LBSyncBytes_ = #[0x4c, 0x42]
    LBSyncBytes_ = #[]

    // Start with randomish numbers for msg and page id, incase we restarted but the STM didn't
    // TODO allow optional injection of an outbox?!
    outbox_ = Channel 15
    
    start_ sendOpen sendHeartbeat startInbound startOutbox

  start_ sendOpen/bool sendHeartbeat/bool startInbound/bool startOutbox/bool:
    logger_.info "Comms starting"

    if startInbound:
      task:: catch-and-restart "processInbound_" (:: processInbound_) --logger=logger_
    if startOutbox:
      task:: catch-and-restart "processOutbox_" (:: processOutbox_) --logger=logger_
    task:: catch-and-restart "processAwaitTimeouts_" (:: processAwaitTimeouts_) --logger=logger_

    // In order for the Lightbug device to talk back to us, we have to open the conn
    // and keep it open with heartbeats
    if sendOpen:
      catch-and-restart "sendOpen_" (:: sendOpen_ ) --limit=5 --restart-always=false --logger=logger_
    if sendHeartbeat:
      task:: catch-and-restart "sendHeartbeats_" (:: sendHeartbeats_) --logger=logger_
    
    logger_.info "Comms started"

  sendOpen_:
    if not (send messages.Open.msg --now=true --withLatch=true --timeout=(Duration --s=10)).get:
      throw "Failed to open device link"
      logger_.debug "Opened device link"

  sendHeartbeats_:
    while true:
      // Send a heartbeat message every 10 seconds (via outbox)
      if not (send messages.Heartbeat.msg --withLatch=true).get:
        logger_.error "Failed to send heartbeat"
      else:
        logger_.debug "Sent heartbeat"
      sleep (Duration --s=15)

  // Creates or gets an inbox by name
  // A single inbox will only deliver messages once
  inbox name/string --size/int? = 15 -> Channel:
    if not inboxesByName.contains name:
      logger_.info "Created new inbox $(name)"
      inboxesByName[name] = Channel size
    else if inboxesByName[name].capacity != size:
      logger_.warn "Tried to get already created inbox, now with different size"
    return inboxesByName[name]

  processInbound_:
    // Keep going until we find a message
    while true:
      yield
      
      // Look for the next byte that is 3, which could indicate our protocol version
      if device_.in.peek-byte != 3:
        // if we don't find a 3, we can skip this byte
        device_.in.read-byte
        continue

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
          continue

      // Try and make sure that we have enough bytes buffered to read the full potential message
      while not device_.in.try-ensure-buffered messageLength:
        logger_.debug "Inbound reader waiting for message length: $(messageLength)"
        yield

      messageBytes := device_.in.peek-bytes messageLength
      // TODO remove once we are sure its good?
      if messageBytes.size != messageLength: // Fail safe, but shouldn't happen due to the try-enure-buffered above
        logger_.error "Message length mismatch, no more bytes availible? skipping message"
        device_.in.read-byte
        throw "Message length mismatch, no more bytes availible? skipping message"
        continue

      e := catch --trace:
        // Extract the expected checksum from the last 2 bytes of the message (LE)
        expectedChecksumBytes := [messageBytes[messageLength - 2], messageBytes[messageLength - 1]]

        // And parse it as a protocol.Message
        v3 := protocol.Message.from-list ( byte-array-to-list messageBytes )

        // Calculate the checksum of the message data
        calculatedChecksum := v3.checksum-calc
        // calculatedChecksumBytes is LE uint16 of calculatedChecksum
        calculatedChecksumBytes := [calculatedChecksum & 0xFF, calculatedChecksum >> 8]

        // if they match, we have a message, return it
        if expectedChecksumBytes == calculatedChecksumBytes:
            // read the bytes we peeked
            device_.in.read-bytes messageLength
            processReceivedMessage_ v3
        else:
          logger_.error "Checksum mismatch, skipping message"

          // Read a byte, and continue looking for a message
          device_.in.read-byte
      if e:
        // output a row of red cross emojis
        logger_.error " ❌ " * 20
        logger_.error "Error parsing message (probably garbeled): $(e) $(stringify-all-bytes messageBytes)"
        logger_.error " ❌ " * 20
        // Read a byte, and continue looking for a message
        device_.in.read-byte

  processReceivedMessage_ msg/protocol.Message:
    logger_.with-level log.DEBUG-LEVEL:
      logger_.debug "RCV msg type $(msg.type) : $(msg) $(message-bytes-to-docs-url msg.bytes)"

    // Add to any registered inboxes
    inboxesByName.do --values=true: | inbox |
      if inbox.size >= inbox.capacity:
        dropped := inbox.receive
        logger_.warn "Inbox full, Dropped message of type: $(dropped.type) in favour of new message of type: $(msg.type)"
      logger_.debug "Adding message to inbox: $(msg.type)"
      inbox.send msg

    // Find waiting lambdas, based on the response
    if msg.header.data.has-data protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID:
      respondingTo := msg.header.data.get-data-uint protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID
      isAck := msg.header.message-type == messages.MSGTYPE_GENERAL_ACK // Otherwise it is a response
      isBad := msg.header.data.has-data protocol.Header.TYPE-MESSAGE-STATUS and msg.msg-status > 0
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
      --withLatch/bool = false
      --timeout/Duration = (Duration --s=60) -> monitor.Latch?:
    logger_.with-level log.DEBUG-LEVEL:
      logger_.debug "Sending message: $(msg) $(message-bytes-to-docs-url msg.bytes)"
  
    // Ensure the message has a known message id
    if not (msg.header.data.has-data protocol.Header.TYPE-MESSAGE-ID):
      msg.header.data.add-data-uint32 protocol.Header.TYPE-MESSAGE-ID msgIdGenerator.next

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

  // Send directly, or via the outbox
  sendSwitching_ msg/protocol.Message --now/bool?=false:
    // TODO don't call this on both the outbox and regular paths, as it is messy
    if now:
      // Ensure the message has a known message id
      if not (msg.header.data.has-data protocol.Header.TYPE-MESSAGE-ID):
        msg.header.data.add-data-uint32 protocol.Header.TYPE-MESSAGE-ID msgIdGenerator.next

      // TODO only send sync bytes on UART?
      m := LBSyncBytes_ + msg.bytes

      // Send the message
      device_.out.write m --flush=true
      logger_.with-level log.DEBUG-LEVEL:
        logger_.debug "SNT msg: $(stringify-all-bytes m) $(message-bytes-to-docs-url m)"
    else:
      send-via-outbox msg
      logger_.with-level log.DEBUG-LEVEL:
        logger_.debug "SNT (outbox) msg of type: $(msg.type) $(message-bytes-to-docs-url msg.bytes)"

  // Send a message via the outbox
  send-via-outbox msg/protocol.Message:
    // If the outbox is full, remove the oldest message, and add the new one
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
          // Remove the timeout key, complete the latch, and remove all callbacks?!
          waitTimeouts.remove key
          latchForMessage[key].set false // false currently means timeout?
          latchForMessage.remove key
          lambdasForBadAck.remove key
          lambdasForGoodAck.remove key
          lambdasForBadResponse.remove key
          lambdasForGoodResponse.remove key
        else:
          // not yet timed out
          // logger_.debug "Not yet timed out: $(key) $(durationSinceTimeout) left"
