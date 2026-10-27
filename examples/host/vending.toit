// Run from examples: jag toit run host/vending.toit [http-port]
// Open http://127.0.0.1:8765 and connect the serial adapter in the page.
import .vending.server as vending

main args:
  vending.main args
