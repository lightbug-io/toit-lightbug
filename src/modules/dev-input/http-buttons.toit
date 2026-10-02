import ...devices show Device
import ...messages as messages
import ...protocol as protocol
import http
import log
import net

/** Opt-in development HTTP bridge into the device's normal P2 inbound path. */
class DevButtonServer:
  device_/Device
  port_/int
  logger_/log.Logger := log.default.with-name "dev-buttons"
  network_/any? := null
  socket_/any? := null
  server_/http.Server? := null

  constructor device/Device --port/int=8080:
    device_ = device
    port_ = port

  start:
    network_ = net.open
    socket_ = network_.tcp_listen port_
    server_ = http.Server --logger=(logger_.with-level log.WARN-LEVEL) --max-tasks=4
    logger_.info "Virtual button control listening on port $port_"
    task::
      server_.listen socket_:: |request/http.RequestIncoming writer/http.ResponseWriter|
        path := request.query.resource
        if path == "/":
          writer.headers.set "Content-Type" "text/html; charset=utf-8"
          writer.write_headers 200
          writer.out.write "<html><meta name='viewport' content='width=device-width'><h1>RH2 virtual buttons</h1><p>P2 page ID: <input id='p' type='number' value='34'></p><button onclick='press(1)'>Left</button> <button onclick='press(0)'>Center</button> <button onclick='press(2)'>Right</button><pre id='result'></pre><script>function press(id){fetch('/button?id='+id+'&page='+document.getElementById('p').value,{method:'POST'}).then(r=>r.text()).then(t=>document.getElementById('result').textContent=t)}</script><p>Virtual P2 events only. P1 home screen and physical button state are unchanged.</p></html>"
          writer.close
        else if path == "/gnss" and request.method == "GET":
          e := catch:
            control-reply := device_.comms.send-new messages.GPSControl.get-msg --timeout=(Duration --s=5)
            position-reply := device_.comms.send-new messages.Position.get-msg --timeout=(Duration --s=5)
            writer.headers.set "Content-Type" "text/plain; charset=utf-8"
            writer.write_headers 200
            if control-reply == null:
              writer.out.write "GPS Control: no response\n"
            else:
              control := messages.GPSControl.from-data control-reply.data
              writer.out.write "GPS on: $(control.has-data messages.GPSControl.GPS-IS-ON ? control.gps-is-on : "unknown")\n"
            if position-reply == null:
              writer.out.write "Position: no response\n"
            else:
              position := messages.Position.from-data position-reply.data
              writer.out.write "Position type=$(position.type) lat=$(position.latitude) lon=$(position.longitude)\n"
          if e:
            logger_.warn "GNSS diagnostic failed: $e"
          writer.close
        else if path == "/radio" and request.method == "GET":
          e := catch:
            reply := device_.comms.send-new messages.LoRa.get-msg --timeout=(Duration --s=5)
            writer.headers.set "Content-Type" "text/plain; charset=utf-8"
            writer.write_headers 200
            if reply == null:
              writer.out.write "LoRa: no response\n"
            else:
              radio := messages.LoRa.from-data reply.data
              writer.out.write "LoRa state=$(radio.state) flags=$(radio.status-flags) (flag 8=subscription active)\n"
          if e:
            logger_.warn "LoRa diagnostic failed: $e"
          writer.close
        else if path == "/button" and request.method != "POST":
          writer.write_headers 405
          writer.close
        else if path == "/button":
          params := request.query.parameters
          e := catch:
            id := int.parse params["id"]
            page := int.parse params["page"]
            duration-param := params.get "duration" --if-absent=(: null)
            duration := duration-param == null ? 500 : int.parse duration-param
            if id < 0 or id > 2 or page < 0 or page > 255 or duration < 1 or duration > 3000:
              throw "Invalid button parameters"
            data := messages.ButtonPress.data --button-id=id --page-id=page --duration=duration
            menu-param := params.get "menu-item" --if-absent=(: null)
            if menu-param != null:
              item := int.parse menu-param
              if item < 0 or item > 255: throw "Invalid menu item"
              data.add-data-uint messages.ButtonPress.MENU-ITEM item
            msg := protocol.Message.with-data messages.ButtonPress.MT data
            logger_.info "Virtual button id=$id page=$page duration=$duration"
            device_.comms.inject-inbound msg
          if e:
            writer.write_headers 400
            writer.out.write "$e"
          else:
            writer.write_headers 200
            writer.out.write "OK"
          writer.close
        else:
          writer.write_headers 404
          writer.close
