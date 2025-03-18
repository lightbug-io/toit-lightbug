import log

catch-and-restart name/string l/Lambda:
  while true:
    e := catch --trace=true:
      log.debug "catch-and-restart: Running " + name
      l.call
    if e:
      log.error "catch-and-restart: Caught exception: " + e.stringify
      log.info "catch-and-restart: Restarting " + name
      yield