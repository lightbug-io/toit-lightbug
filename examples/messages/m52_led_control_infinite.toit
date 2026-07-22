import lightbug.devices as devices
import lightbug.messages as messages

// Sends MT52 LEDControl to P1 without a duration header.
// The P1 LEDs remain blue until another LEDControl message changes them, or something unexpected happens.
main:
  device := devices.I2C --background=false --log-level=devices.ERROR-LEVEL
  data := messages.LEDControl.data --red=0 --green=0 --blue=255
  device.comms.send (messages.LEDControl.set-msg --base-data=data) --now=true
