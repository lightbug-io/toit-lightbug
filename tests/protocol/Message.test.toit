import lightbug.protocol show *

main:
  bl := [0x03, 0x28, 0x00, 0x05, 0x00, 0x04, 0x00, 0x03, 0x04, 0x01, 0x02, 0x04, 0xe0, 0x7e, 0x7e, 0x87, 0x01, 0x00, 0x04, 0x58, 0x00, 0x00, 0x00, 0x08, 0x56, 0x99, 0x93, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x02, 0x0b, 0x00, 0xc9, 0x35]
  m := Message.from-list bl
  // If we didnt error, count it as passed :)
  print "✅ Passed from-list (as no error)"