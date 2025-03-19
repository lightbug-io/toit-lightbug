import lightbug.protocol show *

main:
  name := "bytes-for-protocol: no bytes still has length"
  d := DataField
  got := d.bytes-for-protocol
  want := #[0x00]
  if got != want:
      print "❌ " + name + ": Wanted " + want.stringify + " got " + got.stringify
  else:
      print "✅ " + name + ": Got " + got.stringify
  
  name = "bytes-for-protocol: one byte"
  d = DataField #[0x50]
  got = d.bytes-for-protocol
  want = #[0x01, 0x50]
  if got != want:
      print "❌ " + name + ": Wanted " + want.stringify + " got " + got.stringify
  else:
      print "✅ " + name + ": Got " + got.stringify
