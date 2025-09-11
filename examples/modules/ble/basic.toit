import lightbug.devices as devices
import lightbug.modules.ble as ble

main:
  device := devices.I2C

  print "Performing BLE scan for 3s..."
  scan-results := device.ble.scan --duration=3000
  
  if scan-results.size > 0:
    print "BLE scan completed successfully!"
    print "Found $(scan-results.size) device(s):"
    
    scan-results.do: | result |
      print-scan-result result
  else:
    print "BLE scan completed - no devices found"
    
  print "BLE scan example completed"

print-scan-result result:
  print ""
  print "📱 Device: $(result.formatted-address)"
  if result.device-name and result.device-name.size > 0:
    print "   Name: '$(result.device-name)'"
  else:
    print "   Name: <unnamed>"
  print "   RSSI: $(result.rssi) dBm"
  print "   Connectable: $(result.connectable)"
  
  // Check for iBeacon info
  ibeacon := result.ibeacon-info
  if ibeacon:
    print "   📍 iBeacon detected!"
    print "     Major: $(ibeacon["major"]), Minor: $(ibeacon["minor"])"
    print "     TX Power: $(ibeacon["tx-power"])"
  
  // Show raw advertisement bytes if present
  advertising := result.raw
  if advertising and advertising.size > 0:
    print "   Advertising: $advertising"
