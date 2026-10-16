import lightbug.apps.relay-wire show RelayWire
import ble
import io.byte-order show LITTLE-ENDIAN

check condition/bool label/string:
  if not condition: throw label

main:
  payloads := [
    "0", "123456789012345:ping", "9223372036854775807:pong",
    "42:51.507351,-0.127758", "7:-90.000000,180.000000",
    "8:90.000000,-180.000000",
  ]
  payloads.do: |text/string|
    data := RelayWire.encode text 65535
    check (data.size == 22) "compact packet length"
    check ((RelayWire.decode data) == text) "round trip $text"
    check ((RelayWire.sequence data) == 65535) "sequence preserved"
    advertisement := ble.Advertisement [
      ble.DataBlock.flags --general-discovery,
      ble.DataBlock.manufacturer-specific data,
    ]
    raw := advertisement.to-raw
    check (raw.size <= 31) "fits legacy advertisement without scan response"
    decoded := null
    (ble.Advertisement.raw raw).manufacturer-specific: |company bytes|
      check (company[0] == 255 and company[1] == 255) "experimental manufacturer id"
      decoded = RelayWire.decode bytes
    check (decoded == text) "advertisement round trip $text"

  check ((RelayWire.sequence (RelayWire.encode "1:ping" 65536)) == 0) "sequence wraps"
  check ((RelayWire.decode #[]) == null) "reject truncated packet"
  data := RelayWire.encode "1:ping" 0
  check ((RelayWire.decode data[0..21]) == null) "reject wrong size"
  data[0] = 0
  check ((RelayWire.decode data) == null) "reject unrelated manufacturer payload"
  data[0] = 0x4c
  data[2] = 2
  check ((RelayWire.decode data) == null) "reject unsupported version"
  data[2] = 1
  data[3] = 4
  check ((RelayWire.decode data) == null) "reject unknown type"
  data[3] = 3
  LITTLE-ENDIAN.put-int32 data 14 91_000_000
  check ((RelayWire.decode data) == null) "reject out-of-range coordinate"
  invalid := ["-1:ping", "1:hello", "1:ping:extra", "1:91,0", "1:nan,0"]
  invalid.do: |text/string|
    e := catch: RelayWire.encode text 0
    check (e != null) "reject $text"
  print "Relay wire tests passed"
