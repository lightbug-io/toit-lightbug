PAGE ::= """
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Vending</title>
<style>pre { white-space: pre-wrap; overflow-wrap: anywhere; }</style>
</head>
<body>
<h1>Vending</h1>
<p id="connectionText">Disconnected</p>
<p id="error" role="alert" hidden></p>
<fieldset>
 <legend>Connection</legend>
 <label for="port">Serial port</label>
 <input id="port" value="COM11" placeholder="COM11 or /dev/ttyUSB0" autocomplete="off" spellcheck="false">
 <button id="connect">Connect</button>
 <p>9600 baud, 8N1</p>
</fieldset>
<fieldset>
 <legend>Requests</legend>
 <p><button id="status" data-command="status">Read status</button>
 <button id="authorise" data-command="authorise">Authorise</button>
 <button id="cancel" data-command="cancel">Cancel</button></p>
 <p><button data-command="device-ids">Read Device IDs (V3)</button></p>
 <pre id="deviceIds">Device IDs: not read yet</pre>
 <p><button data-command="start-qc">Start QC</button></p>
 <p id="qcState">QC has not been started.</p>
 <p>Start QC enables P1's cloud link and sends QC Open to the server. Acknowledgement confirms delivery; it does not mean QC passed.</p>
 <p><label><input id="poll" type="checkbox">Poll status</label>
 <label for="pollMs">Interval (ms)</label>
 <input id="pollMs" type="number" min="250" max="60000" step="250" value="2000"></p>
 <p id="authState">Authorisation: no acknowledgement yet</p>
 <details><summary>Request fields</summary>
  <p><label for="deviceId">Device ID (5 bytes, wire order)</label>
  <input id="deviceId" placeholder="Read status to populate" maxlength="10" spellcheck="false"></p>
  <p><label for="reserved">Reserved bytes</label>
  <select id="reserved"><option value="000000">00 00 00</option><option value="ffffff">FF FF FF</option></select></p>
 </details>
</fieldset>
<fieldset>
 <legend>Handshake sequence</legend>
 <p>Read status, then send authorisation using the returned ID.</p>
 <p><label for="sequenceFlag">Follow-up</label>
 <select id="sequenceFlag"><option value="0">Cancel (00)</option><option value="1">Authorise (01)</option></select>
 <label for="gap">Delay (ms)</label>
 <input id="gap" type="number" min="0" max="2000" step="1" value="3">
 <button id="sequence" data-command="sequence">Run sequence</button></p>
 <p>Actual host-side gap is logged. USB buffering and scheduling affect wire timing.</p>
</fieldset>
<h2>Status</h2>
<dl>
 <dt id="identityLabel">Device identifier</dt><dd><span id="identifier">—</span> <span id="identityDetail"></span></dd>
 <dt>Battery voltage</dt><dd><span id="voltage">— V</span> <span id="voltageDetail"></span></dd>
 <dt>Temperature</dt><dd id="temperature">— °C</dd>
 <dt>Round trip</dt><dd><span id="latency">— ms</span> <span id="latencyDetail"></span></dd>
</dl>
<p>Serial identifiers are modulo 1,000,000. The full serial is not returned.</p>
<h2>Conversation</h2>
<p><button id="export">Export JSON</button> <button id="clear">Clear view</button></p>
<p><span id="activity">Ready when you are</span>. <span id="count">0 transactions</span>.</p>
<div id="feed" role="log" aria-label="Serial transactions"><p id="empty">No transactions yet.</p></div>
<p>Last 200 transactions retained. Timing includes the request and complete reply.</p>
<script>
'use strict';
const el = id => document.getElementById(id);
let state = {connected:false,history:[]}, pending = false, lastId = 0, clearedThrough = 0, pollTimer, refreshTimer;
const commandButtons = Array.from(document.querySelectorAll('[data-command]'));
function fail(message) { el('error').textContent = message; el('error').hidden = !message; }
function controls() {
 el('connect').disabled = pending || state.busy;
 el('port').disabled = state.connected || pending;
 el('connect').textContent = state.connected ? 'Disconnect' : 'Connect';
 el('connectionText').textContent = state.connected ? 'Connected / ' + state.port : 'Disconnected';
 commandButtons.forEach(button => button.disabled = !state.connected || pending || state.busy || (['authorise','cancel'].includes(button.dataset.command) && !/^[0-9a-f]{10}\$/i.test(el('deviceId').value)));
 el('poll').disabled = !state.connected;
 el('activity').textContent = pending || state.busy ? 'Request in progress…' : state.connected ? 'Port open · waiting for a request' : 'Ready when you are';
}
async function api(path, body) {
 const response = await fetch(path, body === undefined ? {} : {method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
 const result = await response.json();
 if (!response.ok) throw new Error(result.error || 'Request failed');
 return result;
}
function render(next) {
 const wasConnected = state.connected;
 state = next;
 if (!state.connected) { el('poll').checked = false; clearTimeout(pollTimer); }
 const data = state.status;
 el('qcState').textContent = state.qc ? state.qc.stage : 'QC has not been started.';
 el('deviceIds').textContent = state.deviceIds ? JSON.stringify(state.deviceIds, null, 2) : 'Device IDs: not read yet';
 if (data) {
  el('identityLabel').textContent = data.identityType;
  el('identifier').textContent = String(data.identifier);
  el('identityDetail').textContent = '0x' + data.hexId;
  el('voltage').textContent = data.voltage.toFixed(3) + ' V';
  el('voltageDetail').textContent = 'ADC ' + data.adc + ' · approximate voltage';
  el('temperature').textContent = data.temperature + ' °C';
  if (data.wireId !== el('deviceId').dataset.lastId) {
   el('deviceId').value = data.wireId; el('deviceId').dataset.lastId = data.wireId;
  }
 } else {
  el('identityLabel').textContent = 'Device identifier'; el('identifier').textContent = '—';
  el('identityDetail').textContent = 'Read status to identify the device';
  el('voltage').textContent = '— V'; el('temperature').textContent = '— °C';
  if (wasConnected !== state.connected) { el('deviceId').value = ''; delete el('deviceId').dataset.lastId; }
 }
 const fresh = state.history.filter(item => item.id > lastId);
 fresh.forEach(item => {
  lastId = Math.max(lastId, item.id);
  if (item.id <= clearedThrough) return;
  el('empty').hidden = true;
  const card = document.createElement('article'); card.className = 'transaction'; card.dataset.id = item.id;
  const head = document.createElement('h3');
  head.textContent = '#' + item.id + ' ' + item.command + ' — ' + item.outcome + ' — ' + item.elapsedMs.toFixed(2) + ' ms';
  card.append(head);
  item.events.forEach(event => {
   const row = document.createElement('pre');
   const bytes = (event.hex.match(/.{1,2}/g) || []).join(' ').toUpperCase();
   row.textContent = event.direction + ' ' + bytes + ' (' + event.kind + ', +' + event.ms.toFixed(2) + ' ms)';
   card.append(row);
  });
  const details = [];
  if (item.data && typeof item.data.authorised === 'boolean') {
   const value = item.data.authorised ? 'Authorised' : 'Cancelled';
   details.push('Device acknowledgement: ' + value.toLowerCase());
   el('authState').textContent = 'Last acknowledgement: ' + value.toLowerCase();
  }
  if (item.followupGapMs !== undefined) details.push('Achieved follow-up gap: ' + item.followupGapMs.toFixed(3) + ' ms (host)');
  if (item.error) details.push(item.error);
  if (details.length) { const info = document.createElement('div'); info.className = 'extra'; info.textContent = details.join(' · '); card.append(info); }
  el('feed').append(card);
  if (item.ok) { el('latency').textContent = item.elapsedMs.toFixed(1) + ' ms'; el('latencyDetail').textContent = item.command + ' · complete response'; }
 });
 while (el('feed').querySelectorAll('.transaction').length > 200) el('feed').querySelector('.transaction').remove();
 if (fresh.length) el('feed').scrollTop = el('feed').scrollHeight;
 const count = el('feed').querySelectorAll('.transaction').length;
 el('count').textContent = count + ' transaction' + (count === 1 ? '' : 's');
 controls();
}
function schedulePoll() {
 clearTimeout(pollTimer);
 if (!el('poll').checked || !state.connected) return;
 const delay = Number(el('pollMs').value);
 if (!Number.isInteger(delay) || delay < 250 || delay > 60000) { fail('Polling interval must be 250–60000 ms'); el('poll').checked = false; return; }
 pollTimer = setTimeout(async () => { if (!pending && !state.busy) await send('status'); else schedulePoll(); }, delay);
}
async function send(command) {
 if (pending) return;
 clearTimeout(pollTimer); pending = true; fail(''); controls();
 try { render(await api('/api/command', {command,id:el('deviceId').value.trim(),reserved:el('reserved').value,gapMs:Number(el('gap').value),flag:Number(el('sequenceFlag').value)})); }
 catch (error) { fail(error.message); }
 finally { pending = false; controls(); schedulePoll(); }
}
el('connect').onclick = async () => {
 if (pending) return;
 pending = true; fail(''); clearTimeout(pollTimer); controls();
 try {
  render(await api(state.connected ? '/api/disconnect' : '/api/connect', {port:el('port').value.trim()}));
  el('authState').textContent = 'Authorisation: no acknowledgement yet';
 } catch (error) { fail(error.message); }
 finally { pending = false; controls(); schedulePoll(); }
};
commandButtons.forEach(button => button.onclick = () => send(button.dataset.command));
el('deviceId').oninput = controls;
el('poll').onchange = schedulePoll;
el('pollMs').onchange = schedulePoll;
el('clear').onclick = () => { clearedThrough = lastId; el('feed').querySelectorAll('.transaction').forEach(node => node.remove()); el('empty').hidden = false; el('count').textContent = '0 transactions'; };
el('export').onclick = () => {
 const blob = new Blob([JSON.stringify({exportedAt:new Date().toISOString(),...state},null,2)], {type:'application/json'});
 const url = URL.createObjectURL(blob), link = document.createElement('a');
 link.href = url; link.download = 'vending-session-' + new Date().toISOString().replace(/[:.]/g,'-') + '.json'; link.click(); setTimeout(() => URL.revokeObjectURL(url),1000);
};
async function refresh() {
 try { if (!pending) { render(await api('/api/state')); if (el('error').dataset.offline) { fail(''); delete el('error').dataset.offline; } } }
 catch (error) { fail('Vending app unavailable. Check that the local host process is running.'); el('error').dataset.offline = 'true'; state.connected = false; el('poll').checked = false; controls(); }
 finally { refreshTimer = setTimeout(refresh,1000); }
}
controls(); refresh();
</script></body></html>
"""
