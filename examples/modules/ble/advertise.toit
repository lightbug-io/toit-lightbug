import ble
import lightbug.devices as devices
import lightbug.modules.ble as lb-ble

main:
  // Create advertisement data with a name.
  advertisement := ble.Advertisement
      --name="Lightbug"

  // Create device with automatic BLE advertising.
  device := devices.I2C --ble-advertisement=advertisement

  print "📡 BLE advertising started with name 'Lightbug'"
  print "Advertising for 30 seconds..."

  sleep --ms=30_000

  // Stop advertising when done.
  device.ble.stop-advertise
  print "📡 BLE advertising stopped"
