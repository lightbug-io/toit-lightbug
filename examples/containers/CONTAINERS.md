# Containers

## Base vending

`base-vending.toit` shares the 9600-baud RS232 connection between vending frames
and V3 messages. V3 requires the `LB` prefix; `MixedSerial --require-prefix=false`
also accepts bare V3. USB console V3 and the P1 I2C link run alongside it.

RS232 uses link ID 8, distinct from USB console (7). Forward To `[1, 8]` routes
through ESP32 to RS232; `[3]` routes an external request to P1, and `[0]` routes
it through P1 to the cloud. Remaining destination hops are preserved.

External V3 traffic holds off deep sleep for 60 seconds; keep sending heartbeats
while waiting for a QC result. This does not add a new RS232 wake source: delivery
while asleep still depends on the existing P1/wake configuration.

## Base

The "base" container provides basic ESP functionality as part of a Lightbug Device.

In summary this will listen for messages relating to hardware that the ESP itself controls, such as: 
 - BLE scanning
 - WiFi scanning
 - Strobe LED control

If the ESP receives messages relating to this hardware, it will respond accordingly.

## Base Apps

This builds on top of the "base" container, and provides a set of applications that run on the device, accessible via the "Actions" button on the device.

This is only intended to work with devices which feature a display and buttons, such as the Lightbug RH2, and should not be used with other devices.

You can see more about these applications at https://docs.lightbug.io/devices/api/sdks/toit/applications/

And as part of this container, the ESP will subscribe to button press events when powered on.

When developing, if you want an app to launch automatically when the device is powered on, you can set the `lb-app` define, for example: `-D lb-app=relay`
