import lightbug.protocol show *

main:
  addAndget-data
  from-bytes
  from-list
  toBytes

from-bytes:
    // no data fileds
    d := Data.from-bytes #[0x00, 0x00]
    if d.data-field-count != 0:
        print "❌ Failed getting data-field-count of empty data, got: " + d.data-field-count.stringify
    else:
        print "✅ Passed getting data-field-count of empty data"
    
    // a single uint8 of type 1 value 2
    d = Data.from-bytes #[0x01, 0x00, 0x01, 0x01, 0x02]
    if d.data-field-count != 1:
        print "❌ Failed getting data-field-count of single data field, got: " + d.data-field-count.stringify
    else:
        print "✅ Passed getting data-field-count of single data field"
    
    // uint8 of type 1 value 2, and 2 bytes of type 5, value 8 8
    d = Data.from-bytes #[0x02, 0x00, 0x01, 0x05, 0x01, 0x02, 0x02, 0x08, 0x08]
    if d.data-field-count != 2:
        print "❌ Failed getting data-field-count of 2 data fields, got: " + d.data-field-count.stringify
    else:
        print "✅ Passed getting data-field-count of 2 data fields"
  
from-list:
  // no data fileds
  d := Data.from-list [0x00, 0x00]
  if d.data-field-count != 0:
      print "❌ LIST Failed getting data-field-count of empty data, got: " + d.data-field-count.stringify
  else:
      print "✅ LIST Passed getting data-field-count of empty data"
  
  // a single uint8 of type 1 value 2
  d = Data.from-list [0x01, 0x00, 0x01, 0x01, 0x02]
  if d.data-field-count != 1:
      print "❌ LIST Failed getting data-field-count of single data field, got: " + d.data-field-count.stringify
  else:
      print "✅ LIST Passed getting data-field-count of single data field"
  
  // uint8 of type 1 value 2, and 2 bytes of type 5, value 8 8
  d = Data.from-list [0x02, 0x00, 0x01, 0x05, 0x01, 0x02, 0x02, 0x08, 0x08]
  if d.data-field-count != 2:
      print "❌ LIST Failed getting data-field-count of 2 data fields, got: " + d.data-field-count.stringify
  else:
      print "✅ LIST Passed getting data-field-count of 2 data fields"

toBytes:
  d := Data
  d.add-data-uint8 1 6
  b := d.bytes-for-protocol
  if b != #[0x01, 0x00, 0x01, 0x01, 0x06]:
      print "❌ Failed toBytes single uint8, got: $b"
  else:
      print "✅ Passed toBytes single uint8"
  
  d.add-data 5 #[8, 8]
  b = d.bytes-for-protocol
  if b != #[0x02, 0x00, 0x01, 0x05, 0x01, 0x06, 0x02, 0x08, 0x08]:
      print "❌ Failed toBytes 2 data fields, got: $b"
  else:
      print "✅ Passed toBytes 2 data fields"

addAndget-data:
  d := Data
  ////////////////
  // Byte Values to bytes
  ////////////////

  // Test uint32
  d.add-data-uint32 1 290
  if (d.get-data 1) != #[0x22, 0x01, 0x00, 0x00]:
      print "❌ Failed uint32 byte representation"
  else:
      print "✅ Passed uint32 byte representation"

  // Test int32
  d.add-data-int32 2 290
  if (d.get-data 2) != #[0x22, 0x01, 0x00, 0x00]:
      print "❌ Failed int32 byte representation"
  else:
      print "✅ Passed int32 byte representation"

  // Test float
  d.add-data-float32 3 3.1415927
  got := d.get-data 3
  expect := #[0xdb, 0x0f, 0x49, 0x40]
  if got != expect:
    print "❌ Failed float byte representation. Expected: $expect, got: $got"
  else:
    print "✅ Passed float byte representation"

  ////////////////
  // Round trips
  ////////////////

  // Test uint32 roundtrip
  d.add-data-uint32 4 290
  if (d.get-data-uint32 4) != 290:
    print "❌ Failed uint32 roundtrip"
  else:
    print "✅ Passed uint32 roundtrip"
  
  // Test int32 roundtrip
  d.add-data-int32 5 -290
  if (d.get-data-int32 5) != -290:
      print "❌ Failed int32 roundtrip"
  else:
      print "✅ Passed int32 roundtrip"
  
  // Float roundtrip
  expected := 3.1400001049041748047
  d.add-data-float32 6 expected
  gotFloat := d.get-data-float32 6
  if gotFloat != expected:
      print "❌ Failed float roundtrip. Expected: $expected, got: $gotFloat"
  else:
      print "✅ Passed float roundtrip"

  // list uint16 roundtrip
  expectedList := [1, 2, 3]
  d.add-data-list-uint16 7 expectedList
  gotList := d.get-data-list-uint16 7
  if gotList != expectedList:
    print "❌ Failed list uint16 roundtrip. Expected: $expectedList, got: $gotList"
  else:
    print "✅ Passed list uint16 roundtrip"

  // list uint32 roundtrip
  expectedListUint32 := [100000, 200000, 300000]
  d.add-data-list-uint32 8 expectedListUint32
  gotListUint32 := d.get-data-list-uint32 8
  if gotListUint32 != expectedListUint32:
    print "❌ Failed list uint32 roundtrip. Expected: $expectedListUint32, got: $gotListUint32"
  else:
    print "✅ Passed list uint32 roundtrip"
  
  // list int32 pairs roundtrip
  expectedListInt32Pairs := [[1, 2], [3, 4], [5, 6]]
  d.add-data-list-int32-pairs 9 expectedListInt32Pairs
  gotListInt32Pairs := d.get-data-list-int32-pairs 9
  if gotListInt32Pairs != expectedListInt32Pairs:
      print "❌ Failed list int32 pairs roundtrip. Expected: $expectedListInt32Pairs, got: $gotListInt32Pairs"
  else:
      print "✅ Passed list int32 pairs roundtrip"
