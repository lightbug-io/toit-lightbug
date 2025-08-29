import lightbug.devices as devices
import lightbug.modules.wifi as wifi

main:
  // This example performs a synchronous WiFi scan using the WiFi module.
  w := wifi.WiFi

  print "Performing WiFi scan for 5s..."
  scan-results := w.scan --duration=10000

  if scan-results.size > 0:
    print "WiFi scan completed successfully!"
    print "Found $(scan-results.size) access point(s):"
    scan-results.do: |ap|
      print-scan-result ap
  else:
    print "WiFi scan completed - no access points found"

  print "WiFi scan example completed"

print-scan-result ap:
  print "📶 SSID: '$(ap.ssid)'"