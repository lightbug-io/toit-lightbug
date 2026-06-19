import system
import core.utils

some-map := {:}

main:
  // Profiling is sample based
  // 100 iterations might show 0 ticks
  // 1000 iterations should show some ticks
  utils.Profiler.install false
  utils.Profiler.do:
    1000.repeat: |i|
      b := i+i
      some-map[i] = b
      print "$i -> $b"
  utils.Profiler.report "Profiler report" --cutoff=0

  // There are then various ways to get memory stats, but the easiest is to use the system module
  system.serial-print-heap-report
  
  // And there are other process stats available, which can be printed as follows:
  ps := system.process-stats
  o := "process-stats: [gc: $(ps[system.STATS-INDEX-GC-COUNT]),"
  o += " allocated: $(ps[system.STATS-INDEX-ALLOCATED-MEMORY]),"
  o += " reserved: $(ps[system.STATS-INDEX-RESERVED-MEMORY]),"
  o += " messages: $(ps[system.STATS-INDEX-PROCESS-MESSAGE-COUNT]),"
  o += " heap-allocated: $(ps[system.STATS-INDEX-BYTES-ALLOCATED-IN-OBJECT-HEAP]),"
  o += " group: $(ps[system.STATS-INDEX-GROUP-ID]),"
  o += " process: $(ps[system.STATS-INDEX-PROCESS-ID]),"
  o += " system-free: $(ps[system.STATS-INDEX-SYSTEM-FREE-MEMORY]),"
  o += " system-largest-free: $(ps[system.STATS-INDEX-SYSTEM-LARGEST-FREE]),"
  o += " full-gc: $(ps[system.STATS-INDEX-FULL-GC-COUNT]),"
  o += " full-compacting-gc: $(ps[system.STATS-INDEX-FULL-COMPACTING-GC-COUNT])]"
  print o

