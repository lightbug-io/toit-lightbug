import lightbug.protocol show *
import log

main:
  addAndGetData
  fromBytes
  fromList
  toBytes

fromBytes:
    // no data fileds
    d := Data.fromBytes #[0x00, 0x00]
    if d.dataFieldCount != 0:
        log.error "❌ Failed getting dataFieldCount of empty data, got: " + d.dataFieldCount.stringify
    else:
        log.info "✅ Passed getting dataFieldCount of empty data"
    
    // a single uint8 of type 1 value 2
    d = Data.fromBytes #[0x01, 0x00, 0x01, 0x01, 0x02]
    if d.dataFieldCount != 1:
        log.error "❌ Failed getting dataFieldCount of single data field, got: " + d.dataFieldCount.stringify
    else:
        log.info "✅ Passed getting dataFieldCount of single data field"
    
    // uint8 of type 1 value 2, and 2 bytes of type 5, value 8 8
    d = Data.fromBytes #[0x02, 0x00, 0x01, 0x05, 0x01, 0x02, 0x02, 0x08, 0x08]
    if d.dataFieldCount != 2:
        log.error "❌ Failed getting dataFieldCount of 2 data fields, got: " + d.dataFieldCount.stringify
    else:
        log.info "✅ Passed getting dataFieldCount of 2 data fields"
  
fromList:
  // no data fileds
  d := Data.fromList [0x00, 0x00]
  if d.dataFieldCount != 0:
      log.error "❌ LIST Failed getting dataFieldCount of empty data, got: " + d.dataFieldCount.stringify
  else:
      log.info "✅ LIST Passed getting dataFieldCount of empty data"
  
  // a single uint8 of type 1 value 2
  d = Data.fromList [0x01, 0x00, 0x01, 0x01, 0x02]
  if d.dataFieldCount != 1:
      log.error "❌ LIST Failed getting dataFieldCount of single data field, got: " + d.dataFieldCount.stringify
  else:
      log.info "✅ LIST Passed getting dataFieldCount of single data field"
  
  // uint8 of type 1 value 2, and 2 bytes of type 5, value 8 8
  d = Data.fromList [0x02, 0x00, 0x01, 0x05, 0x01, 0x02, 0x02, 0x08, 0x08]
  if d.dataFieldCount != 2:
      log.error "❌ LIST Failed getting dataFieldCount of 2 data fields, got: " + d.dataFieldCount.stringify
  else:
      log.info "✅ LIST Passed getting dataFieldCount of 2 data fields"

toBytes:
  d := Data
  d.addDataUint8 1 6
  b := d.bytesForProtocol
  if b != #[0x01, 0x00, 0x01, 0x01, 0x06]:
      log.error "❌ Failed toBytes single uint8, got: $b"
  else:
      log.info "✅ Passed toBytes single uint8"
  
  d.addData 5 #[8, 8]
  b = d.bytesForProtocol
  if b != #[0x02, 0x00, 0x01, 0x05, 0x01, 0x06, 0x02, 0x08, 0x08]:
      log.error "❌ Failed toBytes 2 data fields, got: $b"
  else:
      log.info "✅ Passed toBytes 2 data fields"

addAndGetData:
  d := Data
  ////////////////
  // Byte Values to bytes
  ////////////////

  // Test uint32
  d.addDataUint32 1 290
  if (d.getData 1) != #[0x22, 0x01, 0x00, 0x00]:
      log.error "❌ Failed uint32 byte representation"
  else:
      log.info "✅ Passed uint32 byte representation"

  // Test int32
  d.addDataInt32 2 290
  if (d.getData 2) != #[0x22, 0x01, 0x00, 0x00]:
      log.error "❌ Failed int32 byte representation"
  else:
      log.info "✅ Passed int32 byte representation"

  // Test float
  d.addDataFloat 3 3.1415927
  got := d.getData 3
  expect := #[0xdb, 0x0f, 0x49, 0x40]
  if got != expect:
    log.error "❌ Failed float byte representation. Expected: $expect, got: $got"
  else:
    log.info "✅ Passed float byte representation"

  ////////////////
  // Round trips
  ////////////////

  // Test uint32 roundtrip
  d.addDataUint32 4 290
  if (d.getDataUint32 4) != 290:
    log.error "❌ Failed uint32 roundtrip"
  else:
    log.info "✅ Passed uint32 roundtrip"
  
  // Test int32 roundtrip
  d.addDataInt32 5 -290
  if (d.getDataInt32 5) != -290:
      log.error "❌ Failed int32 roundtrip"
  else:
      log.info "✅ Passed int32 roundtrip"
  
  // Float roundtrip
  expected := 3.1400001049041748047
  d.addDataFloat 6 expected
  gotFloat := d.getDataFloat 6
  if gotFloat != expected:
      log.error "❌ Failed float roundtrip. Expected: $expected, got: $gotFloat"
  else:
      log.info "✅ Passed float roundtrip"

  // list uint16 roundtrip
  expectedList := [1, 2, 3]
  d.addDataListUint16 7 expectedList
  gotList := d.getDataListUint16 7
  if gotList != expectedList:
    log.error "❌ Failed list uint16 roundtrip. Expected: $expectedList, got: $gotList"
  else:
    log.info "✅ Passed list uint16 roundtrip"

  // list uint32 roundtrip
  expectedListUint32 := [100000, 200000, 300000]
  d.addDataListUint32 8 expectedListUint32
  gotListUint32 := d.getDataListUint32 8
  if gotListUint32 != expectedListUint32:
    log.error "❌ Failed list uint32 roundtrip. Expected: $expectedListUint32, got: $gotListUint32"
  else:
    log.info "✅ Passed list uint32 roundtrip"
  
  // list int32 pairs roundtrip
  expectedListInt32Pairs := [[1, 2], [3, 4], [5, 6]]
  d.addDataListInt32Pairs 9 expectedListInt32Pairs
  gotListInt32Pairs := d.getDataListInt32Pairs 9
  if gotListInt32Pairs != expectedListInt32Pairs:
      log.error "❌ Failed list int32 pairs roundtrip. Expected: $expectedListInt32Pairs, got: $gotListInt32Pairs"
  else:
      log.info "✅ Passed list int32 pairs roundtrip"
