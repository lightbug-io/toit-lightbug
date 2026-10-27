import io
import lightbug.messages as messages
import lightbug.protocol as protocol
import lightbug.cust.vending_protocol show VendingProtocol
import ...examples.host.vending.peer show read-device-ids decode-device-ids read-response read-v3-response qc-open-request cloud-link-request VendingPeer

main:
  request := messages.DeviceIDs.get-msg
  request.header-add-data-uint32 protocol.Header.TYPE_MESSAGE_ID 7
  ids := messages.DeviceIDs.data --id=19314686 --serial=12345678
  response := protocol.Message.with-data messages.DeviceIDs.MT ids
  response.header-add-data-uint32 protocol.Header.TYPE_RESPONSE_TO_MESSAGE_ID 7
  unrelated := protocol.Message.from-bytes response.bytes
  unrelated.header-remove-data protocol.Header.TYPE_RESPONSE_TO_MESSAGE_ID
  unrelated.header-add-data-uint32 protocol.Header.TYPE_RESPONSE_TO_MESSAGE_ID 6
  ack := messages.ACK.msg --data=null
  ack.header-add-data-uint32 protocol.Header.TYPE_RESPONSE_TO_MESSAGE_ID 7
  vending := VendingProtocol.build-command-frame VendingProtocol.Cmd_GetStat
  wire := (prefix request) + vending + (prefix unrelated) + (prefix ack) + (prefix response)
  events := []
  received := read-device-ids (io.Reader wire) 7 request.bytes events Time.monotonic-us
  decoded := decode-device-ids received
  check "full ID" decoded["id"] 19314686
  check "full serial" decoded["serial"] 12345678
  check "missing IMEI" decoded["imei"] null
  check "echo recorded" events[0]["kind"] "adapter echo"
  check "unrelated frames retained in log" events.size 5
  rejected := protocol.Message.from-bytes ack.bytes
  rejected.header-add-data-uint8 protocol.Header.TYPE_MESSAGE_STATUS protocol.Header.STATUS_NOT_SUPPORTED
  error := catch: read-device-ids (io.Reader (prefix rejected)) 7 request.bytes [] Time.monotonic-us
  if error == null: throw "Negative ACK was accepted"
  // V3 payload may contain a vending header; legacy reads must skip it whole.
  noise := protocol.Message.with-data 123 (messages.DeviceIDs.data --imei=">1234")
  status := VendingProtocol.response-for-command-frame vending 115983431678 20 3.7
  legacy := read-response (io.Reader ((prefix noise) + status)) VendingProtocol.Res_GetStat [] Time.monotonic-us
  check "legacy response after V3" legacy["payload"][0] VendingProtocol.Res_GetStat
  open := qc-open-request
  check "QC Open targets cloud" (open.header-get-data-uint protocol.Header.TYPE_FORWARD_TO) 0
  check "QC app" (open.header-get-data-ascii 50) "qc"
  check "QC expiry" (open.header-get-data-ascii 51) "day"
  enable := cloud-link-request
  check "cloud link enabled" (messages.LinkControl.from-data enable.data).enable true
  check "link control targets P1" (enable.header-get-data-uint protocol.Header.TYPE_FORWARD_TO) 3
  local-ack := protocol.Message.from-bytes ack.bytes
  local-ack.header-add-data-uint8 protocol.Header.TYPE_FORWARDED_FOR 3
  server-ack := protocol.Message.from-bytes ack.bytes
  server-ack.header-add-data-uint8 protocol.Header.TYPE_FORWARDED_FOR 0
  // The server does not copy app=qc onto its ACK. Require matching correlation
  // and cloud origin, ignoring the same-ID P1 ACK and the adapter echo.
  events = []
  accepted := read-v3-response (io.Reader ((prefix open) + (prefix local-ack) + (prefix server-ack))) 7 open.bytes messages.ACK.MT events Time.monotonic-us --cloud=true
  check "cloud ACK without app header" accepted.forwarded-for 0
  check "P1 receipt not accepted as cloud ACK" events.size 3
  check "cloud ACK classified" events[2]["kind"] "server response"
  success := SimulatedPeer
  success.run-qc_
  check "QC stages complete" success.requests.size 5
  check "QC server acknowledged" success.qc_["acknowledged"] true
  failed := SimulatedPeer --fail-at=2
  failed.run-qc_
  check "failed enable stops before server Open" failed.requests.size 3
  check "failed setup not acknowledged" failed.qc_["acknowledged"] false
  if not failed.qc_.contains "error": throw "Setup failure not reported"
  retrying := SimulatedPeer --cloud-timeouts=1
  retrying.run-qc_
  check "missing cloud ACK retried" retrying.cloud-attempts 2
  check "retry acknowledgement reported" retrying.qc_["acknowledged"] true
  timed-out := SimulatedPeer --cloud-timeouts=6
  timed-out.run-qc_
  check "cloud retries bounded" timed-out.cloud-attempts 6
  check "timeout not shown as acknowledgement" timed-out.qc_["acknowledged"] false
  if not timed-out.qc_.contains "error": throw "Cloud timeout not reported"
  print "Vending host V3 tests passed"

prefix message/protocol.Message -> ByteArray:
  return #[0x4c, 0x42] + message.bytes

check label/string actual expected:
  if actual != expected: throw "$label: expected $expected, got $actual"

class SimulatedPeer extends VendingPeer:
  requests /List := []
  fail-at_ /int
  cloud-timeouts_ /int
  cloud-attempts /int := 0
  constructor --fail-at/int=-1 --cloud-timeouts/int=0:
    fail-at_ = fail-at
    cloud-timeouts_ = cloud-timeouts
    qc_ = {"acknowledged": false}
  exchange-v3_ label/string request/protocol.Message expected/int --cloud/bool=false --timeout-ms/int=5000 -> protocol.Message?:
    requests.add request
    if cloud:
      cloud-attempts++
      if cloud-attempts <= cloud-timeouts_:
        history_.add {"outcome": "timeout"}
        return null
    if requests.size - 1 == fail-at_: return null
    if expected == messages.DeviceIDs.MT:
      return protocol.Message.with-data expected (messages.DeviceIDs.data --id=1234)
    return messages.ACK.msg --data=null
