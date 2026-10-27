// Local vending test console. Run from examples using the host's Jaguar:
//   jag toit run host/vending.toit
// Open http://127.0.0.1:8765, then connect the adapter's port in the page.
// An optional argument selects a different HTTP port. The device is not flashed.

import encoding.hex
import encoding.json
import http
import log
import net
import net.modules.tcp show TcpServerSocket
import .peer show VendingPeer
import .page show PAGE

main args:
  if args.size > 1:
    print "Usage: jag toit run host/vending.toit [http-port]"
    return
  port := args.size == 1 ? (int.parse args[0]) : 8765
  if port < 1 or port > 65535: throw "Invalid HTTP port"
  peer := VendingPeer
  network := net.open
  socket := TcpServerSocket network
  socket.listen "127.0.0.1" port
  print "Vending: http://127.0.0.1:$port"
  try:
    (http.Server --max-tasks=8 --logger=(log.default.with-level log.ERROR-LEVEL)).listen socket:: | request/http.RequestIncoming writer/http.ResponseWriter |
      handle request writer peer port
  finally:
    peer.disconnect
    socket.close
    network.close

handle request/http.RequestIncoming writer/http.ResponseWriter peer/VendingPeer port/int:
  try:
    writer.headers.set "Cache-Control" "no-store"
    // Restrict browser requests to this loopback origin, including Host checks
    // so a different origin cannot use the console through DNS rebinding.
    host := request.headers.get "Host"
    if host == null or host.size != 1 or not ["127.0.0.1:$port", "localhost:$port"].contains host[0]:
      request.body.read-all
      reply writer {"error": "Invalid host"} --status=403
      return
    origin := request.headers.get "Origin"
    if origin != null and (origin.size != 1 or not ["http://127.0.0.1:$port", "http://localhost:$port"].contains origin[0]):
      request.body.read-all
      reply writer {"error": "Invalid origin"} --status=403
      return
    path := request.query.resource
    if request.method == http.GET and path == "/":
      writer.headers.set "Content-Type" "text/html; charset=utf-8"
      writer.out.write PAGE
      return
    if request.method == http.GET and path == "/api/state":
      reply writer peer.state
      return
    if request.method != http.POST or not ["/api/connect", "/api/disconnect", "/api/command"].contains path:
      request.body.read-all
      reply writer {"error": "Not found"} --status=404
      return
    result := null
    error := catch:
      body := json.decode request.body.read-all
      if body is not Map: throw "Expected a JSON object"
      if path == "/api/connect":
        serial-port := body.get "port"
        if serial-port is not string or serial-port.trim == "": throw "Enter a serial port"
        peer.connect serial-port.trim
      else if path == "/api/disconnect":
        peer.disconnect
      else:
        name := body.get "command"
        if not ["status", "authorise", "cancel", "sequence", "device-ids", "start-qc"].contains name: throw "Unknown command"
        if name == "device-ids" or name == "start-qc":
          peer.command name null #[0, 0, 0] 0 0
          reply writer peer.state
          return
        id-text := body.get "id" --if-absent=(: "")
        reserved-text := body.get "reserved" --if-absent=(: "000000")
        if id-text is not string or reserved-text is not string: throw "Invalid hex fields"
        if id-text != "" and id-text.size != 10: throw "Device ID must contain exactly ten hex digits"
        if reserved-text.size != 6: throw "Reserved field must contain exactly six hex digits"
        id := id-text == "" ? null : (hex.decode id-text)
        reserved := hex.decode reserved-text
        if reserved.size != 3: throw "Reserved field must contain three bytes"
        gap := body.get "gapMs" --if-absent=(: 3)
        flag := body.get "flag" --if-absent=(: 0)
        if gap is not int or gap < 0 or gap > 2000: throw "Gap must be 0 to 2000 ms"
        if flag is not int or (flag != 0 and flag != 1): throw "Flag must be 0 or 1"
        peer.command name id reserved gap flag
      result = peer.state
    if error:
      reply writer {"error": "$error"} --status=400
    else:
      reply writer result
  finally:
    writer.close

reply writer/http.ResponseWriter value --status/int=200:
  writer.headers.set "Content-Type" "application/json"
  writer.write-headers status
  writer.out.write (json.encode value)
