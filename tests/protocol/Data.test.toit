import lightbug.protocol show *
import log

main:
  addAndget-data
  from-bytes
  from-list
  toBytes

from-bytes:
    // no data fileds
    d := Data.from-bytes #[0x00, 0x00]
    if d.data-field-count != 0:
        log.error "❌ Failed getting data-field-count of empty data, got: " + d.data-field-count.stringify
    else:
        log.info "✅ Passed getting data-field-count of empty data"
    
    // a single uint8 of type 1 value 2
    d = Data.from-bytes #[0x01, 0x00, 0x01, 0x01, 0x02]
    if d.data-field-count != 1:
        log.error "❌ Failed getting data-field-count of single data field, got: " + d.data-field-count.stringify
    else:
        log.info "✅ Passed getting data-field-count of single data field"
    
    // uint8 of type 1 value 2, and 2 bytes of type 5, value 8 8
    d = Data.from-bytes #[0x02, 0x00, 0x01, 0x05, 0x01, 0x02, 0x02, 0x08, 0x08]
    if d.data-field-count != 2:
        log.error "❌ Failed getting data-field-count of 2 data fields, got: " + d.data-field-count.stringify
    else:
        log.info "✅ Passed getting data-field-count of 2 data fields"
  
from-list:
  // no data fileds
  d := Data.from-list [0x00, 0x00]
  if d.data-field-count != 0:
      log.error "❌ LIST Failed getting data-field-count of empty data, got: " + d.data-field-count.stringify
  else:
      log.info "✅ LIST Passed getting data-field-count of empty data"
  
  // a single uint8 of type 1 value 2
  d = Data.from-list [0x01, 0x00, 0x01, 0x01, 0x02]
  if d.data-field-count != 1:
      log.error "❌ LIST Failed getting data-field-count of single data field, got: " + d.data-field-count.stringify
  else:
      log.info "✅ LIST Passed getting data-field-count of single data field"
  
  // uint8 of type 1 value 2, and 2 bytes of type 5, value 8 8
  d = Data.from-list [0x02, 0x00, 0x01, 0x05, 0x01, 0x02, 0x02, 0x08, 0x08]
  if d.data-field-count != 2:
      log.error "❌ LIST Failed getting data-field-count of 2 data fields, got: " + d.data-field-count.stringify
  else:
      log.info "✅ LIST Passed getting data-field-count of 2 data fields"

toBytes:
  d := Data
  d.add-data-uint8 1 6
  b := d.bytes-for-protocol
  if b != #[0x01, 0x00, 0x01, 0x01, 0x06]:
      log.error "❌ Failed toBytes single uint8, got: $b"
  else:
      log.info "✅ Passed toBytes single uint8"
  
  d.add-data 5 #[8, 8]
  b = d.bytes-for-protocol
  if b != #[0x02, 0x00, 0x01, 0x05, 0x01, 0x06, 0x02, 0x08, 0x08]:
      log.error "❌ Failed toBytes 2 data fields, got: $b"
  else:
      log.info "✅ Passed toBytes 2 data fields"

addAndget-data:
  d := Data
  ////////////////
  // Byte Values to bytes
  ////////////////

  // Test uint32
  d.add-data-uint32 1 290
  if (d.get-data 1) != #[0x22, 0x01, 0x00, 0x00]:
      log.error "❌ Failed uint32 byte representation"
  else:
      log.info "✅ Passed uint32 byte representation"

  // Test int32
  d.add-data-int32 2 290
  if (d.get-data 2) != #[0x22, 0x01, 0x00, 0x00]:
      log.error "❌ Failed int32 byte representation"
  else:
      log.info "✅ Passed int32 byte representation"

  // Test float
  d.add-data-float32 3 3.1415927
  got := d.get-data 3
  expect := #[0xdb, 0x0f, 0x49, 0x40]
  if got != expect:
    log.error "❌ Failed float byte representation. Expected: $expect, got: $got"
  else:
    log.info "✅ Passed float byte representation"

  ////////////////
  // Round trips
  ////////////////

  // Test uint32 roundtrip
  d.add-data-uint32 4 290
  if (d.get-data-uint32 4) != 290:
    log.error "❌ Failed uint32 roundtrip"
  else:
    log.info "✅ Passed uint32 roundtrip"
  
  // Test int32 roundtrip
  d.add-data-int32 5 -290
  if (d.get-data-int32 5) != -290:
      log.error "❌ Failed int32 roundtrip"
  else:
      log.info "✅ Passed int32 roundtrip"
  
  // Float roundtrip
  expected := 3.1400001049041748047
  d.add-data-float32 6 expected
  gotFloat := d.get-data-float32 6
  if gotFloat != expected:
      log.error "❌ Failed float roundtrip. Expected: $expected, got: $gotFloat"
  else:
      log.info "✅ Passed float roundtrip"

  // list uint16 roundtrip
  expectedList := [1, 2, 3]
  d.add-data-list-uint16 7 expectedList
  gotList := d.get-data-list-uint16 7
  if gotList != expectedList:
    log.error "❌ Failed list uint16 roundtrip. Expected: $expectedList, got: $gotList"
  else:
    log.info "✅ Passed list uint16 roundtrip"

  // list uint32 roundtrip
  expectedListUint32 := [100000, 200000, 300000]
  d.add-data-list-uint32 8 expectedListUint32
  gotListUint32 := d.get-data-list-uint32 8
  if gotListUint32 != expectedListUint32:
    log.error "❌ Failed list uint32 roundtrip. Expected: $expectedListUint32, got: $gotListUint32"
  else:
    log.info "✅ Passed list uint32 roundtrip"
  
  // list int32 pairs roundtrip
  expectedListInt32Pairs := [[1, 2], [3, 4], [5, 6]]
  d.add-data-list-int32-pairs 9 expectedListInt32Pairs
  gotListInt32Pairs := d.get-data-list-int32-pairs 9
  if gotListInt32Pairs != expectedListInt32Pairs:
      log.error "❌ Failed list int32 pairs roundtrip. Expected: $expectedListInt32Pairs, got: $gotListInt32Pairs"
  else:
      log.info "✅ Passed list int32 pairs roundtrip"
