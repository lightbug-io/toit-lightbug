import lightbug.protocol as lbp
import log

main:
  // just tests that the constants can easily be used from the package
  log.info "✅ Passed using constants from the package: " + lbp.HEADER-CLIENT-ID.stringify