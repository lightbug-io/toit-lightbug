import ...util.bytes show stringify-all-bytes
import ...devices as devices
import .msgs

html-page device/devices.Device docsUrl/string -> string:
  return """<html><head><meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    button, input[type="button"] {
        outline: none;
        border: none;
        background-color: #fc7c3d;
        color: #fff;
        padding: 10px;
        margin: 3px 5px 3px 0;
        cursor: pointer;
        
    }
  </style>
  </head><body>
  <h1>Lightbug $(device.name)</h1>
  <h2>Input</h2>
  <p>Use the below box to send bytes or messages to P1 (the device), or simulate receiving on P2 (the ESP).</p>
  <input type="button" value="Send (P1)" onclick="submit()">
  <input type="button" value="Simulate receive (P2/ESP)" onclick="submitP2()">
  </br><input type="text" id="post" name="post" style="width: 50%;">
  <p>The /post and /post-receive endpoints accept three formats:</p>
  <ul>
    <li>String payloads (text/plain): space-separated bytes like "3 23 0 40 ..."</li>
    <li>Form-encoded JSON: <code>payload={"bytes":[3,23,0,40,...]}</code></li>
  </ul>
  <a href="$(docsUrl)/devices/api/tools/generate" target="_blank">You can generate messages, or copy examples on the docs site</a>
  <h2>Log</h2>
  <a href="$(docsUrl)/devices/api/tools/parse" target="_blank">You can parse these logs back into viewable messages on the docs site</a>
  </br><div id="l"><span>Sent messages, and their responses will appear here...</span></div>
  
<script>
    function submit(input = null, end = '/post') {
        submitMulti([input], end);
    }
    function submitP2(input = null) {
        submitMulti([input], '/post-receive');
    }
    function submitMulti(inputs = [], end = '/post') {
        let post = inputs.map(input => {
            let p = input || document.getElementById('post').value;
            if (p.startsWith("custom:")) {
                return p;
            }
            return p.split(/[, ]+/).map(s => s.trim()).map(s => {
                if (s.startsWith('0x')) {
                    return parseInt(s, 16);
                } else {
                    return parseInt(s, 10);
                }
            }).join(' ');
        }).join('\\n');

        fetch(end, {
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
                            d.prepend(document.createElement('br'));
                            const p = document.createElement('span');
                            p.textContent = line;
                            d.prepend(p);
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
    function poll() {
        if (fetching) return;
        fetching = true;
        fetch('/poll')
        .then(response => response.text())
        .then(text => {
            const lines = text.split('\\n');
            lines.forEach(line => {
                if (line.trim() !== '') {
                    const d = document.getElementById('l');
                    d.prepend(document.createElement('br'));
                    const p = document.createElement('span');
                    p.textContent = line;
                    d.prepend(p);
                    const matches = line.match(/(\\d{1,3}(\\s\\d{1,3})+)/g);
                    if (matches) {
                        matches.forEach(b => {
                            const a = document.createElement('a');
                            a.href = "$(docsUrl)/devices/api/parse?bytes=" + b;
                            a.textContent = "(parse)";
                            a.target = "_blank";
                            d.prepend(document.createTextNode(' '));
                            d.prepend(a);
                        });
                    }
                }
            });
        })
        .catch((error) => {
            console.error('Error:', error);
        })
        .finally(() => {
            fetching = false;
        });
    }
    setInterval(poll, 2000);
</script>
</body></html>"""
