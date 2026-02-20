import lightbug.devices as devices
import lightbug.messages.messages_gen as messages

main:
  req := messages.SIMsettings.data --active-sim=messages.SIMsettings.ACTIVE-SIM_SIM1
  resp := ((devices.I2C).comms.send ( messages.SIMsettings.set-msg --base-data=req ) --withLatch=true).get
  print "Resp: $(resp)"