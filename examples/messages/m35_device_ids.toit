import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages

main:
  resp := ((devices.RtkHandheld2).comms.send messages.DeviceIDs.get-msg --withLatch=true).get
  data := messages.DeviceIDs.from-data resp.data
  print "ID: $(data.id)"
  print "IMEI: $(data.imei)"
  print "ICCID: $(data.iccid)"