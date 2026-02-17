# Containers

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