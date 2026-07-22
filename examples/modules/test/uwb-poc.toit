import gpio
import spi

// Hardware-specific UWB proof of concept for RH2-family boards.
//
// The UWB driver has not been added to lightbug yet. This retains the original
// low-level SPI check so it can be run manually on compatible hardware:
//
//   jag run examples/modules/test/uwb-poc.toit
main:
  print "Testing UWB chip"
  pin-enable-uwb := gpio.Pin 1 --output=true
  pin-enable-uwb.set 0
  sleep --ms=250
  pin-enable-uwb.set 1

  spi-bus := spi.Bus
      --miso=gpio.Pin 5
      --mosi=gpio.Pin 4
      --clock=gpio.Pin 2
  spi-bus-device := spi-bus.device
      --frequency=10_000
  pin-cs := gpio.Pin 3 --output=true
  pin-cs.set 1
  sleep --ms=100

  pin-cs.set 0
  spi-bus-device.write #[0x00]
  response := spi-bus-device.read 4
  pin-cs.set 1

  if response != #[0x02, 0x03, 0xca, 0xde]:
    throw "UWB chip did not respond as expected: $response"
  print "UWB chip responded as expected"
