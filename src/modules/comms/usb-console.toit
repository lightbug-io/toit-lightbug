import io
import log
import ...firmware as firmware
import ...messages as messages
import ...protocol as protocol
import .comms show Comms
import .console-framing show HexLineReader HexLineWriter
import .message-handler show MessageHandler
import .transport show V3Transport

/**
V3 transport over the primary USB console. Requires a USB-console firmware
envelope; the peer is a host computer rather than a Lightbug device.
*/
class UsbConsole implements V3Transport:
  comms_ /Comms? := null
  handlers_ /List/*<MessageHandler>*/
  background_ /bool
  start-inbound_ /bool
  logger_ /log.Logger
  reader_ /io.Reader
  writer_ /io.Writer

  constructor
      --handlers/List?/*<MessageHandler>*/=[]
      --startComms/bool=true
      --startInbound/bool=true
      --background/bool=true
      --logger/log.Logger=(log.default.with-name "usb-console"):
    handlers_ = handlers
    background_ = background
    start-inbound_ = startInbound
    logger_ = logger
    reader_ = HexLineReader io.stdin
    writer_ = HexLineWriter io.stdout
    if startComms: comms

  /** The shared console stream is not prefixed with the legacy I2C "LB" bytes. */
  prefix -> bool:
    return false

  connected -> bool:
    return true

  connect -> none:

  disconnect -> none:

  in -> io.Reader:
    return reader_

  out -> io.Writer:
    return writer_

  comms -> Comms:
    if not comms_:
      // A host console has no Lightbug Open/reinit handshake. Applications can
      // explicitly start V3 heartbeats when that behaviour is desired.
      comms_ = Comms
          --transport=this
          --handlers=handlers_
          --open=false
          --startInbound=start-inbound_
          --background=background_
          --logger=(logger_.with-name "comms")
      // The console peer is a computer, but it is useful for it to query the
      // Toit application's own firmware information using normal V3.
      comms_.register-handler (ConsoleDeviceStatusHandler comms_ logger_)
    return comms_

class ConsoleDeviceStatusHandler implements MessageHandler:
  comms_ /Comms
  logger_ /log.Logger

  constructor comms/Comms logger/log.Logger:
    comms_ = comms
    logger_ = logger

  handle-message msg/protocol.Message -> bool:
    if msg.type != messages.DeviceStatus.MT:
      return false
    // A forwarded request belongs to the bridge, not the P2 console service.
    // In particular, `Forward To = 3` must reach P1 rather than racing a
    // direct DeviceStatus response from P2.
    if msg.header-has-data protocol.Header.TYPE_FORWARD_TO:
      return false
    if not msg.header-has-data protocol.Header.TYPE_MESSAGE_METHOD:
      return false
    method := msg.header-get-data-uint protocol.Header.TYPE_MESSAGE_METHOD
    if method != protocol.Header.METHOD-GET:
      return false

    logger_.info "Handling USB DeviceStatus GET request"
    response := protocol.Message.with-data messages.DeviceStatus.MT (messages.DeviceStatus.data
        --firmware-version=firmware.firmware-version-int)
    if msg.msgId != null:
      response.header-add-data-uint32 protocol.Header.TYPE_RESPONSE_TO_MESSAGE_ID msg.msgId
    comms_.send response --now=true
    return true
