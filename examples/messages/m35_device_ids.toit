import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages

main:
  resp := ((devices.I2C).comms.send messages.DeviceIDs.get-msg --withLatch=true).get
  data := messages.DeviceIDs.from-data resp.data
  print "ID: $(data.id)"
  // Only available on some device types for now, so serial may be empty.
  // print "Serial: $(data.serial)"
  print "IMEI: $(data.imei)"
  print "ICCID: $(data.iccid)"