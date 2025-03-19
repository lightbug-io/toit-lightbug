import lightbug.util.idgen

main:
  sequential
  random

sequential:
  g := idgen.SequentialIdGenerator --start=1 --maxId=3
  expectedI := [1, 2, 0, 1]
  expectedI.do:
    i := g.next
    if i != it:
      print "❌ idgen sequential Wanted $it got $i"
    else:
      print "✅ idgen sequential Got $i"

random:
  g := idgen.RandomIdGenerator --lowerBound=1 --upperBound=3
  for i := 0; i < 10; i++:
    it := g.next
    if it < 1 or it > 3:
      print "❌ idgen random Out of bounds $it"
    else:
      print "✅ idgen random Got $it (in bounds)"