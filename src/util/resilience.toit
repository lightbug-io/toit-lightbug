import log

/**
Catches exceptions from the given $lambda and restarts it.

If $limit is -1, it will run indefinitely, otherwise it will run $limit times at most.

If $restart-always is true (the default), it will always restart the given $l, even if it finishes successfully.
If $restart-always is false, it will only restart the given $l if it throws an exception.

# Example
```
  task:: catch-and-restart "doWork" (:: doWork)
```
*/
catch-and-restart name/string lambda/Lambda
    --limit/int?=-1
    --restart-always/bool=true
    --logger/log.Logger=log.default:
  while limit == -1 or limit > 0:
    if limit > 0:
      limit -= 1
    e := catch --trace=true:
      logger.debug "car: Running $name"
      lambda.call
      if not restart-always:
        logger.info "car: Finished $name"
        return
    if e:
      logger.error "car: Caught: $e.stringify"
      logger.info "car: Restarting $name"
      yield