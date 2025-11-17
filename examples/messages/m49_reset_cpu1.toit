import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages

// Sends a reset command to CPU1 on the device
// This is the most basic usage of the messaging system
// It will reset the CPU1 and then the device will reboot
// This is useful for testing or recovering from a bad state
main:
  ((devices.I2C).comms.send messages.Reset.msg --withLatch=true).get