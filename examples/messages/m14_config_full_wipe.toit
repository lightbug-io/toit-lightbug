import lightbug.devices as devices
import lightbug.messages.messages_gen as messages

// This is the factory-style reset. It wipes all P1 configuration, including the
// stored device identity, and then reboots P1.
//
// The device should then reconnect and re provision itself.
main:
  data := messages.Config.data --command=messages.Config.COMMAND_FULL-WIPE
  message := messages.Config.msg --data=data
  response := ((devices.I2C).comms.send message --withLatch=true).get
  print "Full-wipe request acknowledged: status=$(response.msg-status)"
