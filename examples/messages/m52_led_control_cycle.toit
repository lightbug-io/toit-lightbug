import lightbug.devices as devices
import lightbug.messages as messages
import lightbug.protocol as protocol

ON-DURATION-MS ::= 1000
SEND-INTERVAL-MS ::= 2000

// Sends MT52 LEDControl messages to P1 over I2C.
// P1 keeps each colour on for 1s; send the next colour every 2 seconds.
main:
  device := devices.I2C --background=false --log-level=devices.ERROR-LEVEL

  colour := 0
  while true:
    colour++
    if colour == 1:
      set-leds device 255 0 0
    else if colour == 2:
      set-leds device 0 255 0
    else:
      set-leds device 0 0 255
      colour = 0

    sleep --ms=SEND-INTERVAL-MS

set-leds device red/int green/int blue/int:
  data := messages.LEDControl.data --red=red --green=green --blue=blue
  msg := messages.LEDControl.set-msg --base-data=data
  msg.header-add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-DURATION ON-DURATION-MS
  device.comms.send msg --now=true
