import lightbug.devices as devices
import lightbug.services as services
import lightbug.messages.messages_gen as messages

// Sends a reset command to CPU1 on the device
// This is the most basic usage of the messaging system
// It will reset the CPU1 and then the device will reboot
// This is useful for testing or recovering from a bad state
main:
  ((services.Comms --device=devices.RtkHandheld2).send messages.CPU1Reset.do-msg --withLatch=true).get