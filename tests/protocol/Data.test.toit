import io.byte-order show LITTLE-ENDIAN
import lightbug.protocol show *
import lightbug.protocol.data show list-to-byte-array

main:
    addAndget-data
    from-bytes
    from-bytes-list-equivalents
    toBytes
    add-get-roundtrips

assert-eq label/string got want -> none:
  if got != want:
    throw "$label failed. Got=$got Want=$want"

assert-eq-bytes label/string got/ByteArray want/ByteArray -> none:
  if got != want:
    throw "$label failed. Got=$got Want=$want"

assert-near label/string got/float want/float -> none:
  diff := got - want
  if diff < 0: diff = -diff
  if diff > 0.000001:
    throw "$label failed. Got=$got Want=$want"

coordinate-bytes lat-int/int lon-int/int -> ByteArray:
  b := ByteArray 8
  LITTLE-ENDIAN.put-int32 b 0 lat-int
  LITTLE-ENDIAN.put-int32 b 4 lon-int
  return b

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
  
from-bytes-list-equivalents:
  // no data fields
  b0 := ByteArray 2
  b0[0] = 0x00
  b0[1] = 0x00
  d := Data.from-bytes b0
  if d.data-field-count != 0:
      print "❌ Failed getting data-field-count of empty data (from-bytes), got: " + d.data-field-count.stringify
  else:
      print "✅ Passed getting data-field-count of empty data (from-bytes)"

  // a single uint8 of type 1 value 2
  b1 := ByteArray 5
  b1[0] = 0x01
  b1[1] = 0x00
  b1[2] = 0x01
  b1[3] = 0x01
  b1[4] = 0x02
  d = Data.from-bytes b1
  if d.data-field-count != 1:
      print "❌ Failed getting data-field-count of single data field (from-bytes), got: " + d.data-field-count.stringify
  else:
      print "✅ Passed getting data-field-count of single data field (from-bytes)"

  // uint8 of type 1 value 2, and 2 bytes of type 5, value 8 8
  b2 := ByteArray 9
  b2[0] = 0x02
  b2[1] = 0x00
  b2[2] = 0x01
  b2[3] = 0x05
  b2[4] = 0x01
  b2[5] = 0x02
  b2[6] = 0x02
  b2[7] = 0x08
  b2[8] = 0x08
  d = Data.from-bytes b2
  if d.data-field-count != 2:
      print "❌ Failed getting data-field-count of 2 data fields (from-bytes), got: " + d.data-field-count.stringify
  else:
      print "✅ Passed getting data-field-count of 2 data fields (from-bytes)"

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

add-get-roundtrips:
  d := Data

  assert-eq "empty size" d.size 2
  assert-eq "empty data-field-count" d.data-field-count 0
  assert-eq-bytes "missing get-data" (d.get-data 250) #[]

  d.add-data-string 10 "hello"
  assert-eq "add-data-string/get-data-ascii" (d.get-data-ascii 10) "hello"

  d.add-data-ascii 11 "ascii"
  assert-eq "add-data-ascii/get-data-ascii" (d.get-data-ascii 11) "ascii"

  d.add-data-uint8 12 0x7f
  assert-eq "add-data-uint8/get-data-uint8" (d.get-data-uint8 12) 0x7f

  d.add-data-uint16 13 0x1234
  assert-eq "add-data-uint16/get-data-uint16" (d.get-data-uint16 13) 0x1234

  d.add-data-uint32 14 0x12345678
  assert-eq "add-data-uint32/get-data-uint32" (d.get-data-uint32 14) 0x12345678

  d.add-data-int8 15 -2
  assert-eq "add-data-int8/get-data-intn" (d.get-data-intn 15) -2
  assert-eq "get-data-int alias" (d.get-data-int 15) -2

  d.add-data-int32 16 -123456
  assert-eq "add-data-int32/get-data-int32" (d.get-data-int32 16) -123456

  d.add-data-uint64 17 0x0102030405060708
  assert-eq "add-data-uint64/get-data-uint64" (d.get-data-uint64 17) 0x0102030405060708

  d.add-data-uint 18 0xfe
  assert-eq "add-data-uint uint8/get-data-uint" (d.get-data-uint 18) 0xfe

  d.add-data-uint 19 0x1234
  assert-eq "add-data-uint uint16/get-data-uint" (d.get-data-uint 19) 0x1234

  d.add-data-uint 20 0x12345678
  assert-eq "add-data-uint uint32/get-data-uint" (d.get-data-uint 20) 0x12345678

  d.add-data-uint 21 0x0102030405
  assert-eq "add-data-uint uint64/get-data-uint" (d.get-data-uint 21) 0x0102030405

  d.add-data-float 22 3.5
  assert-eq "add-data-float/get-data-float" (d.get-data-float 22) 3.5

  d.add-data-float32 23 1.25
  assert-eq "add-data-float32/get-data-float32" (d.get-data-float32 23) 1.25

  d.add-data-bool 24 true
  assert-eq "add-data-bool/get-data-bool true" (d.get-data-bool 24) true

  d.add-data-bool 25 false
  assert-eq "add-data-bool/get-data-bool false" (d.get-data-bool 25) false

  d.add-data-list-uint16 26 [0x1234, 0xabcd]
  assert-eq "add-data-list-uint16/get-data-list-uint16" (d.get-data-list-uint16 26) [0x1234, 0xabcd]

  d.add-data-list-uint32 27 [0x12345678, 0x87654321]
  assert-eq "add-data-list-uint32/get-data-list-uint32" (d.get-data-list-uint32 27) [0x12345678, 0x87654321]

  d.add-data-list-float32 28 [1.25, 2.5]
  float-list-bytes := d.get-data 28
  assert-eq "add-data-list-float32 byte size" float-list-bytes.size 8
  assert-eq "add-data-list-float32 first" (LITTLE-ENDIAN.float32 float-list-bytes 0) 1.25
  assert-eq "add-data-list-float32 second" (LITTLE-ENDIAN.float32 float-list-bytes 4) 2.5

  d.add-data-list-int32-pairs 29 [[-1, 2], [3, -4]]
  assert-eq "add-data-list-int32-pairs/get-data-list-int32-pairs" (d.get-data-list-int32-pairs 29) [[-1, 2], [3, -4]]

  d.add-data 30 (coordinate-bytes 123456789 -987654321)
  c := d.get-data-coordinate 30
  assert-near "get-data-coordinate lat" c.lat 12.3456789
  assert-near "get-data-coordinate lon" c.lon -98.7654321

  coords := (coordinate-bytes 10000000 20000000) + (coordinate-bytes -30000000 40000000)
  d.add-data 31 coords
  got-coords := d.get-data-list-coordinates 31
  assert-eq "get-data-list-coordinates size" got-coords.size 2
  assert-near "get-data-list-coordinates first lat" got-coords[0].lat 1.0
  assert-near "get-data-list-coordinates first lon" got-coords[0].lon 2.0
  assert-near "get-data-list-coordinates second lat" got-coords[1].lat -3.0
  assert-near "get-data-list-coordinates second lon" got-coords[1].lon 4.0

  assert-eq "has-data true" (d.has-data 12) true
  assert-eq "has-data false" (d.has-data 200) false

  before-size := d.size
  d.remove-data 12
  assert-eq "remove-data removes field" (d.has-data 12) false
  assert-eq "remove-data updates size" d.size (before-size - 2 - 1)

  bytes := d.bytes-for-protocol
  cloned := Data.from-data d
  assert-eq-bytes "constructor.from-data bytes" cloned.bytes-for-protocol bytes

  prefixed := #[0xaa, 0xbb] + bytes
  from-at := Data.from-bytes-at prefixed 2
  assert-eq-bytes "constructor.from-bytes-at bytes" from-at.bytes-for-protocol bytes

  target := ByteArray bytes.size + 4
  end := d.write-bytes-for-protocol-into target 2
  assert-eq "write-bytes-for-protocol-into end" end (2 + bytes.size)
  assert-eq-bytes "write-bytes-for-protocol-into payload" target[2..2 + bytes.size] bytes

  assert-eq "stringify includes first string field" ((d.stringify).contains "10:") true
  assert-eq-bytes "list-to-byte-array" (list-to-byte-array [1, 2, 3]) #[1, 2, 3]

  print "✅ Passed Data add get roundtrips"

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
