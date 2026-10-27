import encoding.hex
import io
import monitor
import uart
import lightbug.cust.vending_protocol show VendingProtocol
import lightbug.messages as messages
import lightbug.protocol as protocol
import lightbug.modules.comms.serial-framing show SerialFrameReader

// One lock covers a whole sequence, including connect/disconnect, so polling
// and commands from different browser tabs cannot interleave on the wire.
class VendingPeer:
  mutex_ := monitor.Mutex
  port_ /uart.Port? := null
  path_ /string? := null
  history_ /List := []
  next-id_ /int := 1
  next-message-id_ /int := 1
  last-status_ /Map? := null
  device-ids_ /Map? := null
  busy_ /bool := false
  qc_ /Map? := null

  state -> Map:
    return {
      "connected": port_ != null,
      "port": path_,
      "busy": busy_,
      "status": last-status_,
      "deviceIds": device-ids_,
      "qc": qc_,
      "history": history_.copy,
    }

  connect path/string:
    mutex_.do:
      if port_ != null: throw "Disconnect the current port first"
      port_ = uart.Port path --baud-rate=9600
      path_ = path
      last-status_ = null
      device-ids_ = null
      qc_ = null
      sleep --ms=250

  disconnect:
    mutex_.do:
      if port_ != null: port_.close
      port_ = null
      path_ = null
      last-status_ = null
      device-ids_ = null
      qc_ = null

  command name/string id/ByteArray? reserved/ByteArray gap-ms/int flag/int:
    if not ["status", "sequence", "authorise", "cancel", "device-ids", "start-qc"].contains name: throw "Unknown command"
    mutex_.do:
      if port_ == null: throw "Connect a serial port first"
      if busy_: throw "A request is already in progress"
      if name == "start-qc":
        busy_ = true
        qc_ = {"running": true, "stage": "Reading device IDs", "acknowledged": false, "startedAt": Time.now.stringify}
        // The HTTP request returns immediately; state polling shows progress.
        // Keep the same serial lock for the whole bounded startup sequence.
        task --background=true::
          mutex_.do:
            try:
              run-qc_
            finally:
              qc_["running"] = false
              busy_ = false
        return
      busy_ = true
      try:
        if name == "device-ids":
          exchange-device-ids_
        else if name == "status":
          exchange_ "Status" VendingProtocol.Cmd_GetStat #[]
        else if name == "sequence":
          status := exchange_ "Status" VendingProtocol.Cmd_GetStat #[]
          if status["ok"]:
            // Use this response's identity, not a stale value from the page.
            device-id := hex.decode status["data"]["wireId"]
            sleep --ms=gap-ms
            exchange_ (flag == 1 ? "Authorise" : "Cancel") VendingProtocol.Cmd_Auth (auth-data device-id reserved flag)
                --previous-response-us=status["receivedUs"]
        else:
          if id == null or id.size != 5: throw "Read status or enter a five-byte device ID"
          auth-flag := name == "authorise" ? 1 : 0
          exchange_ (auth-flag == 1 ? "Authorise" : "Cancel") VendingProtocol.Cmd_Auth (auth-data id reserved auth-flag)
      finally:
        busy_ = false

  exchange-device-ids_:
    response := exchange-v3_ "Device IDs (V3)" (p1-request messages.DeviceIDs.get-msg) messages.DeviceIDs.MT
    if response != null: device-ids_ = decode-device-ids response

  run-qc_:
    error := catch:
      response := exchange-v3_ "QC: Device IDs" (p1-request messages.DeviceIDs.get-msg) messages.DeviceIDs.MT
      if response == null: throw "Device IDs request failed; see conversation"
      device-ids_ = decode-device-ids response
      if device-ids_["id"] == null or device-ids_["id"] == 0: throw "P1 did not return a device ID"
      qc_["deviceId"] = device-ids_["id"]
      qc_["stage"] = "Opening P1 link"
      if (exchange-v3_ "QC: Open P1" (p1-request (messages.Open.msg --data=null)) messages.ACK.MT) == null:
        throw "P1 Open failed; see conversation"
      qc_["stage"] = "Enabling P1 cloud link"
      if (exchange-v3_ "QC: Enable cloud link" cloud-link-request messages.ACK.MT) == null:
        throw "Cloud link enable failed; see conversation"
      for attempt := 1; attempt <= 6; attempt++:
        qc_["stage"] = "Waiting for server acknowledgement ($attempt/6)"
        // Finish the local heartbeat exchange before transmitting again on
        // the half-duplex wire. Its ACK also confirms the ESP is still awake.
        if (exchange-v3_ "QC: Keep awake" (messages.Heartbeat.msg --data=null) messages.ACK.MT) == null:
          throw "RS232 heartbeat failed; see conversation"
        response = exchange-v3_ "QC: Open server ($attempt/6)" qc-open-request messages.ACK.MT --cloud=true --timeout-ms=10000
        if response != null:
          qc_["acknowledged"] = true
          qc_["stage"] = "Server acknowledged QC Open; QC checks are not verified"
          return
        if history_[history_.size - 1]["outcome"] != "timeout":
          throw "QC Open failed; see conversation"
      throw "No server acknowledgement after six attempts; check P1 cloud connectivity and return routing"
    if error:
      qc_["stage"] = "Failed: $error"
      qc_["error"] = "$error"

  exchange-v3_ label/string request/protocol.Message expected/int --cloud/bool=false --timeout-ms/int=5000 -> protocol.Message?:
    id := next-message-id_++
    request.header-add-data-uint32 protocol.Header.TYPE_MESSAGE_ID id
    wire := #[0x4c, 0x42] + request.bytes
    started-us := Time.monotonic-us
    events := []
    result := {
      "id": next-id_++, "command": label, "ok": false,
      "outcome": "timeout", "events": events, "data": null, "port": path_, "startedAt": Time.now.stringify,
    }
    response := null
    error := catch:
      with-timeout --ms=timeout-ms:
        events.add {"direction": "TX", "hex": hex.encode wire, "kind": label, "ms": (Time.monotonic-us - started-us) / 1000.0}
        port_.out.write wire --flush=true
        response = read-v3-response port_.in id request.bytes expected events started-us --cloud=cloud
        result["receivedUs"] = Time.monotonic-us
        result["elapsedMs"] = (Time.monotonic-us - started-us) / 1000.0
        result["data"] = expected == messages.DeviceIDs.MT ? (decode-device-ids response) : {"responseTo": response.response-to, "status": response.msg-status, "cloudAcknowledged": cloud}
        if response.msgId != null and response.type != messages.ACK.MT:
          ack := messages.ACK.msg --data=null
          ack.header-add-data-uint32 protocol.Header.TYPE_RESPONSE_TO_MESSAGE_ID response.msgId
          ack-wire := #[0x4c, 0x42] + ack.bytes
          port_.out.write ack-wire --flush=true
          events.add {"direction": "TX", "hex": hex.encode ack-wire, "kind": "V3 ACK", "ms": (Time.monotonic-us - started-us) / 1000.0}
        result["ok"] = true
        result["outcome"] = "success"
    if error:
      response = null
      result["elapsedMs"] = (Time.monotonic-us - started-us) / 1000.0
      result["outcome"] = error == DEADLINE-EXCEEDED-ERROR ? "timeout" : "error"
      result["error"] = error == DEADLINE-EXCEEDED-ERROR ? "No matching response within $timeout-ms ms" : "$error"
    history_.add result
    if history_.size > 200: history_ = history_[1..]
    return response

  exchange_ label/string command/int data/ByteArray --previous-response-us/int?=null -> Map:
    frame := VendingProtocol.build-command-frame command data
    events := []
    started-us := Time.monotonic-us
    result := {
      "id": next-id_++, "command": label, "ok": false,
      "outcome": "timeout", "events": events, "data": null, "port": path_, "startedAt": Time.now.stringify,
    }
    if previous-response-us != null:
      result["followupGapMs"] = (started-us - previous-response-us) / 1000.0
    events.add {"direction": "TX", "hex": hex.encode frame, "kind": "request", "ms": 0.0}
    error := catch:
      with-timeout --ms=3000:
        port_.out.write frame --flush=true
        expected := command == VendingProtocol.Cmd_GetStat ? VendingProtocol.Res_GetStat : VendingProtocol.Res_Auth
        response := read-response port_.in expected events started-us
        result["receivedUs"] = response["receivedUs"]
        result["elapsedMs"] = (response["receivedUs"] - started-us) / 1000.0
        result["statusCode"] = response["payload"][1]
        decoded := decode-response response["payload"]
        result["data"] = decoded
        result["ok"] = response["payload"][1] == VendingProtocol.Stat_Success
        result["outcome"] = status-name response["payload"][1]
        if result["ok"] and command == VendingProtocol.Cmd_GetStat:
          last-status_ = decoded
        if result["ok"] and command == VendingProtocol.Cmd_Auth and decoded["authorised"] != (data[8] == 1):
          result["ok"] = false
          result["outcome"] = "state mismatch"
    if error:
      result["elapsedMs"] = (Time.monotonic-us - started-us) / 1000.0
      result["outcome"] = error == DEADLINE-EXCEEDED-ERROR ? "timeout" : "error"
      result["error"] = error == DEADLINE-EXCEEDED-ERROR ? "No valid response within 3000 ms" : "$error"
    history_.add result
    if history_.size > 200: history_ = history_[1..]
    return result

auth-data id/ByteArray reserved/ByteArray flag/int -> ByteArray:
  if id.size != 5 or reserved.size != 3 or (flag != 0 and flag != 1): throw "Invalid authorisation fields"
  data := ByteArray 9
  5.repeat: data[it] = id[it]
  3.repeat: data[5 + it] = reserved[it]
  data[8] = flag
  return data

read-response reader/io.Reader expected/int events/List started-us/int -> Map:
  error-text := "ERROR\r\n".to-byte-array
  error-position := 0
  noise := io.Buffer
  while true:
    if reader.peek-byte == 'L':
      frame := (SerialFrameReader).read-next reader
      if frame != null:
        events.add {"direction": "RX", "hex": hex.encode (#[0x4c, 0x42] + frame.bytes), "kind": "unrelated V3 frame", "ms": (Time.monotonic-us - started-us) / 1000.0}
      continue
    byte := reader.read-byte
    if byte != VendingProtocol.HEADER:
      noise.write #[byte]
      error-position = byte == error-text[error-position] ? error-position + 1 : (byte == error-text[0] ? 1 : 0)
      if error-position == error-text.size:
        events.add {"direction": "RX", "hex": hex.encode noise.bytes, "kind": "device error", "ms": (Time.monotonic-us - started-us) / 1000.0}
        throw "Device replied ERROR"
      // Keep garbage bounded even when a noisy peer never sends a header.
      if noise.size == 100:
        events.add {"direction": "RX", "hex": hex.encode noise.bytes, "kind": "noise", "ms": (Time.monotonic-us - started-us) / 1000.0}
        noise = io.Buffer
      continue
    error-position = 0
    if noise.size > 0:
      events.add {"direction": "RX", "hex": hex.encode noise.bytes, "kind": "noise", "ms": (Time.monotonic-us - started-us) / 1000.0}
      noise = io.Buffer
    event := {"direction": "RX", "hex": hex.encode #[byte], "kind": "partial frame", "ms": (Time.monotonic-us - started-us) / 1000.0}
    events.add event
    length := reader.read-byte
    event["hex"] = hex.encode #[byte, length]
    if length < 4 or length > VendingProtocol.BUFFER_SIZE:
      event["kind"] = "invalid length"
      continue
    frame := ByteArray length + 2
    frame[0] = byte
    frame[1] = length
    length.repeat:
      frame[it + 2] = reader.read-byte
      event["hex"] = hex.encode frame[..it + 3]
    received-us := Time.monotonic-us
    payload := VendingProtocol.command-payload-from-frame frame
    event["kind"] = "invalid checksum / terminator"
    event["ms"] = (received-us - started-us) / 1000.0
    if payload == null: continue
    event["kind"] = "unexpected response"
    if payload[0] == VendingProtocol.Cmd_GetStat or payload[0] == VendingProtocol.Cmd_Auth:
      event["kind"] = "adapter echo"
      continue
    if payload[0] != expected: continue
    event["kind"] = "invalid response payload"
    valid := catch: decode-response payload
    if valid: continue
    event["kind"] = "response"
    return {"payload": payload, "receivedUs": received-us}

read-device-ids reader/io.Reader id/int request/ByteArray events/List started-us/int -> protocol.Message:
  return read-v3-response reader id request messages.DeviceIDs.MT events started-us

read-v3-response reader/io.Reader id/int request/ByteArray expected/int events/List started-us/int --cloud/bool=false -> protocol.Message:
  scanner := SerialFrameReader
  while true:
    frame := scanner.read-next reader
    if frame == null: continue
    event := {"direction": "RX", "hex": hex.encode (frame.v3 ? (#[0x4c, 0x42] + frame.bytes) : frame.bytes), "kind": "unrelated vending frame", "ms": (Time.monotonic-us - started-us) / 1000.0}
    events.add event
    if not frame.v3: continue
    event["kind"] = "unrelated V3 frame"
    if frame.bytes == request:
      event["kind"] = "adapter echo"
      continue
    response := protocol.Message.from-bytes frame.bytes
    if response.response-to != id: continue
    if cloud and not cloud-origin response: continue
    event["kind"] = cloud ? "server response" : "V3 response"
    if response.msg-status != null and response.msg-status < 0: continue
    if not response.msg-ok: throw "V3 request rejected: status=$(response.msg-status)"
    if response.type == expected: return response

decode-device-ids response/protocol.Message -> Map:
  data := messages.DeviceIDs.from-data response.data
  return {
    "id": data.has-data messages.DeviceIDs.ID ? data.id : null,
    "serial": data.has-data messages.DeviceIDs.SERIAL ? data.serial : null,
    "imei": data.has-data messages.DeviceIDs.IMEI ? data.imei : null,
    "iccid": data.has-data messages.DeviceIDs.ICCID ? data.iccid : null,
  }

decode-response payload/ByteArray -> Map?:
  if payload.size < 3: throw "Missing response status"
  if payload[1] != VendingProtocol.Stat_Success: return null
  if payload[0] == VendingProtocol.Res_Auth:
    if payload.size != 4 or payload[2] > 1: throw "Invalid authorisation response"
    return {"authorised": payload[2] == 1}
  if payload[0] != VendingProtocol.Res_GetStat or payload.size != 12: throw "Invalid status response"
  data := payload[2..payload.size - 1]
  id := io.LITTLE-ENDIAN.read-uint data 5 0
  prefix := id >> 32
  adc := io.LITTLE-ENDIAN.uint16 data 7
  return {
    "deviceId": id,
    "hexId": "$(%010x id)",
    "wireId": hex.encode data[..5],
    "identityType": prefix == VendingProtocol.ID_PREFIX_SERIAL ? "Serial suffix" : (prefix == VendingProtocol.ID_PREFIX_CURRENT ? "Current ID" : "Unknown prefix"),
    "identifier": id & 0xFFFF_FFFF,
    "temperature": data[6] >= 128 ? data[6] - 256 : data[6],
    "voltage": adc * 453.0 / 102400.0,
    "adc": adc,
  }

status-name code/int -> string:
  if code == VendingProtocol.Stat_Success: return "success"
  if code == VendingProtocol.Stat_Fail: return "device failure"
  if code == VendingProtocol.Stat_NoSupport: return "unsupported"
  return "unknown status 0x$(%02x code)"

// P1 adds cloud origin before relaying the server response back to the ESP.
cloud-origin response/protocol.Message -> bool:
  return response.header-has-data protocol.Header.TYPE_FORWARDED_FOR and
      (response.header-get-data-uint protocol.Header.TYPE_FORWARDED_FOR) == protocol.Header.LINK_ID_CHASM

p1-request request/protocol.Message -> protocol.Message:
  request.header-add-data-uint8 protocol.Header.TYPE_FORWARD_TO protocol.Header.LINK_ID_P1
  return request

cloud-link-request -> protocol.Message:
  data := messages.LinkControl.data --enable=true
  return p1-request (messages.LinkControl.set-msg --base-data=data)

qc-open-request -> protocol.Message:
  request := messages.Open.msg --data=null
  request.header-add-data-string 50 "qc"
  request.header-add-data-string 51 "day"
  request.header-add-data-uint8 protocol.Header.TYPE_FORWARD_TO protocol.Header.LINK_ID_CHASM
  return request
