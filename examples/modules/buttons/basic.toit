import lightbug.devices as devices
import lightbug.messages as messages

main:
  device := devices.I2C --background=false
    
  device.buttons.subscribe --timeout=null --callback=(:: |button-data/messages.ButtonPress|
    button-name := messages.ButtonPress.button-id-from-int button-data.button-id
    print "Button pressed: $button-name (ID: $button-data.button-id) for $button-data.duration ms"
  )

