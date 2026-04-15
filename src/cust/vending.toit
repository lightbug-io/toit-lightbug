import uart
import gpio
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
  static Cmd_Auth := VendingProtocol.Cmd_Auth // Will not be implemented.

  port := null
  _rx-pin := null
  _tx-pin := null
  _rx-pin-num := null
  _tx-pin-num := null
  _baud-rate := null
  _min-response-delay := (Duration --ms=50)
  _last-request-start-us := 0
  temperature-cache_ /float := 20.0
  voltage-cache_ /float := 3.7

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

  constructor --rx-pin/int --tx-pin/int --baud-rate/int=VENDING_BAUD --min-response-delay/Duration=(Duration --ms=50) --logger=log.default:
    logger_ = logger
    _rx-pin-num = rx-pin
    _tx-pin-num = tx-pin
    _rx-pin = gpio.Pin _rx-pin-num --open-drain=true
    _tx-pin = gpio.Pin _tx-pin-num --open-drain=true
    _baud-rate = baud-rate
    _min-response-delay = min-response-delay
    // Init a port..
    set-port-rx

  refresh-pins:
    // Refresh both pins to avoid stale drive state after TX.
    if _rx-pin:
      _rx-pin.close
    if _tx-pin:
      _tx-pin.close
    _rx-pin = gpio.Pin _rx-pin-num --open-drain=true
    _tx-pin = gpio.Pin _tx-pin-num --open-drain=true

  wait-min-response-delay:
    if _min-response-delay.in-us <= 0:
      return
    if _last-request-start-us <= 0:
      return
    elapsed-us := (Time.monotonic-us --since-wakeup) - _last-request-start-us
    remaining-us := _min-response-delay.in-us - elapsed-us
    if remaining-us > 0:
      sleep --ms=((remaining-us + 999) / 1000)
      // blocking-sleep (Duration --us=remaining-us)

  set-port-rx:
    print "Setting port to rx mode"
    if port:
      port.close
    refresh-pins
    port = uart.Port
      --rx=_rx-pin
      --tx=_tx-pin // Partner pin for half-duplex read mode
      --baud_rate=_baud-rate
      --high-priority=true
      --no-large-buffers
  
  set-port-tx:
    print "Setting port to tx mode"
    if port:
      port.close
    refresh-pins
    port = uart.Port
      --rx=_tx-pin // Partner pin while transmitting
      --tx=_rx-pin // Drive response on the kiosk line
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
    wait-min-response-delay
    set-port-tx
    port.out.write "ERROR\r\n".to-byte-array --flush=true
    // Let the final stop bit clear before rearming RX.
    sleep (Duration --ms=2)
    set-port-rx

  send-response frame/ByteArray:
    wait-min-response-delay
    set-port-tx
    // pad the frame with 500 bytes of 1...
    // frame = frame + (ByteArray 500 --initial=1)
    port.out.write frame --flush=true
    // Let the final stop bit clear before rearming RX.
    sleep (Duration --ms=2)
    set-port-rx
    logger_.debug "Sent response frame: $(frame)"
  
  read-frame -> ByteArray?:
    // Wait for a port
    while not port:
        sleep (Duration --ms=1)
    // Wait for header byte.
    while port.in.peek-byte != HEADER:
      port.in.read-byte
    _last-request-start-us = Time.monotonic-us --since-wakeup
    port.in.read-byte // Consume header.

    length := 0
    // exception := catch --unwind=(: it != DEADLINE-EXCEEDED-ERROR):
    //   with-timeout (Duration --ms=100):
    length = port.in.read-byte
    // if exception:
    //   return null

    if length < 4 or length > BUFFER_SIZE:
      return null

    // LENGTH includes [command/data/xor] and trailing CRLF.
    payload := ByteArray length

    // exception = catch --unwind=(: it != DEADLINE-EXCEEDED-ERROR):
    //   with-timeout (Duration --ms=50):
    length.repeat: | i |
      payload[i] = port.in.read-byte
    // if exception:
    //   return null

    if payload[length - 2] != BACKSLASH_R or payload[length - 1] != BACKSLASH_N:
      return null

    frame := ByteArray length + 2
    frame[0] = HEADER
    frame[1] = length
    length.repeat: | i |
      frame[i + 2] = payload[i]
    return frame

  process-loop:
    // // Send Hello to start for debug
    // send-response "Hello\r\n".to-byte-array
    while true:
      frame := read-frame
      if not frame:
        send-error
        continue

      payload := VendingProtocol.command-payload-from-frame frame
      if not payload:
        logger_.error "Invalid vending frame"
        send-error
        continue

      process-command payload
  
  process-command data/ByteArray:
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
      send-response response
      print "Processed command $(data[0])"
      return

    if data[0] < Cmd_SetId or data[0] > Cmd_Auth:
      send-error
      logger_.error "Unhandled command received: $(data[0])"
      return

    logger_.warn "Ignoring unsupported command $(data[0])"
