import lightbug.util.idgen

main:
  sequential

sequential:
  g := idgen.SequentialIdGenerator --start=1 --maxId=3
  expectedI := [1, 2, 0, 1]
  expectedI.do:
    i := g.next
    if i != it:
      print "❌ idgen sequential Wanted $it got $i"
    else:
      print "✅ idgen sequential Got $i"
