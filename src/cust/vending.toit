import uart
import log
import .vending_protocol show VendingProtocol

class Vending:

  // Frame structure:
  // [HEADER, LENGTH, PAYLOAD..., CR, LF].
  // Payload is [COMMAND, DATA..., CHECKSUM].
  // Header/length/payload checksum XOR must evaluate to zero.

  static HEADER := VendingProtocol.HEADER
  static BUFFER_SIZE := VendingProtocol.BUFFER_SIZE

  static BACKSLASH_R := VendingProtocol.BACKSLASH_R
  static BACKSLASH_N := VendingProtocol.BACKSLASH_N

  static VENDING_BAUD := 9600

  // State
  static Stat_Unknown := 0
  static Stat_ReadingLength := 1
  static Stat_ReadingMessage := 2

  // Commands (FROM VENDING)
  static Cmd_SetId := VendingProtocol.Cmd_SetId // Will not be implemented.
  static Cmd_Auth := VendingProtocol.Cmd_Auth

  port := null
  _rx-pin-num := null
  _tx-pin-num := null
  _baud-rate := null
  _min-response-delay := (Duration --ms=50)
  _response-count /int := 1
  _last-request-start-us := 0
  // Development timing temporarily disabled.
  // uart-ready-us /int := 0
  // first-request-us /int? := null
  // first-response-us /int? := null
  // first-rx-restored-us /int? := null
  last-activity-us /int := 0
  busy /bool := false
  // request-count /int := 0
  // last-command /int? := null
  // last-tx-flushed-us /int? := null
  // last-rx-restored-us /int? := null
  temperature-cache_ /float := 20.0
  voltage-cache_ /float := 3.7
  authed /bool := false

  // 0x2b is serial
  // 	if(settings->serialNum){
  // 	vendingId = 0x2B00000000;
  // 	uint32_t serialRange = settings->serialNum / 1e6;
  // 	uint32_t deviceIdentifier = settings->serialNum - (serialRange * 1e6);
  // 	memcpy(&vendingId, &deviceIdentifier, 4);
  // } else {
  // 	vendingId = 0x1B00000000;
  // 	uint32_t id = settings->getCurrentId();
  // 	memcpy(&vendingId, &id, 4);
  // }
  static VENDING_ID_DEFAULT := 0x1B00000000
  vending-id := VENDING_ID_DEFAULT

  logger_/log.Logger

  constructor --rx-pin/int --tx-pin/int --baud-rate/int=VENDING_BAUD --min-response-delay/Duration=(Duration --ms=50) --response-count/int=1 --vending-id/int=VENDING_ID_DEFAULT --logger=log.default:
    if response-count < 1:
      throw "response-count must be at least 1"
    logger_ = logger
    _rx-pin-num = rx-pin
    _tx-pin-num = tx-pin
    _baud-rate = baud-rate
    _min-response-delay = min-response-delay
    _response-count = response-count
    this.vending-id = vending-id
    // Init a port..
    set-port-rx
    // uart-ready-us = Time.monotonic-us --since-wakeup
    last-activity-us = Time.monotonic-us --since-wakeup

  wait-min-response-delay --since-us/int?=null:
    if _min-response-delay.in-us <= 0:
      return
    start-us := since-us == null ? _last-request-start-us : since-us
    if start-us <= 0:
      return
    elapsed-us := (Time.monotonic-us --since-wakeup) - start-us
    remaining-us := _min-response-delay.in-us - elapsed-us
    if remaining-us > 0:
      sleep --ms=((remaining-us + 999) / 1000)
      // blocking-sleep (Duration --us=remaining-us)

  set-port-rx:
    if port:
      port.close
    port = uart.Port
      --rx=_rx-pin-num
      --tx=_tx-pin-num // Partner pin for half-duplex read mode
      --baud_rate=_baud-rate
      --high-priority=true
      --no-large-buffers
  
  set-port-tx:
    if port:
      port.close
    port = uart.Port
      --rx=_tx-pin-num // Partner pin while transmitting
      --tx=_rx-pin-num // Drive response on the kiosk line
      --baud_rate=_baud-rate
      --high-priority=true
      --no-large-buffers

  set-port --port_/uart.Port:
    port = port_

  update-vending-id-from-current-id current-id/int -> int:
    vending-id = VendingProtocol.vending-id-from-current-id current-id
    return vending-id

  update-vending-id-from-serial serial-num/int -> int:
    vending-id = VendingProtocol.vending-id-from-serial serial-num
    return vending-id

  update-cache --temperature/float?=null --voltage/float?=null:
    if temperature != null:
      temperature-cache_ = temperature
    if voltage != null:
      voltage-cache_ = voltage
  
  get-temperature -> int:
    return temperature-cache_.to-int
  
  get-voltage -> float:
    return voltage-cache_
  
  send-error:
    send-response "ERROR\r\n".to-byte-array

  send-response frame/ByteArray:
    previous-start-us := _last-request-start-us
    _response-count.repeat:
      wait-min-response-delay --since-us=previous-start-us
      set-port-tx
      previous-start-us = Time.monotonic-us --since-wakeup
      // if first-response-us == null: first-response-us = previous-start-us
      port.out.write frame --flush=true
      // last-tx-flushed-us = Time.monotonic-us --since-wakeup
      // Let the final stop bit clear before rearming RX.
      // sleep (Duration --ms=2)
      set-port-rx
      // last-rx-restored-us = Time.monotonic-us --since-wakeup
      last-activity-us = Time.monotonic-us --since-wakeup
      // if first-rx-restored-us == null: first-rx-restored-us = last-rx-restored-us
  
  read-frame -> ByteArray?:
    // Wait for a port
    while not port:
        sleep (Duration --ms=1)
    // Wait for header byte.
    while port.in.peek-byte != HEADER:
      port.in.read-byte
    _last-request-start-us = Time.monotonic-us --since-wakeup
    // if first-request-us == null: first-request-us = _last-request-start-us
    last-activity-us = _last-request-start-us
    busy = true
    port.in.read-byte // Consume header.

    frame := null
    error := catch:
      // 100 bytes at 9600 baud take ~104 ms. Bound a truncated request
      // without timing out the idle wait for the next header.
      with-timeout --ms=250:
        frame = read-frame-body_
    if error == DEADLINE-EXCEEDED-ERROR: return null
    if error: throw error
    return frame

  read-frame-body_ -> ByteArray?:
    length := port.in.read-byte
    if length < 4 or length > BUFFER_SIZE: return null
    payload := ByteArray length
    length.repeat: | i | payload[i] = port.in.read-byte
    if payload[length - 2] != BACKSLASH_R or payload[length - 1] != BACKSLASH_N:
      return null
    frame := ByteArray length + 2
    frame[0] = HEADER
    frame[1] = length
    length.repeat: | i | frame[i + 2] = payload[i]
    return frame

  process-loop:
    while true:
      try:
        frame := read-frame
        // Resynchronise silently; an ERROR here could overlap a new frame.
        if not frame: continue
        payload := VendingProtocol.command-payload-from-frame frame
        if not payload: continue
        process-command payload
      finally:
        busy = false
        last-activity-us = Time.monotonic-us --since-wakeup

  process-command data/ByteArray:
    // request-count++
    // if data.size > 0: last-command = data[0]
    // logger_.debug "Received command frame: $(data)"
    if data.size < 2: // Minimum length is command and checksum.
      logger_.error "invalid cmd message received"
      send-error
      return

    if not VendingProtocol.is-valid-command-payload data:
      logger_.error "XOR failed"
      send-error
      return

    response := VendingProtocol.response-for-command-payload data vending-id get-temperature get-voltage
    if response:
      if data[0] == Cmd_Auth and response[3] == VendingProtocol.Stat_Success:
        authed = response[4] == 0x01
      send-response response
      return

    if data[0] < Cmd_SetId or data[0] > Cmd_Auth:
      send-error
      logger_.error "Unhandled command received: $(data[0])"
      return

    logger_.warn "Ignoring unsupported command $(data[0])"
