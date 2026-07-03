import lightbug.devices as devices

main:
  device := devices.I2C
  
  print "💬 Sending a menu to the device"
  device.eink.send-menu --items=["Option1", "Option2", "Option3", "Option4"] --selected-item=1

  i := 5
  items := ["Option1", "Option2", "Option3", "Option4"]
  while true:
    sleep --ms=2000
    print "💬 Updating the menu on the device with $i"
    items[3] = "Option$(i)"
    device.eink.send-menu --items=items 
    i += 1
