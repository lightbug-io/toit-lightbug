// Start QC through the 9600-baud RS232 adapter, then release the port.
// Run from examples: jag toit run -- host/qc-start.toit COM11 [--json]
import encoding.json
import .vending.peer show VendingPeer

main args:
  if args.size < 1 or args.size > 2 or (args.size == 2 and args[1] != "--json"):
    print "Usage: jag toit run -- host/qc-start.toit <serial-port> [--json]"
    throw "Invalid arguments"
  json-output := args.size == 2
  peer := VendingPeer
  try:
    peer.connect args[0]
    peer.command "start-qc" null #[0, 0, 0] 0 0
    previous := ""
    while peer.state["qc"]["running"]:
      stage := peer.state["qc"]["stage"]
      if not json-output and stage != previous: print stage
      previous = stage
      sleep --ms=100
    state := peer.state
    if json-output: print (json.encode state).to-string
    if not state["qc"]["acknowledged"]: throw state["qc"]["error"]
    if not json-output:
      print "Device $(state["qc"]["deviceId"]): server acknowledged QC Open."
      print "QC completion is reported separately by the server."
  finally:
    peer.disconnect
