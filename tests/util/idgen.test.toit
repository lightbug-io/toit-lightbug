import lightbug.util.idgen
import log

main:
  sequential
  random

sequential:
  g := idgen.SequentialIdGenerator --start=1 --maxId=3
  expectedI := [1, 2, 0, 1]
  expectedI.do:
    i := g.next
    if i != it:
      log.info "❌ idgen sequential Wanted $it got $i"
    else:
      log.info "✅ idgen sequential Got $i"

random:
  g := idgen.RandomIdGenerator --lowerBound=1 --upperBound=3
  for i := 0; i < 10; i++:
    it := g.next
    if it < 1 or it > 3:
      log.error "❌ idgen random Out of bounds $it"
    else:
      log.info "✅ idgen random Got $it (in bounds)"