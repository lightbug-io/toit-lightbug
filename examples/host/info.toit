// Host-side P1 information query over the PR3 USB -> P2 -> I2C V3 route. Requires jag
// with Toit v2.0.0-alpha.198 or newer and the USB V3 base application.
//
// Run from examples:
//   jag toit run host/info.toit /dev/ttyACM0
//   jag toit run host/info.toit COM58

import io
import lightbug.messages as messages
import lightbug.modules.comms.comms show Comms
import lightbug.modules.comms.console-framing show HexLineReader HexLineWriter
import lightbug.modules.comms.transport show V3Transport
import lightbug.protocol as protocol
import uart

main args:
  if args.size < 1 or args.size > 2:
    print "Usage: toit run host/info.toit <serial-port> [--trace]"
    return

  port := uart.Port args[0] --baud-rate=115200
  trace := args.size == 2 and args[1] == "--trace"
  comms := Comms
      --transport=(HostSerialTransport port --trace=trace)
      --open=false
      --background=false

  // Audible proof of the full host -> USB -> P2 -> P1 command direction.
  // It is deliberately forwarded (unlike the bridge's own startup beep).
  beep := messages.BuzzerControl.set-msg --base-data=(messages.BuzzerControl.data --duration=100 --frequency=5.0)
  beep.header-add-data-uint8 protocol.Header.TYPE_FORWARD_TO protocol.Header.LINK_ID_P1
  print "Sending forwarded 100 ms P1 beep (Forward To=3)..."
  beep-reply := (comms.send beep
      --now=true
      --withLatch=true
      --timeout=(Duration --s=3)
      --preSend=(:: | msg | trace-usb-tx "P1 beep via Forward To=3" msg)).get
  if beep-reply:
    print "P1 forwarded beep was acknowledged: type=$(beep-reply.type) status=$(beep-reply.msg-status)"
  else:
    print "P1 forwarded beep was not acknowledged; listen for the beep to distinguish command delivery from return routing"

  print "Requesting P2 DeviceStatus directly over USB..."
  p2-reply := (comms.send messages.DeviceStatus.get-msg
      --now=true
      --withLatch=true
      --timeout=(Duration --s=10)
      --preSend=(:: | msg | trace-usb-tx "P2 direct" msg)).get
  print-device-status "P2" p2-reply

  // The P2 bridge consumes this header and puts Forwarded For = 7 on the
  // I2C frame. P1's reply returns through P2 to this host process.
  request := messages.DeviceStatus.get-msg
  request.header-add-data-uint8 protocol.Header.TYPE_FORWARD_TO protocol.Header.LINK_ID_P1
  print "Requesting P1 DeviceStatus through USB (Forward To=3)..."
  reply := (comms.send request
      --now=true
      --withLatch=true
      --timeout=(Duration --s=10)
      --preSend=(:: | msg | trace-usb-tx "P1 via Forward To=3" msg)).get
  print-device-status "P1" reply

  // Same GET pattern as examples/messages/m35_device_ids.toit, now routed
  // through P2 to P1. This gives us a second, independent P1 response path.
  ids-request := messages.DeviceIDs.get-msg
  ids-request.header-add-data-uint8 protocol.Header.TYPE_FORWARD_TO protocol.Header.LINK_ID_P1
  print "Requesting P1 DeviceIDs through USB (Forward To=3)..."
  ids-reply := (comms.send ids-request
      --now=true
      --withLatch=true
      --timeout=(Duration --s=10)
      --preSend=(:: | msg | trace-usb-tx "P1 DeviceIDs via Forward To=3" msg)).get
  print-device-ids ids-reply

trace-usb-tx label/string msg/protocol.Message:
  // `preSend` runs after Comms allocated the V3 message id, so this is the
  // exact encoded frame subsequently written to the USB serial port.
  print "USB-V3 TX $label: $(msg.bytes)"

print-device-status label/string reply/protocol.Message? -> none:
  if reply == null:
    print "No response from $label within 10 seconds"
    return

  if reply.type == messages.DeviceStatus.MT:
    status := messages.DeviceStatus.from-data reply.data
    firmware-version := reply.data.has-data messages.DeviceStatus.FIRMWARE-VERSION ? status.firmware-version.stringify : "not provided"
    print "$label DeviceStatus received: firmware-version=$firmware-version forwarded-for=$(reply.forwarded-for)"
  else:
    print "$label replied with V3 type=$(reply.type) status=$(reply.msg-status)"

print-device-ids reply/protocol.Message? -> none:
  if reply == null:
    print "No DeviceIDs response from P1 within 10 seconds"
    return
  if reply.type != messages.DeviceIDs.MT:
    print "P1 DeviceIDs request replied with V3 type=$(reply.type) status=$(reply.msg-status)"
    return
  ids := messages.DeviceIDs.from-data reply.data
  print "P1 DeviceIDs received: id=$(ids.id) imei=$(ids.imei) iccid=$(ids.iccid) forwarded-for=$(reply.forwarded-for)"

class HostSerialTransport implements V3Transport:
  port_ /uart.Port
  reader_ /io.Reader
  writer_ /io.Writer

  constructor port/uart.Port --trace/bool=false:
    port_ = port
    raw-reader := trace ? (UsbTraceReader port.in) : port.in
    reader_ = HexLineReader raw-reader
    writer_ = HexLineWriter port.out

  prefix -> bool: return false
  connected -> bool: return true
  connect -> none:
  disconnect -> none: port_.close
  in -> io.Reader: return reader_
  out -> io.Writer: return writer_

// Keep console/log bytes visible while Comms consumes only valid V3 frames.
// This is diagnostic-only: it does not modify or consume the serial data.
class UsbTraceReader extends io.Reader with io.InMixin:
  source_ /io.Reader

  constructor source/io.Reader:
    source_ = source

  read_ -> ByteArray?:
    bytes := source_.read
    if bytes != null and bytes.size > 0:
      print "USB-V3 RAW RX: $bytes"
    return bytes
