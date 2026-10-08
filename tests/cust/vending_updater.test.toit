import lightbug.cust.vending_updater show VendingUpdater
import lightbug.cust.vending_protocol show VendingProtocol
import lightbug.messages as messages
import lightbug.protocol as protocol

assert-eq label/string got want:
  if got != want:
    throw "$label failed. Got=$got Want=$want"

// Hardware-free cache implementing the updater's vending operations.
class FakeVending:
  vending-id := 0x1B00000000
  temperature := 20.0
  voltage := 3.7

  update-vending-id-from-current-id id/int -> int:
    vending-id = VendingProtocol.vending-id-from-current-id id
    return vending-id

  update-vending-id-from-serial serial/int -> int:
    vending-id = VendingProtocol.vending-id-from-serial serial
    return vending-id

  update-cache --temperature/float?=null --voltage/float?=null:
    if temperature != null: this.temperature = temperature
    if voltage != null: this.voltage = voltage

class FakeLatch:
  response := null
  fail := false
  constructor .response --.fail=false:
  get:
    if fail: throw "request timeout"
    return response

class FakeComms:
  response := null
  fail := false
  send-fails := false
  requests := []
  constructor .response:
  send msg --withLatch --now --timeout:
    assert-eq "request latch" withLatch true
    assert-eq "immediate request" now true
    assert-eq "request timeout" timeout.in-ms 10_000
    requests.add msg.type
    if send-fails: throw "send failed"
    if msg.type == messages.Temperature.MT:
      return FakeLatch (protocol.Message.with-data messages.Temperature.MT (messages.Temperature.data --temperature=25.0))
    if msg.type == messages.BatteryStatus.MT:
      return FakeLatch (protocol.Message.with-data messages.BatteryStatus.MT (messages.BatteryStatus.data --voltage=4.0 --percent=80))
    return FakeLatch response --fail=fail

ids --serial/int?=null --id/int?=null:
  return protocol.Message.with-data messages.DeviceIDs.MT (messages.DeviceIDs.data --serial=serial --id=id)

main:
  fallback-keeps-retrying
  fallback-survives-bad-replies
  last-good-survives-bad-replies
  later-serial-and-zero-suffix
  every-cycle-refreshes-all-fields
  print "Vending updater tests passed"

fallback-keeps-retrying:
  updater := VendingUpdater
  vending := FakeVending
  comms := FakeComms null
  updater.update-device-id comms vending
  assert-eq "no response leaves default" vending.vending-id 0x1B00000000
  comms.response = ids --serial=0 --id=123
  updater.update-device-id comms vending
  assert-eq "zero serial uses current ID" vending.vending-id 0x1B0000007B
  comms.response = ids --id=456
  updater.update-device-id comms vending
  assert-eq "absent serial uses current ID" vending.vending-id 0x1B000001C8
  comms.response = ids --serial=12_345_678
  updater.update-device-id comms vending
  assert-eq "fallback recovers to serial" vending.vending-id 0x2B0005464E
  assert-eq "all calls request IDs" comms.requests.size 4

fallback-survives-bad-replies:
  updater := VendingUpdater
  vending := FakeVending
  comms := FakeComms (ids --id=456)
  updater.update-device-id comms vending
  bad := [null, ids, ids --id=0, protocol.Message 0]
  error := ids --serial=123
  error.header-add-data-int8 protocol.Header.TYPE_MESSAGE_STATUS protocol.Header.STATUS_GENERIC_ERROR
  bad.add error
  data := messages.DeviceIDs.data --id=999
  data.add-data messages.DeviceIDs.SERIAL #[]
  bad.add (protocol.Message.with-data messages.DeviceIDs.MT data)
  bad.do: | response |
    comms.response = response
    updater.update-device-id comms vending
    assert-eq "bad reply preserves fallback" vending.vending-id 0x1B000001C8
  comms.response = ids --serial=1_234_567
  updater.update-device-id comms vending
  assert-eq "fallback still recovers" vending.vending-id (VendingProtocol.vending-id-from-serial 1_234_567)

last-good-survives-bad-replies:
  vending := FakeVending
  comms := FakeComms (ids --serial=12_345_678)
  (VendingUpdater).update-device-id comms vending
  expected := vending.vending-id
  // A fresh updater must preserve the same cached serial too.
  updater := VendingUpdater
  bad := [null, ids, ids --id=999, ids --serial=0 --id=999]
  bad.add (protocol.Message 0) // ACK/unrelated type.
  bad.add (protocol.Message.with-data messages.Temperature.MT (messages.DeviceIDs.data --serial=123))
  error := ids --serial=123
  error.header-add-data-int8 protocol.Header.TYPE_MESSAGE_STATUS protocol.Header.STATUS_GENERIC_ERROR
  bad.add error
  [#[], #[1, 2, 3, 4, 5, 6, 7, 8, 9]].do: | bytes |
    data := messages.DeviceIDs.data --id=999
    data.add-data messages.DeviceIDs.SERIAL bytes
    bad.add (protocol.Message.with-data messages.DeviceIDs.MT data)
  // Structurally truncated data section: parsing throws before mutation.
  bad.add (protocol.Message.from-bytes #[3, 12, 0, 35, 0, 0, 0, 2, 0, 4, 0, 0])
  bad.do: | response |
    comms.response = response
    updater.update-device-id comms vending
    assert-eq "bad reply preserves serial" vending.vending-id expected
  comms.fail = true
  updater.update-device-id comms vending
  assert-eq "timeout preserves serial" vending.vending-id expected
  comms.fail = false
  comms.send-fails = true
  updater.update-device-id comms vending
  assert-eq "send failure preserves serial" vending.vending-id expected
  assert-eq "bad replies all retried" comms.requests.size (bad.size + 3)

later-serial-and-zero-suffix:
  updater := VendingUpdater
  vending := FakeVending
  comms := FakeComms (ids --serial=12_345_678)
  updater.update-device-id comms vending
  comms.response = ids --serial=1_000_000
  updater.update-device-id comms vending
  assert-eq "later valid serial with zero suffix" vending.vending-id 0x2B00000000
  comms.response = ids --serial=0 --id=999
  updater.update-device-id comms vending
  assert-eq "zero suffix is still a serial" vending.vending-id 0x2B00000000
  comms.response = ids --serial=2_000_001
  updater.update-device-id comms vending
  assert-eq "later serial change" vending.vending-id 0x2B00000001

every-cycle-refreshes-all-fields:
  updater := VendingUpdater
  vending := FakeVending
  comms := FakeComms (ids --serial=12_345_678)
  3.repeat:
    updater.update-vending-cache-from-device comms vending
  assert-eq "one request per field per cycle" comms.requests.size 9
  3.repeat: | cycle |
    assert-eq "IDs in every cycle" comms.requests[cycle * 3] messages.DeviceIDs.MT
    assert-eq "temperature in every cycle" comms.requests[cycle * 3 + 1] messages.Temperature.MT
    assert-eq "battery in every cycle" comms.requests[cycle * 3 + 2] messages.BatteryStatus.MT
  assert-eq "temperature refreshed" vending.temperature 25.0
  assert-eq "voltage refreshed" vending.voltage 4.0
  comms.fail = true
  updater.update-vending-cache-from-device comms vending
  assert-eq "ID failure still permits other fields" comms.requests.size 12
