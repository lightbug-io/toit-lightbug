import encoding.hex
import io
import monitor
import uart
import lightbug.cust.vending_protocol show VendingProtocol

// One lock covers a whole sequence, including connect/disconnect, so polling
// and commands from different browser tabs cannot interleave on the wire.
class VendingPeer:
  mutex_ := monitor.Mutex
  port_ /uart.Port? := null
  path_ /string? := null
  history_ /List := []
  next-id_ /int := 1
  last-status_ /Map? := null
  busy_ /bool := false

  state -> Map:
    return {
      "connected": port_ != null,
      "port": path_,
      "busy": busy_,
      "status": last-status_,
      "history": history_.copy,
    }

  connect path/string:
    mutex_.do:
      if port_ != null: throw "Disconnect the current port first"
      port_ = uart.Port path --baud-rate=9600
      path_ = path
      last-status_ = null
      sleep --ms=250

  disconnect:
    mutex_.do:
      if port_ != null: port_.close
      port_ = null
      path_ = null
      last-status_ = null

  command name/string id/ByteArray? reserved/ByteArray gap-ms/int flag/int:
    if not ["status", "sequence", "authorise", "cancel"].contains name: throw "Unknown command"
    mutex_.do:
      if port_ == null: throw "Connect a serial port first"
      busy_ = true
      try:
        if name == "status":
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
