import lightbug.devices as devices
import lightbug.modules.ble as ble

main:
  device := devices.I2C
  
  print "Starting continuous BLE scan - showing only new devices..."
  print "Press Ctrl+C to stop\n"
  
  // Keep track of devices we've already seen
  seen-devices := {}
  scan-count := 0
  
  // Scan continuously
  while true:
    scan-count++
    print "=== Scan #$scan-count ==="
    
    // Perform async scan
    scan-completed := false
    new-devices := []
    
    device.ble.scan --async --duration=3000  // 3 second scans
        --onComplete=(:: | results |
          results.do: | result |
            address := result.formatted-address
            if not seen-devices.contains address:
              seen-devices.add address
              new-devices.add result
          scan-completed = true
        )
        --onError=(:: | error |
          print "Scan failed: $error"
          scan-completed = true
        )
    
    yield // yield so the scan actually starts
    // Wait for scan to complete
    while not scan-completed:
      print "waiting for scan to complete..."
      sleep --ms=500
    
    // Show any new devices found
    if new-devices.size > 0:
      print "Found $(new-devices.size) new device(s):"
      new-devices.do: | result |
        print-scan-result result
    else:
      print "No new devices found"
    
    print "Total unique devices seen: $(seen-devices.size)\n"

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
  
  // Show manufacturer data if present
  manufacturer-data := result.manufacturer-data
  if manufacturer-data and manufacturer-data.size > 0:
    print "   Manufacturer: $manufacturer-data"
  
  // Show services if present  
  services := result.service-classes
  if services and services.size > 0:
    print "   Services ($(services.size)): $services"
