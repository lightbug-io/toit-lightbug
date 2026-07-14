import lightbug.devices as devices

main:
  duration-ms := 5000
  device := devices.I2C

  print "Performing active BLE streaming scan for $(duration-ms)ms..."

  seen := 0
  emitted := device.ble.scan --stream --duration=duration-ms --active=true --onSeen=(:: | result |
    seen++
    print "[$(seen)] $(result.formatted-address) RSSI=$(result.rssi)dBm"
    if result.device-name and result.device-name.size > 0:
      print "     Name: '$(result.device-name)'"
  )

  print "\nActive BLE scan completed"
  print "Devices streamed: $(emitted)"
