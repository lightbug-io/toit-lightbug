import ..messages.messages_gen as messages
import ..protocol as protocol
import .lora-distance show LoraDistance
import .lora-profile show LoraProfile
import log

/**
Best-effort, opt-in upload of the existing ID:latitude,longitude radio format.

One upload may be outstanding; there is no queue, retry, persistent storage or
radio ACK. A task deadline bounds both the P1 write and response wait. Keeping the
wait outside radio dispatch lets the UI and other inbound messages keep running.
*/
class RelayUpload:
  static OFF ::= 0
  static L1 ::= 1
  static L2 ::= 2

  mode_/int := OFF
  generation_/int := 0
  busy_/bool := false
  send_/Lambda
  logger_/log.Logger
  timeout_/Duration

  constructor --send/Lambda --timeout/Duration=(Duration --s=15) --logger/log.Logger=(log.default.with-name "relay-upload"):
    send_ = send
    logger_ = logger
    timeout_ = timeout

  mode -> int:
    return mode_

  label -> string:
    if mode_ == L1: return "L1"
    if mode_ == L2: return "L2"
    return "Off"

  busy -> bool:
    return busy_

  select mode/int:
    if mode != OFF and mode != L1 and mode != L2:
      throw "Invalid relay upload link"
    mode_ = mode
    generation_++
    logger_.info "Cloud upload selected: $label (best effort)"

  cycle:
    select ((mode_ + 1) % 3)

  stop:
    // A frame already handed to P1 cannot be recalled. A scheduled but not yet
    // sent frame is cancelled; no new uploads are accepted until re-enabled.
    select OFF

  receive payload/ByteArray local-id/int? -> bool:
    if mode_ == OFF: return false
    msg := location-message payload local-id mode_
    if msg == null: return false
    if busy_:
      logger_.warn "Cloud upload dropped: busy (one outstanding, no queue)"
      return false
    busy_ = true
    generation := generation_
    task:: upload_ msg generation
    return true

  upload_ msg/protocol.Message generation/int:
    try:
      if generation != generation_:
        logger_.info "Cloud upload cancelled: selection changed before send"
        return
      source := msg.header-get-data-uint protocol.Header.TYPE_FORWARDED_FOR
      logger_.info "Cloud upload attempt: source=$source link=$label"
      e := catch:
        // Comms' timeout only expires its response tracker. Also bound the
        // synchronous write (P1 may report no I2C write capacity indefinitely).
        response/protocol.Message? := with-timeout timeout_: send_.call msg
        if response == null:
          logger_.warn "Cloud upload unconfirmed: source=$source id=$(msg.msgId); no retry"
        else if not response.msg-ok:
          logger_.warn "Cloud upload rejected: source=$source id=$(msg.msgId) status=$(response.msg-status); no retry"
        else:
          // A matching response is not a claim about downstream persistence.
          logger_.info "Cloud upload response OK: source=$source id=$(msg.msgId)"
      if e:
        logger_.warn "Cloud upload failed: source=$source error=$e; no retry"
    finally:
      busy_ = false

  static location-message payload/ByteArray local-id/int? mode/int -> protocol.Message?:
    if mode != L1 and mode != L2: return null
    // Fail closed until local identity is known, so self echoes cannot upload.
    if local-id == null or payload.size == 0 or payload.size > LoraProfile.MAX-PAYLOAD:
      return null
    e := catch:
      // Do not replay arbitrary V3, encrypted, ACK, session or control traffic.
      // Even decoded V3 Position support is deliberately outside this v1.
      text := payload.to-string
      parts := text.split ":"
      if parts.size != 2: return null
      id-text/string := parts[0]
      if id-text.size == 0 or id-text.size > 10: return null
      id-text.do: |char|
        if char < '0' or char > '9': return null
      source := int.parse id-text
      if source < 0 or source > 0xffff_ffff or source == local-id: return null
      coordinate := LoraDistance.parse parts[1]
      if coordinate == null: return null

      // Timestamp means GPS fix time, not relay reception time. The text
      // format conveys no timestamp, type, source, accuracy or altitude, so
      // leave them absent rather than claiming a fix/RTK quality or an epoch.
      data := protocol.Data
      data.add-data-int32 messages.Position.LATITUDE ((coordinate.lat * 1e7).round.to-int)
      data.add-data-int32 messages.Position.LONGITUDE ((coordinate.lon * 1e7).round.to-int)
      msg := protocol.Message.with-data messages.Position.MT data
      msg.header-add-data-uint protocol.Header.TYPE_FORWARDED_FOR source
      destination := mode == L1 ? protocol.Header.LINK_ID_CHASM : protocol.Header.LINK_ID_LINK2
      msg.header-add-data-uint protocol.Header.TYPE_FORWARD_TO destination
      // No ClientID: P1 supplies relay identity and appends its ESP32 hop (1).
      // No MessageID: Comms assigns a fresh relay ID. No S_RAM: a forwarded
      // cloud ACK can bypass P1's stored-message cleanup.
      return msg
    // Untrusted radio input must not take down its reader or UI task.
    if e: return null
    return null
