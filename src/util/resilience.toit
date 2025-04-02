import log

catch-and-restart name/string l/Lambda --logger/log.Logger=log.default:
  while true:
    e := catch --trace=true:
      logger.debug "catchAndRestart: Running " + name
      l.call
    if e:
      logger.error "catchAndRestart: Caught exception: " + e.stringify
      logger.info "catchAndRestart: Restarting " + name
      yield