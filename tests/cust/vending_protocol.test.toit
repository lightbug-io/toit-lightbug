import lightbug.cust.vending_protocol show VendingProtocol

main:
  vending-id-from-current-id
  vending-id-from-serial
  build-command-frame-get-stat
  parse-command-frame-get-stat
  parse-command-frame-invalid-checksum
  parse-command-frame-invalid-length
  parse-command-frame-invalid-terminator
  build-response-frame-get-stat-success
  build-response-frame-get-stat-negative-temp
  build-response-frame-get-stat-fail-with-extra-data
  build-response-frame-direct-fail
  ignore-unsupported-commands

vending-id-from-current-id:
  got := VendingProtocol.vending-id-from-current-id 0x12345678
  expected := 0x1b12345678
  if got != expected:
    print "❌ vending-id-from-current-id. Expected: $expected, got: $got"
  else:
    print "✅ vending-id-from-current-id"

vending-id-from-serial:
  // Mirrors C++ logic: serial % 1_000_000 into low 4 bytes with 0x2B prefix.
  got := VendingProtocol.vending-id-from-serial 12_345_678
  expected := 0x2b0005464e
  if got != expected:
    print "❌ vending-id-from-serial. Expected: $expected, got: $got"
  else:
    print "✅ vending-id-from-serial"

build-command-frame-get-stat:
  got := VendingProtocol.build-command-frame VendingProtocol.Cmd_GetStat
  // C++ equivalent: expectedLen=4 (cmd + xor + \r\n), xor=0x98.
  expected := #[0x3e, 0x04, 0xa2, 0x98, 0x0d, 0x0a]
  if got != expected:
    print "❌ build-command-frame-get-stat. Expected: $expected, got: $got"
  else:
    print "✅ build-command-frame-get-stat"

parse-command-frame-get-stat:
  frame := #[0x3e, 0x04, 0xa2, 0x98, 0x0d, 0x0a]
  got := VendingProtocol.command-payload-from-frame frame
  expected := #[0xa2, 0x98]
  if got != expected:
    print "❌ parse-command-frame-get-stat. Expected: $expected, got: $got"
  else:
    print "✅ parse-command-frame-get-stat"

parse-command-frame-invalid-checksum:
  frame := #[0x3e, 0x04, 0xa2, 0x00, 0x0d, 0x0a]
  got := VendingProtocol.command-payload-from-frame frame
  if got != null:
    print "❌ parse-command-frame-invalid-checksum. Expected null, got: $got"
  else:
    print "✅ parse-command-frame-invalid-checksum"

parse-command-frame-invalid-length:
  // Length should be 4 for this payload; declare 5 to force rejection.
  frame := #[0x3e, 0x05, 0xa2, 0x98, 0x0d, 0x0a]
  got := VendingProtocol.command-payload-from-frame frame
  if got != null:
    print "❌ parse-command-frame-invalid-length. Expected null, got: $got"
  else:
    print "✅ parse-command-frame-invalid-length"

parse-command-frame-invalid-terminator:
  frame := #[0x3e, 0x04, 0xa2, 0x98, 0x0a, 0x0d]
  got := VendingProtocol.command-payload-from-frame frame
  if got != null:
    print "❌ parse-command-frame-invalid-terminator. Expected null, got: $got"
  else:
    print "✅ parse-command-frame-invalid-terminator"

build-response-frame-get-stat-success:
  request := #[0x3e, 0x04, 0xa2, 0x98, 0x0d, 0x0a]
  got := VendingProtocol.response-for-command-frame request 0x1b00000000 20 3.7
  expected := #[
    0x3e,
    0x0e,
    0xb2,
    0xf1,
    0x00,
    0x00,
    0x00,
    0x00,
    0x1b,
    0x00,
    0x14,
    0x44,
    0x03,
    0x3b,
    0x0d,
    0x0a,
  ]
  if got != expected:
    print "❌ build-response-frame-get-stat-success. Expected: $expected, got: $got"
  else:
    print "✅ build-response-frame-get-stat-success"

build-response-frame-get-stat-negative-temp:
  request := #[0x3e, 0x04, 0xa2, 0x98, 0x0d, 0x0a]
  got := VendingProtocol.response-for-command-frame request 0x1b00000000 -1 3.7
  // C++ casts temperature to int8_t, so -1 becomes 0xFF in the payload.
  expected := #[
    0x3e,
    0x0e,
    0xb2,
    0xf1,
    0x00,
    0x00,
    0x00,
    0x00,
    0x1b,
    0x00,
    0xff,
    0x44,
    0x03,
    0xd0,
    0x0d,
    0x0a,
  ]
  if got != expected:
    print "❌ build-response-frame-get-stat-negative-temp. Expected: $expected, got: $got"
  else:
    print "✅ build-response-frame-get-stat-negative-temp"

build-response-frame-get-stat-fail-with-extra-data:
  request := #[0x3e, 0x05, 0xa2, 0x01, 0x98, 0x0d, 0x0a]
  got := VendingProtocol.response-for-command-frame request 0x1b00000000 20 3.7
  expected := #[0x3e, 0x05, 0xb2, 0xf2, 0x7b, 0x0d, 0x0a]
  if got != expected:
    print "❌ build-response-frame-get-stat-fail-with-extra-data. Expected: $expected, got: $got"
  else:
    print "✅ build-response-frame-get-stat-fail-with-extra-data"

build-response-frame-direct-fail:
  got := VendingProtocol.build-response-frame VendingProtocol.Res_GetStat VendingProtocol.Stat_Fail
  expected := #[0x3e, 0x05, 0xb2, 0xf2, 0x7b, 0x0d, 0x0a]
  if got != expected:
    print "❌ build-response-frame-direct-fail. Expected: $expected, got: $got"
  else:
    print "✅ build-response-frame-direct-fail"

ignore-unsupported-commands:
  request := VendingProtocol.build-command-frame VendingProtocol.Cmd_SetId #[0x10, 0x20]
  got := VendingProtocol.response-for-command-frame request 0x1b00000000 20 3.7
  if got != null:
    print "❌ ignore-unsupported-commands. Expected null, got: $got"
  else:
    print "✅ ignore-unsupported-commands"