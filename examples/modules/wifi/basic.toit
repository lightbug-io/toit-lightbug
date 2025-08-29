import lightbug.devices as devices
import lightbug.util.bytes as bytes

main:
  // This example is setup to work with the RH2 device.
  device := devices.RtkHandheld2

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

// Use shared MAC formatting helper.

print-scan-result ap:
  // Safely attempt to read SSID, MAC and RSSI from the access-point object.
  ssid := "<unknown>"
  mac := "<unknown>"
  rssi := "<unknown>"

  e := catch:
    // Use the canonical AccessPoint fields from net/wifi.AccessPoint.
    // According to net/wifi.toit, AccessPoint has: ssid/string, bssid/ByteArray, rssi/int
    ssid = ap.ssid
    mac = bytes.format-mac ap.bssid
    rssi = ap.rssi

  print ""
  print "📶 SSID: '$(ssid)'"
  print "   MAC: $(mac)"
  print "   RSSI: $(rssi)"