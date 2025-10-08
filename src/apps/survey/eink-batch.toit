import monitor
import log

eink-sem := monitor.Semaphore --count=1 --limit=1
eink-last-draw-ago_/Time := Time.now

// Perform a batch of actions in a single task to avoid interleaving with other
// async calls.
// Used to ensure that multiple messages intended for a single eink update, are
// sent together without other async calls interleaving.
//
// --important: if true, will wait indefinitely for the mutex, otherwise will not
// draw if the mutex is not available immediately.
//
// In the future, we might advance this further, to allow queuing of important?
// Overwriting of older updates etc?
//
// Ultimately this should be moved to the primary eink module for reuse in a generic way
// as part of the lightbug package.
eink-do-batch --important/bool=false [block]:
  if not important:
    // Skip non important things, if other eink messages are actively being sent
    if eink-sem.count == 0: // If there is no room
      return
    
    // If we are not actively sending, but we have drawn recently, skip non important
    wait-until := eink-last-draw-ago_ + (Duration --ms=1000)
    if wait-until >= Time.now:
      return
  
  t := 5000
  if important:
    t = 10000
  
  // Otherwise, lock and draw..
  eink-sem.down
  e := catch:
    with-timeout --ms=t:
      block.call
  if e:
    log.warn "$e"
  eink-last-draw-ago_ = Time.now
  eink-sem.up