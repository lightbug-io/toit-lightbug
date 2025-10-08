import monitor
import log

strobe-sem := monitor.Semaphore --count=1 --limit=1

// Rather than needing this in the survey app, move the ability to solve this problem into the strobe module.
//
// In essence the problem is that there is no "flash" ability of the strobe package.
// So apps end up doing something like this...
// 
//              device_.strobe.blue
//              sleep --ms=50
//              device_.strobe.off
// 
// And if they do this multiple times in quick succession, you can end up with overlapping strobes
// ON SLEEP ON SLEEP OFF OFF for example

strobe-once [block]:
  // Skip all strobes if the strobe is busy
  if strobe-sem.count == 0: // If there is no room
    log.debug "STROBE busy skip"
    return
  
  // Otherwise, lock and strobe..
  strobe-sem.down
  e := catch:
    with-timeout --ms=1000:
      block.call
  if e:
    log.warn "$e"
  strobe-sem.up