import lightbug.devices as devices
import lightbug.messages.messages_gen as messages
import monitor

main:
  device := devices.I2C --background=false --log-level=devices.ERROR-LEVEL
  
  (device.comms.send (messages.Command.set-msg --base-data=(messages.Command.data --arm-mode=1) ) --now=true
    --preSend=(:: print "Arming device")
    --postSend=(:: print "Device armed")
    --onAck=(:: print "✅ Device arm Acked: $it")
    --onNack=(:: print "❌ Device arm Not Acked: $it")
    --onResponse=(:: print "✅ Device arm response: $it")
    --onError=(:: print "❌ Error arming device: $it")).get