import ..protocol as protocol
import ..devices as devices
import ..messages as messages
import ..devices as devices
import ..messages as messages
import ..util.docs show messageBytesToDocsURL
import ..util.resilience show catchAndRestart
import ..util.idgen show IdGenerator RandomIdGenerator SequentialIdGenerator
import ..util.bytes show stringifyAllBytes byteArrayToList
import io.reader show Reader
import io.writer show Writer
import encoding.url
import log
import io
import monitor
import monitor show Channel

class Comms:
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
      --idGenerator/IdGenerator? = null:

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
    
    start_

  start_:
    log.info "Comms starting"
    task:: catchAndRestart "processInbound_" (:: processInbound_)
    task:: catchAndRestart "processOutbox_" (:: processOutbox_)
    task:: catchAndRestart "processAwaitTimeouts_" (:: processAwaitTimeouts)
    log.info "Comms started"

  // Creates or gets an inbox by name
  // A single inbox will only deliver messages once
  inbox name/string --size/int? = 15 -> Channel:
    if not inboxesByName.contains name:
      log.info "Created new inbox " + name
      inboxesByName[name] = Channel size
    else if inboxesByName[name].capacity != size:
      log.warn "Tried to get already created inbox, now with different size"
    return inboxesByName[name]

  processInbound_:
    // Keep going until we find a message
    while true:
      yield

      while not device_.in.try-ensure-buffered 1:
        log.debug "Inbound reader waiting for 1 byte"
        yield
      
      // Look for the next byte that is 3, which could indicate our protocol version
      if device_.in.peek-byte != 3:
        // if we don't find a 3, we can skip this byte
        device_.in.read-byte
        continue

      // Wait for a total of 3 bytes, which would also give us the length
      while not device_.in.try-ensure-buffered 3:
        log.debug "Inbound reader waiting for 3 bytes"
        yield
      // Peek all 3 bytes, which is protocol + message length
      b3 := device_.in.peek-bytes 3

      // last to bytes of b3 are the uint16 LE message length
      messageLength := (b3[2] << 8) + b3[1]
      // If the msgLength looks too long (over 1000, just advance, as its probably garbage)
      if messageLength > 1000:
          log.error "Message length probably too long, skipping: " + messageLength.stringify
          device_.in.read-byte
          continue

      // Try and make sure that we have enough bytes buffered to read the full potential message
      while not device_.in.try-ensure-buffered messageLength:
        log.debug "Inbound reader waiting for message length: " + messageLength.stringify
        yield

      messageBytes := device_.in.peek-bytes messageLength
      // TODO remove once we are sure its good?
      if messageBytes.size != messageLength: // Fail safe, but shouldn't happen due to the try-enure-buffered above
        log.error "Message length mismatch, no more bytes availible? skipping message"
        device_.in.read-byte
        throw "Message length mismatch, no more bytes availible? skipping message"
        continue

      e := catch --trace:
        // Extract the expected checksum from the last 2 bytes of the message (LE)
        expectedChecksumBytes := [messageBytes[messageLength - 2], messageBytes[messageLength - 1]]

        // And parse it as a protocol.Message
        v3 := protocol.Message.fromList ( byteArrayToList messageBytes )

        // Calculate the checksum of the message data
        calculatedChecksum := v3.checksumCalc
        // calculatedChecksumBytes is LE uint16 of calculatedChecksum
        calculatedChecksumBytes := [calculatedChecksum & 0xFF, calculatedChecksum >> 8]

        // if they match, we have a message, return it
        if expectedChecksumBytes == calculatedChecksumBytes:
            // read the bytes we peeked
            device_.in.read-bytes messageLength
            processReceivedMessage_ v3
        else:
          log.error "Checksum mismatch, skipping message"

          // Read a byte, and continue looking for a message
          device_.in.read-byte
      if e:
        // output a row of red cross emojis
        log.error " ❌ " * 20
        log.error "Error parsing message (probably garbeled): " + e.stringify + " " + ( stringifyAllBytes messageBytes)
        log.error " ❌ " * 20
        // Read a byte, and continue looking for a message
        device_.in.read-byte

  processReceivedMessage_ msg/protocol.Message:
    log.debug "RCV msg type " + msg.type.stringify + " : " + msg.stringify + " " + ( messageBytesToDocsURL msg.bytes )

    // Add to any registered inboxes
    inboxesByName.do --values=true: | inbox |
      if inbox.size >= inbox.capacity:
        dropped := inbox.receive
        log.warn "Inbox full, Dropped message of type: " + dropped.type.stringify + " in favour of new message of type: " + msg.type.stringify
      inbox.send msg
      yield // on each inbox population

    // Process awaiting lambdas
    // TODO possibly have a timeout for the age of waiting for a response?
    // That could be its own lambda to act on, but also remove the lambdas from the list
    if msg.header.data.hasData protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID:
      respondingTo := msg.header.data.getDataUintn protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID
      isAck := msg.header.messageType == messages.MSGTYPE_GENERAL_ACK // Otherwise it is a response
      isBad := msg.header.data.hasData protocol.Header.TYPE-MESSAGE-STATUS and msg.msgStatus > 0
      if isAck:
        if isBad:
          if lambdasForBadAck.contains respondingTo:
            lambda := lambdasForBadAck[respondingTo]
            log.debug "Calling lambda for bad ack: " + respondingTo.stringify
            task:: lambda.call msg
        else:
          if lambdasForGoodAck.contains respondingTo:
            lambda := lambdasForGoodAck[respondingTo]
            log.debug "Calling lambda for good ack: " + respondingTo.stringify
            task:: lambda.call msg
        lambdasForBadAck.remove respondingTo
        lambdasForGoodAck.remove respondingTo
      else:
        if isBad:
          if lambdasForBadResponse.contains respondingTo:
            lambda := lambdasForBadResponse[respondingTo]
            log.debug "Calling lambda for bad response: " + respondingTo.stringify
            task:: lambda.call msg
        else:
          if lambdasForGoodResponse.contains respondingTo:
            lambda := lambdasForGoodResponse[respondingTo]
            log.debug "Calling lambda for good response: " + respondingTo.stringify
            task:: lambda.call msg
        lambdasForBadResponse.remove respondingTo
        lambdasForGoodResponse.remove respondingTo
      // If there are no waiting lambdas for the msg id, then latchForMessage can be released
      if (lambdasForBadAck.contains respondingTo) == false and (lambdasForGoodAck.contains respondingTo) == false and (lambdasForBadResponse.contains respondingTo) == false and (lambdasForGoodResponse.contains respondingTo) == false:
        // Remove remaining timeouts, and release the latch
        if waitTimeouts.contains respondingTo:
          waitTimeouts.remove respondingTo
        if latchForMessage.contains respondingTo:
          latchForMessage[respondingTo].set (not isBad) // TODO consider returning something better here? like the message?
          latchForMessage.remove respondingTo

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
      --timeout/Duration = (Duration --s=60) -> monitor.Latch:
    log.debug "Sending (and) message: " + msg.stringify + " " + ( messageBytesToDocsURL msg.bytes )
  
    // Ensure the message has a known message id
    if not (msg.header.data.hasData protocol.Header.TYPE-MESSAGE-ID):
      msg.header.data.addDataUint32 protocol.Header.TYPE-MESSAGE-ID msgIdGenerator.next

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

    if shouldTrack:
      latchForMessage[msg.msgId] = latch
      waitTimeouts[msg.msgId] = Time.now + timeout
    
    if preSend != null:
      preSend.call msg

    sendSwitching_ msg --now=now

    if postSend != null:
      postSend.call msg

    return latch

  // Send directly, or via the outbox
  sendSwitching_ msg/protocol.Message --now/bool?=false:
    // TODO don't call this on both the outbox and regular paths, as it is messy
    if now:
      // Ensure the message has a known message id
      if not (msg.header.data.hasData protocol.Header.TYPE-MESSAGE-ID):
        msg.header.data.addDataUint32 protocol.Header.TYPE-MESSAGE-ID msgIdGenerator.next

      // TODO only send sync bytes on UART?
      m := LBSyncBytes_ + msg.bytes

      // Send the message
      device_.out.write m --flush=true
      log.debug "SNT msg: " + (stringifyAllBytes m) + " " + ( messageBytesToDocsURL m )
    else:
      sendViaOutbox msg
      log.debug "SNT (outbox) msg of type: " + msg.type.stringify + " " + ( messageBytesToDocsURL msg.bytes )

  // Send a message via the outbox
  sendViaOutbox msg/protocol.Message:
    // If the outbox is full, remove the oldest message, and add the new one
    if outbox_.size == outbox_.capacity:
      // TODO should cleanup the lambdas for the removed message, or wait for them to timeout?
      droppedMsg := outbox_.receive
      log.warn "Outbox full, Dropped message of type: " + droppedMsg.type.stringify + " in favour of new message of type: " + msg.type.stringify
    // We don't log the send here, as it will be sent later when the outbox is processed
    outbox_.send msg

  // Send raw bytes, without any protocol wrapping
  sendRawBytes bytes/ByteArray:
    device_.out.write bytes --flush=true
    log.debug "SNT raw: " + (stringifyAllBytes bytes) + " " + ( messageBytesToDocsURL bytes )

  processAwaitTimeouts:
    while true:
      yield
      sleep TimeoutCheckEvery_
      waitTimeouts.do --keys=true: | key |
        durationSinceTimeout := (waitTimeouts[key].to Time.now)
        if (durationSinceTimeout > (Duration --s=0)):
          log.debug "Timeout for message: " + key.stringify + " expired " + durationSinceTimeout.stringify + " ago"
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
          // log.debug "Not yet timed out: " + key.stringify + " " + durationSinceTimeout.stringify + " left"
