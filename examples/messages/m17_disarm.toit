import lightbug.devices as devices
import lightbug.messages.messages_gen as messages
import monitor

main:
  device := devices.I2C --background=false --log-level=devices.ERROR-LEVEL
  
  (device.comms.send (messages.Command.set-msg --base-data=(messages.Command.data --arm-mode=0) ) --now=true
    --preSend=(:: print "Disarming device")
    --postSend=(:: print "Device disarmed")
    --onAck=(:: print "✅ Device disarm Acked: $it")
    --onNack=(:: print "❌ Device disarm Not Acked: $it")
    --onResponse=(:: print "✅ Device disarm response: $it")
    --onError=(:: print "❌ Error arming device: $it")).get