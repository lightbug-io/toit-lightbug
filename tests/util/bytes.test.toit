import lightbug.util.bytes

main:
  format-mac-bytearray
  format-mac-string
  format-mac-null
  format-mac-7byte

format-mac-bytearray:
  // MAC as ByteArray [0x01,0x23,0x45,0x67,0x89,0xab]
  mac := #[1, 0x23, 0x45, 0x67, 0x89, 0xab]
  s := bytes.format-mac mac
  if s != "01:23:45:67:89:ab":
    print "❌ format-mac-bytearray Wanted 01:23:45:67:89:ab got $s"
  else:
    print "✅ format-mac-bytearray Got $s"

format-mac-string:
  s := bytes.format-mac "de:ad:be:ef:00:01"
  if s != "de:ad:be:ef:00:01":
    print "❌ format-mac-string Wanted de:ad:be:ef:00:01 got $s"
  else:
    print "✅ format-mac-string Got $s"

format-mac-null:
  s := bytes.format-mac null
  if s != "<unknown>":
    print "❌ format-mac-null Wanted <unknown> got $s"
  else:
    print "✅ format-mac-null Got $s"

format-mac-7byte:
  // 7-byte array with leading length byte; expect the last 6 bytes formatted.
  mac := #[6, 0xde, 0xad, 0xbe, 0xef, 0xfa, 0xce]
  s := bytes.format-mac mac
  if s != "de:ad:be:ef:fa:ce":
    print "❌ format-mac-7byte Wanted de:ad:be:ef:fa:ce got $s"
  else:
    print "✅ format-mac-7byte Got $s"
