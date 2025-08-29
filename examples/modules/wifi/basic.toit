import lightbug.devices as devices

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

format-mac mac -> string:
  // Accept a ByteArray or string and format as a human-readable MAC address.
  if not mac:
    return "<unknown>"
  if mac is ByteArray:
    start := mac.size > 6 ? 1 : 0
    result := ""
    for i := start; i < mac.size and i < start + 6; i++:
      if i > start:
        result += ":"
      result += "$(%02x mac[i])"
    return result
  if mac is string:
    return mac
  return "<unknown>"

print-scan-result ap:
  // Safely attempt to read SSID, MAC and RSSI from the access-point object.
  ssid := "<unknown>"
  mac := "<unknown>"
  rssi := "<unknown>"

  e := catch:
    // Try common field names. Use catch to avoid runtime errors if a field is missing.
    if ap.ssid:
      ssid = ap.ssid
    if ap.bssid:
      mac = format-mac ap.bssid
    else:
      if ap.mac:
        mac = format-mac ap.mac
      else:
        if ap.address:
          mac = format-mac ap.address

    if ap.rssi:
      rssi = ap.rssi
    else:
      if ap.signal:
        rssi = ap.signal

  if e:
    print "  (failed to read AP fields: $e)"

  print ""
  print "📶 SSID: '$(ssid)'"
  print "   MAC: $(mac)"
  print "   RSSI: $(rssi)"