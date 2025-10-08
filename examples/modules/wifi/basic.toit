import lightbug.devices as devices
import lightbug.util.bytes as bytes

main:
  // This example is setup to work with the RH2 device.
  device := devices.I2C

  print "Performing WiFi scan for 10s..."
  scan-results := device.wifi.scan --duration=10000

  if scan-results.size > 0:
    print "WiFi scan completed successfully!"
    print "Found $(scan-results.size) access point(s):"
    scan-results.do: | ap |
      print-scan-result ap
  else:
    print "WiFi scan completed - no access points found"

  print "WiFi scan example completed"

print-scan-result ap:
  ssid := "<unknown>"
  mac := "<unknown>"
  rssi := "<unknown>"

  e := catch:
    ssid = ap.ssid
    mac = bytes.format-mac ap.bssid
    rssi = ap.rssi

  print ""
  print "📶 SSID: '$(ssid)'"
  print "   MAC: $(mac)"
  print "   RSSI: $(rssi)"