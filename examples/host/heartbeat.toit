// Host-side heartbeat peer for usb_console_v3.toit. Requires jag with Toit
// v2.0.0-alpha.198 or newer. Run from the examples directory:
//   jag toit run host/heartbeat.toit /dev/ttyACM0
//   jag toit run host/heartbeat.toit COM58

import io
import log
import uart
import lightbug.messages as messages
import lightbug.modules.comms.comms show Comms
import lightbug.modules.comms.console-framing show HexLineReader HexLineWriter
import lightbug.modules.comms.message-handler show MessageHandler
import lightbug.modules.comms.transport show V3Transport
import lightbug.protocol as protocol

main args:
  if args.size != 1:
    print "Usage: toit run host/heartbeat.toit <serial-port>"
    print "Examples: /dev/ttyACM0 or COM58"
    return

  port := uart.Port args[0] --baud-rate=115200
  transport := HostSerialTransport port
  comms := Comms
      --transport=transport
      --open=false
      --background=false
      --handlers=[(V3ConsoleHandler)]
      --logger=(log.default.with-name "usb-v3-peer")

  print "USB-V3 host peer connected to $(args[0])"
  // USB CDC endpoints may need a moment after opening before the device sees
  // host input. Do not treat a single early frame as a transport failure.
  sleep --ms=250
  acknowledged := false
  3.repeat: | attempt |
    if not acknowledged:
      print "Sending heartbeat $(attempt + 1)/3 and waiting for the device ACK..."
      heartbeat := messages.Heartbeat.msg
      ack := comms.send heartbeat --now=true --withLatch=true --timeout=(Duration --s=3)
      response := ack.get
      if response and response.msg-ok:
        acknowledged = true
        print "USB-V3 host heartbeat acknowledged"
      else:
        print "USB-V3 host heartbeat was not acknowledged"
        sleep --ms=250

  print "Requesting ESP DeviceStatus over V3..."
  comms.send messages.DeviceStatus.get-msg --now=true

  // Keep the inbound Comms task alive. It ACKs each identified device
  // heartbeat, while the handler below prints its arrival.
  while true:
    sleep --ms=60_000

class HostSerialTransport implements V3Transport:
  port_ /uart.Port
  reader_ /io.Reader
  writer_ /io.Writer
  connected_ /bool := true

  constructor port/uart.Port:
    port_ = port
    reader_ = HexLineReader port.in
    writer_ = HexLineWriter port.out

  prefix -> bool:
    return false

  connected -> bool:
    return connected_

  connect -> none:
    connected_ = true

  disconnect -> none:
    if not connected_: return
    port_.close
    connected_ = false

  in -> io.Reader:
    return reader_

  out -> io.Writer:
    return writer_

class V3ConsoleHandler implements MessageHandler:
  count_ /int := 0

  handle-message msg/protocol.Message -> bool:
    if msg.type == messages.Heartbeat.MT:
      count_++
      battery := "not provided"
      if msg.data.has-data messages.Heartbeat.BATTERY-PERCENT:
        heartbeat := messages.Heartbeat.from-data msg.data
        battery = "$(heartbeat.battery-percent)%"
      print "USB-V3 device heartbeat #$count_ id=$(msg.msgId) battery=$battery"
      // This is only logging. Leave the message unhandled so Comms ACKs it.
      return false

    if msg.type == messages.DeviceStatus.MT:
      status := messages.DeviceStatus.from-data msg.data
      firmware-version := msg.data.has-data messages.DeviceStatus.FIRMWARE-VERSION ? status.firmware-version.stringify : "not provided"
      print "USB-V3 ESP DeviceStatus response-to=$(msg.response-to) firmware-version=$firmware-version"
      return true

    return false
