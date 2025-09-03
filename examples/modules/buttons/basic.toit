import lightbug.devices as devices
import lightbug.modules.buttons as buttons

main:
  device := devices.I2C
  
  print "Starting basic button press example..."
  
  // Subscribe to button press events with a callback.
  success := device.buttons.subscribe --callback=(:: |button-data|    
    // Map button IDs to human-readable names.
    button-name := ?
    if button-data.button-id == 0:
      button-name = "middle"
    else if button-data.button-id == 1:
      button-name = "left"
    else if button-data.button-id == 2:
      button-name = "right"
    else:
      button-name = "unknown($button-data.button-id)"
    
    print "Button pressed: $button-name (ID: $button-data.button-id)"
  )
  
  if success:
    print "Successfully subscribed to button press events"
    // Keep the program running to receive button events.
    while true:
      sleep --ms=1000
  else:
    print "Failed to subscribe to button press events"
