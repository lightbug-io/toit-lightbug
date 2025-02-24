import log

catchAndRestart name/string l/Lambda:
  while true:
    e := catch --trace=true:
      log.debug "catchAndRestart: Running " + name
      l.call
    if e:
      log.error "catchAndRestart: Caught exception: " + e.stringify
      log.info "catchAndRestart: Restarting " + name
      yield