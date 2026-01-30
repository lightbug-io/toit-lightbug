import lightbug.devices as devices
import lightbug.protocol as protocol
import lightbug.messages.messages_gen as messages
import monitor
import .alternate show fill-screen

main:
  device := devices.I2C --background=false// --log-level=devices.DEBUG-LEVEL
  
  sleep --ms=2000

  // Sub to position...
  (device.comms.send (messages.Position.subscribe-msg --interval=200 ) --now=true
    --preSend=(:: print "Subscribing to Position")
    --postSend=(:: print "Subscribed to Position")
    --onAck=(:: print "✅ Position subscription Acked: $it")
    --onNack=(:: print "❌ Position subscription Not Acked: $it")
    --onResponse=(:: print "✅ Position: $it")
    --onError=(:: print "❌ Error subscribing to Position: $it")).get

  inbox := device.comms.inbox "in"
  task:: while true:
    msgIn := inbox.receive
    if msgIn.type == messages.Heartbeat.MT:
      print "❤️ Heartbeat received"
    if msgIn.type == messages.Position.MT:
      data := messages.Position.from-data msgIn.data
      print "📍 Position: Sats: $data.satellites CN0: $data.cn0 Accuracy: $data.accuracy"

  task:: while true:
    fill-screen device true
    sleep --ms=4000

    fill-screen device false
    sleep --ms=4000 // left at 1:10
  
  while true:
    sleep --ms=25

    msg := protocol.Message.with-data 8765 (protocol.Data)
    msg.data.add-data-string 99 "hello"
    msg.data.add-data-string 98 "from"
    msg.data.add-data-string 97 "alternate.toit!"
    msg.header.data.add-data-uint32 protocol.Header.TYPE-MESSAGE-ID device.comms.msgIdGenerator.next

    print "send other: $(msg.msgId)"
    device.comms.send-new msg --timeout=(Duration --s=3) --onTimeout=(:: |id|
      print "Timeout sending message id: $id"
    )