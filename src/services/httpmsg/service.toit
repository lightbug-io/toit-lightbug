import ...protocol as protocol
import ...devices as devices
import ...services as services
import ...messages as messages
import ...util.resilience show catchAndRestart
import ...util.docs show docsUrl
import ...util.bytes show stringifyAllBytes
import http
import net
import log

// Hosts a small HTTP server that serves a page for directly sending bytes or messages to a Lightbug device
class HttpMsg:

  static DEFAULT_PORT /int := 18019

  static msg-opts := {
    "$(messages.HapticsControl.MT) Haptics": {
      "Pattern 1, low intensity": (messages.HapticsControl.doMsg messages.HapticsControl.PATTERN_1 messages.HapticsControl.INTENSITY-LOW).bytesForProtocol,
      "Pattern 2, low intensity": (messages.HapticsControl.doMsg messages.HapticsControl.PATTERN_2 messages.HapticsControl.INTENSITY-LOW).bytesForProtocol,
      "Pattern 3, low intensity": (messages.HapticsControl.doMsg messages.HapticsControl.PATTERN_3 messages.HapticsControl.INTENSITY-LOW).bytesForProtocol,
    },
    "$(messages.BuzzerControl.MT) Buzzer": {
      "20ms, 0.5khz": (messages.BuzzerControl.doMsg --duration=20 --frequency=0.5 ).bytesForProtocol,
      "200ms, 1khz": (messages.BuzzerControl.doMsg --duration=200 --frequency=1.0 ).bytesForProtocol,
    },
    "$(messages.AlarmControl.MT) Alarm": {
      "Duration 0": (messages.AlarmControl.doMsg --duration=0).bytesForProtocol,
      "3s pattern 4 intensity 1": (messages.AlarmControl.doMsg --duration=3 --buzzerPattern=4 --buzzerIntensity=1).bytesForProtocol,
    },
  }

  static MSG_HAPTICS_CONTROL /ByteArray := (messages.HapticsControl.doMsg 1 1).bytesForProtocol // patern 1, intensity 0

  srvPort /int
  deviceComms_ /services.Comms
  deviceName_ /string // TODO could pass in the whole device?

  constructor deviceName/string deviceComms/services.Comms --port/int=DEFAULT_PORT:
    srvPort = port
    deviceComms_ = deviceComms
    deviceName_ = deviceName
    task:: catchAndRestart "lightbug-HtmlMsgServer::serveHttp" (:: serveHttp)

  serveHttp:
    log.debug "Starting lightbug-HtmlMsgServer on port $srvPort"
    network := net.open
    tcp_socket := network.tcp_listen srvPort
    // Only log INFO level server messages (especially as these come back through this log server..)
    server := http.Server --logger=(log.Logger log.INFO-LEVEL log.DefaultTarget) --max-tasks=5
    server.listen tcp_socket:: | request/http.RequestIncoming writer/http.ResponseWriter |
      resource := request.query.resource
      // TODO factor the page out into its own file
      if resource == "/":
        // Use msg-opts to dynamically generate buttons for sending messages
        dynamicHtml := ""
        msg-opts.keys.map: |key|
          dynamicHtml = dynamicHtml + """$key:\n"""
          msg-opts[key].keys.map: |action|
            dynamicHtml = dynamicHtml + """<input type="button" value="$action" onclick="submit('$(stringifyAllBytes msg-opts[key][action] --short=true --commas=false --hex=false)')">\n"""
          dynamicHtml = dynamicHtml + """</br>\n"""
        html := """<html><body>
        <h1>Lightbug $(deviceName_)</h1>
        <input type="button" value="Send bytes" onclick="submit()">
        <input type="text" id="post" name="post" style="width: 50%;">
        <h4>Presets</h4>
        $(dynamicHtml)
        Info:
        <input type="button" value="Status" onclick="submit('3 17 0 34 0 2 0 5 1 1 2 1 51 0 0 206 243')">
        <input type="button" value="Time" onclick="submit('3 17 0 36 0 2 0 1 5 1 89 1 2 0 0 3 61')">
        <input type="button" value="IMEI" onclick="submit('3 19 0 32 0 2 0 1 5 1 234 1 2 1 0 1 0 21 145')">
        <input type="button" value="ICCID" onclick="submit('3 19 0 33 0 2 0 1 5 1 234 1 2 1 0 1 0 116 234')">
        <input type="button" value="ID" onclick="submit('3 19 0 35 0 2 0 1 5 1 234 1 2 1 0 1 0 182 28')">
        <input type="button" value="Temp" onclick="submit('3 14 0 41 0 1 0 5 1 2 0 0 39 176')">
        <input type="button" value="Pressure" onclick="submit('3 14 0 44 0 1 0 5 1 2 0 0 235 199')">
        <input type="button" value="Location" onclick="submit('3 17 0 15 0 2 0 1 5 1 145 1 2 0 0 1 124')">
        </br>
        GSM:
        <input type="button" value="SET Normal mode" onclick="submit('3 17 0 31 0 1 0 5 1 1 1 0 1 1 1 75 30')">
        <input type="button" value="SET Airplane mode 10s" onclick="submit('3 23 0 31 0 1 0 5 1 1 2 0 1 2 1 0 4 10 0 0 0 56 139')">
        <input type="button" value="GET CFUN" onclick="submit('3 14 0 31 0 1 0 5 1 2 0 0 173 30')">
        <input type="button" value="txnow (txnowweb)" onclick="submit('3 27 0 30 0 2 0 5 1 1 4 1 195 1 0 2 8 116 120 110 111 119 119 101 98 95 250')">
        </br>
        Location:
        <input type="button" value="RTK ON" onclick="submit('3 17 0 39 0 1 0 5 1 1 1 0 1 1 1 19 92')">
        <input type="button" value="RTK OFF" onclick="submit('3 17 0 39 0 1 0 5 1 1 1 0 1 1 2 112 108')">
        </br>
        Preset pages:
        <input type="button" value="Default" onclick="submit('3, 14, 0, 24, 39, 1, 0, 1, 1, 43, 0, 0, 39, 130')">
        </br>
        Text pages:
        <input type="button" value="Page 101: Title and line 1" onclick="submit('3 41 0 25 39 1 0 1 1 233 3 0 3 4 100 1 101 10 80 97 103 101 32 84 105 116 108 101 10 70 105 114 115 116 32 76 105 110 101 144 215')">
        <input type="button" value="Page 101: line 2" onclick="submit('3 30 0 25 39 1 0 1 1 233 2 0 3 101 1 101 11 83 101 99 111 110 100 32 76 105 110 101 50 24')">
        <input type="button" value="Page 101: clear all lines" onclick="submit('3 27 0 25 39 1 0 1 1 233 6 0 3 101 100 102 104 103 1 101 0 0 0 0 0 244 71')">
        </br>
        Menu pages:
        <input type="button" value="Page 102: 2 options" onclick="submit('3 32 0 26 39 1 0 1 1 186 4 0 3 100 101 2 1 102 4 111 112 116 49 4 111 112 116 50 1 2 31 14')">
        <input type="button" value="Page 102: change opt 2" onclick="submit('3 40 0 26 39 1 0 1 1 186 4 0 3 100 101 2 1 102 4 111 112 116 49 12 111 112 116 50 32 99 104 97 110 103 101 100 1 2 210 27')">
        <input type="button" value="Page 103: 2 options (selected 2nd)" onclick="submit('3 35 0 26 39 1 0 1 1 186 5 0 3 100 101 2 5 1 103 4 111 112 116 49 4 111 112 116 50 1 2 1 1 107 145')">
        </br><a href="$(docsUrl)/devices/api/generate" target="_blank">You can also generate your own messages</a>
        <h1>Log</h1>
        <div id="l"><span>Sent messages, and their responses will appear here...</span></div>
        <script>
          function submit(input = null) {
            let post = input || document.getElementById('post').value;
            post = post.split(/[, ]+/).map(s => s.trim()).map(s => {
              if (s.startsWith('0x')) {
                return parseInt(s, 16);
              } else {
                return parseInt(s, 10);
              }
            }).join(' ');
            fetch('/post', {
              method: 'POST',
              body: post,
            })
            .then(response => {
              const reader = response.body.getReader();
              const decoder = new TextDecoder();
              function read() {
                reader.read().then(({ done, value }) => {
                  if (done) {
                    return;
                  }
                  const text = decoder.decode(value, { stream: true });
                  const lines = text.split('\\n');
                  lines.forEach(line => {
                    if (line.trim() !== '') {
                      const d = document.getElementById('l');
                      const p = document.createElement('span');
                      p.textContent = line;
                      d.prepend(p);
                      line.match(/(\\d{1,3}(\\s\\d{1,3})+)/g).forEach(b => {
                          const a = document.createElement('a');
                          a.href = "$(docsUrl)/devices/api/parse?bytes=" + b;
                          a.textContent = "(parse)";
                          a.target = "_blank";
                          d.prepend(document.createTextNode(' '));
                          d.prepend(a);
                      });
                      d.prepend(document.createElement('br'));
                    }
                  });
                  read();
                }).catch(error => {
                  console.error('Error reading stream:', error);
                });
              }
              read();
            })
            .catch((error) => {
              console.error('Error:', error);
            });
          }
          let fetching = false;
        </script>
        </body></html>"""
        writer.headers.set "Content-Type" "text/html"
        writer.headers.set "Content-Length" html.size.stringify
        writer.write-headers 200
        writer.out.write html
      if resource == "/post":
        body := request.body.read-all
        writer.headers.set "Content-Type" "text/plain"
        writer.headers.set "Access-Control-Allow-Origin" "*"
        writer.write_headers 200
        // Read the input bytes, and convert to a msg
        byteList := []
        ((body.to-string.split " ").do: |s| byteList.add (int.parse s))
        msg := protocol.Message.fromList byteList
        // TODO detect invalid msg and let the user know..
        msgLatch := deviceComms_.send msg
          --now=true
          --withLatch=true
          --preSend=(:: writer.out.write "$(it.msgId) Sending: $(stringifyAllBytes (listToByteArray byteList) --short=true --commas=false --hex=false)\n")
          --postSend=(:: writer.out.write "$(it.msgId) Sent: $(stringifyAllBytes msg.bytesForProtocol --short=true --commas=false --hex=false)\n")
        // Wait for the response
        response := msgLatch.get
        if response == false:
          writer.out.write "$(msg.msgId) Error: No response\n"
        else:
          writer.out.write "$(msg.msgId) Response $(response.msgId): $(stringifyAllBytes response.bytesForProtocol --short=true --commas=false --hex=false)\n"
      else :
        writer.headers.set "Content-Type" "text/plain"
        writer.write_headers 404
        writer.out.write "Not found\n"
      writer.close

listToByteArray l/List -> ByteArray:
  b := ByteArray l.size
  for i := 0; i < l.size; i++:
    b[i] = l[i]
  return b