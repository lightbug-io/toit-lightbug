import lightbug.devices as devices
import lightbug.protocol as protocol
import lightbug.messages.messages_gen as messages
import monitor
import .alternate show fill-screen

main:
  device := devices.I2C --background=false --log-level=devices.ERROR-LEVEL
  
  sleep --ms=2000

  // Arm the device, so we get correction data from the GNSS module
  // This section was only tested on an RH2 device, but should work on any armable device
  (device.comms.send (messages.Command.set-msg --base-data=(messages.Command.data --arm-mode=1) ) --now=true
    --preSend=(:: print "Arming device")
    --postSend=(:: print "Device armed")
    --onAck=(:: print "✅ Device arm Acked: $it")
    --onNack=(:: print "❌ Device arm Not Acked: $it")
    --onResponse=(:: print "✅ Device arm response: $it")
    --onError=(:: print "❌ Error arming device: $it")).get

  // Sub to position at 5hz...
  (device.comms.send (messages.Position.subscribe-msg --interval=200 ) --now=true
    --preSend=(:: print "Subscribing to Position")
    --postSend=(:: print "Subscribed to Position")
    --onAck=(:: print "✅ Position subscription Acked: $it")
    --onNack=(:: print "❌ Position subscription Not Acked: $it")
    --onResponse=(:: print "✅ Position: $it")
    --onError=(:: print "❌ Error subscribing to Position: $it")).get

  // Create a message inbox to receive messages from the device
  inbox := device.comms.inbox "in"
  task:: while true:
    msgIn := inbox.receive
    if msgIn.type == messages.Heartbeat.MT:
      print "❤️ Heartbeat received"
    if msgIn.type == messages.Position.MT:
      data := messages.Position.from-data msgIn.data
      print "📍 Position: Sats: $data.satellites CN0: $data.cn0 Accuracy: $data.accuracy"

  // Alternate the screen between black and clear every 4 seconds
  task:: while true:
    fill-screen device true
    sleep --ms=4000

    fill-screen device false
    sleep --ms=4000 // left at 1:10
  
  // Send a message to the device every 25ms
  task:: while true:
    sleep --ms=1200

    msg := protocol.Message.with-data 8765 (protocol.Data)
    msg.data.add-data-string 99 "hello"
    msg.data.add-data-string 98 "from"
    msg.data.add-data-string 97 "alternate-plus.toit!"
    msg.header.data.add-data-uint32 protocol.Header.TYPE-MESSAGE-ID device.comms.msgIdGenerator.next

    print "send other: $(msg.msgId)"
    device.comms.send-new msg --timeout=(Duration --s=2) --onTimeout=(:: |id|
      print "Timeout sending spam msg: $id"
    )
  
  // And forward a message to the cloud link every 100ms
  task:: while true:
    sleep --ms=100

    msg := protocol.Message.with-data 8766 (protocol.Data)
    msg.data.add-data-string 99 "hello"
    msg.data.add-data-string 98 "from"
    msg.data.add-data-string 97 "alternate-plus.toit!"
    msg.header.data.add-data-uint32 protocol.Header.TYPE-MESSAGE-ID device.comms.msgIdGenerator.next
    msg.header.data.add-data-uint8 protocol.Header.TYPE-FORWARD-TO 0 // chasm

    print "send cloud: $(msg.msgId)"
    device.comms.send-new msg --timeout=(Duration --s=2) --onTimeout=(:: |id|
      print "Timeout sending fwd msg: $id"
    )
  
  while true:
    sleep --ms=10000