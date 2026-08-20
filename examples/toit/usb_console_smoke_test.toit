// Exercises the ESP-IDF primary console input through io.stdin.
//
// Requires Toit v2.0.0-alpha.198 or newer. The firmware chooses which
// console backend supplies stdin. Console output can be mirrored to USB
// Serial/JTAG even when input is routed to UART0, so seeing logs on a USB
// CDC port does not guarantee that input sent there reaches this program.
import io

main:
  print "USB-CONSOLE-READY"

  while true:
    received := io.stdin.read
    print "USB-CONSOLE-RX: $received"
    io.stdout.write "BBB\n".to-byte-array --flush=true
