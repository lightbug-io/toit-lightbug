import lightbug.devices as devices
import lightbug.firmware as firmware
import lightbug.modules.comms.forwarder show P1UsbForwarder
import lightbug.modules.comms.usb-console show UsbConsole

main:
  firmware.print-startup-line
  p1 := devices.I2C --open=false --background=false --startComms=true
  usb := UsbConsole --background=false
  P1UsbForwarder --usb=usb.comms --p1=p1.comms
