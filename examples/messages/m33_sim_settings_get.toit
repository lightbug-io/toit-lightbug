import lightbug.devices as devices
import lightbug.messages.messages_gen as messages

main:
  resp := ((devices.I2C).comms.send ( messages.SIMsettings.get-msg ) --withLatch=true).get
  data := messages.SIMsettings.from-data resp.data
  print "Resp: $(resp)"
  print "$(data)"