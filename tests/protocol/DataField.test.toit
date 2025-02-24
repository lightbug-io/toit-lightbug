import lightbug.protocol show *
import log

main:
  name := "bytesForProtocol: no bytes still has length"
  d := DataField
  got := d.bytesForProtocol
  want := #[0x00]
  if got != want:
      log.error "❌ " + name + ": Wanted " + want.stringify + " got " + got.stringify
  else:
      log.info "✅ " + name + ": Got " + got.stringify
  
  name = "bytesForProtocol: one byte"
  d = DataField #[0x50]
  got = d.bytesForProtocol
  want = #[0x01, 0x50]
  if got != want:
      log.error "❌ " + name + ": Wanted " + want.stringify + " got " + got.stringify
  else:
      log.info "✅ " + name + ": Got " + got.stringify
