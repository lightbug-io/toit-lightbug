// Requires jag with Toit v2.0.0-alpha.198 or newer and a USB-console firmware
// envelope. Receives V3 frames over USB and responds to DeviceStatus GET.
//
// Run the host peer from the examples directory:
//   jag toit run toit/usb_v3_peer.toit /dev/ttyACM0

import lightbug.messages as messages
import lightbug.modules.comms.message-handler show MessageHandler
import lightbug.modules.comms.usb-console show UsbConsole
import lightbug.protocol as protocol
import log

main:
  log.set-default (log.default.with-level log.INFO-LEVEL)

  link := UsbConsole --background=false
  link.comms.register-handler (HeartbeatHandler)
  link.comms.heartbeats.set-period (Duration --s=5)
  link.comms.heartbeats.start

  print "USB-V3-READY"
  print "USB-V3 sends heartbeats every 5 seconds, ACKs identified host messages, and answers DeviceStatus GET"

class HeartbeatHandler implements MessageHandler:
  count_ /int := 0

  handle-message msg/protocol.Message -> bool:
    if msg.type != messages.Heartbeat.MT: return false
    count_++
    battery := "not provided"
    if msg.data.has-data messages.Heartbeat.BATTERY-PERCENT:
      heartbeat := messages.Heartbeat.from-data msg.data
      battery = "$(heartbeat.battery-percent)%"
    print "USB-V3-RX-HEARTBEAT #$count_ id=$(msg.msgId) battery=$battery"
    // Observing a heartbeat does not consume it: Comms should send its normal
    // ACK when the host supplied a message id.
    return false
