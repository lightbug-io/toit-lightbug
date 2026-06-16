import lightbug.messages.messages_gen as messages
import lightbug.protocol as protocol
import system

measure-us [block] -> int:
  start := Time.monotonic-us
  block.call
  return Time.monotonic-us - start

print-stats label/string stats/List -> none:
  print "$label: gc=$(stats[system.STATS-INDEX-GC-COUNT]) full-gc=$(stats[system.STATS-INDEX-FULL-GC-COUNT]) compacting-full-gc=$(stats[system.STATS-INDEX-FULL-COMPACTING-GC-COUNT]) allocated=$(stats[system.STATS-INDEX-ALLOCATED-MEMORY]) reserved=$(stats[system.STATS-INDEX-RESERVED-MEMORY]) bytes-allocated=$(stats[system.STATS-INDEX-BYTES-ALLOCATED-IN-OBJECT-HEAP]) free=$(stats[system.STATS-INDEX-SYSTEM-FREE-MEMORY]) largest-free=$(stats[system.STATS-INDEX-SYSTEM-LARGEST-FREE])"

print-delta label/string before/List after/List -> none:
  print "$label delta: gc=$(after[system.STATS-INDEX-GC-COUNT] - before[system.STATS-INDEX-GC-COUNT]) full-gc=$(after[system.STATS-INDEX-FULL-GC-COUNT] - before[system.STATS-INDEX-FULL-GC-COUNT]) compacting-full-gc=$(after[system.STATS-INDEX-FULL-COMPACTING-GC-COUNT] - before[system.STATS-INDEX-FULL-COMPACTING-GC-COUNT]) allocated=$(after[system.STATS-INDEX-ALLOCATED-MEMORY] - before[system.STATS-INDEX-ALLOCATED-MEMORY]) reserved=$(after[system.STATS-INDEX-RESERVED-MEMORY] - before[system.STATS-INDEX-RESERVED-MEMORY]) bytes-allocated=$(after[system.STATS-INDEX-BYTES-ALLOCATED-IN-OBJECT-HEAP] - before[system.STATS-INDEX-BYTES-ALLOCATED-IN-OBJECT-HEAP]) free=$(after[system.STATS-INDEX-SYSTEM-FREE-MEMORY] - before[system.STATS-INDEX-SYSTEM-FREE-MEMORY]) largest-free=$(after[system.STATS-INDEX-SYSTEM-LARGEST-FREE] - before[system.STATS-INDEX-SYSTEM-LARGEST-FREE])"

main:
  create-count := 1_000_000
  parse-count := 1_000_000
  retain-count := 250_000

  print "Memory-aware protocol benchmark"
  print "Counts: create=$create-count parse=$parse-count retain=$retain-count"

  // Prime stats and reset bytes-allocated-delta baseline.
  ignored := system.bytes-allocated-delta

  baseline := system.process-stats --gc=true
  print-stats "baseline(gc)" baseline

  msg-template := messages.Command.set-msg --base-data=(messages.Command.data --arm-mode=1)

  // Create benchmark.
  ignored = system.bytes-allocated-delta
  last-bytes := null
  create-us := measure-us:
    create-count.repeat:
      last-bytes = msg-template.bytes-for-protocol
  create-alloc-delta := system.bytes-allocated-delta
  after-create := system.process-stats
  after-create-gc := system.process-stats --gc=true

  print "Create phase: $(create-us / 1000) ms"
  print "Create phase bytes-allocated-delta: $create-alloc-delta"
  print "Create phase gc-count direct: $(system.gc-count)"
  print "Last created bytes: $last-bytes"
  print-stats "after-create(no-gc)" after-create
  print-delta "create vs baseline(no-gc)" baseline after-create
  print-stats "after-create(gc)" after-create-gc
  print-delta "create vs baseline(gc)" baseline after-create-gc

  // Parse benchmark.
  ignored = system.bytes-allocated-delta
  last-message := null
  parse-us := measure-us:
    parse-count.repeat:
      last-message = protocol.Message.from-bytes last-bytes
  parse-alloc-delta := system.bytes-allocated-delta
  after-parse := system.process-stats
  after-parse-gc := system.process-stats --gc=true

  print "Parse phase: $(parse-us / 1000) ms"
  print "Parse phase bytes-allocated-delta: $parse-alloc-delta"
  print "Last parsed message: $last-message"
  print-stats "after-parse(no-gc)" after-parse
  print-delta "parse vs after-create-gc(no-gc)" after-create-gc after-parse
  print-stats "after-parse(gc)" after-parse-gc
  print-delta "parse vs after-create-gc(gc)" after-create-gc after-parse-gc

  // Retained-memory experiment: keep many encoded messages alive.
  ignored = system.bytes-allocated-delta
  retained := []
  retain-us := measure-us:
    retain-count.repeat:
      retained.add msg-template.bytes-for-protocol
  retain-alloc-delta := system.bytes-allocated-delta
  after-retain := system.process-stats
  after-retain-gc := system.process-stats --gc=true

  print "Retain phase: $(retain-us / 1000) ms"
  print "Retain phase bytes-allocated-delta: $retain-alloc-delta"
  print "Retained messages: $(retained.size)"
  print-stats "after-retain(no-gc)" after-retain
  print-delta "retain vs after-parse-gc(no-gc)" after-parse-gc after-retain
  print-stats "after-retain(gc)" after-retain-gc
  print-delta "retain vs after-parse-gc(gc)" after-parse-gc after-retain-gc

  // Release retained data and force GC to see reclaimed live heap.
  retained = []
  after-release-gc := system.process-stats --gc=true
  print-stats "after-release(gc)" after-release-gc
  print-delta "release vs after-retain-gc" after-retain-gc after-release-gc

  // Optional low-level dumps for deep inspection.
  system.serial-print-heap-report "v3-profile-memory"
  system.print-objects --marker="v3-profile-memory"