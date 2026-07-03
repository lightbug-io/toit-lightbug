import lightbug.modules.comms.message-tracker show MessageTracker BoundedTrackerMap
import monitor

assert-true label/string value/bool:
  if not value:
    throw "$label failed"

assert-false label/string value/bool:
  if value:
    throw "$label failed"

assert-eq label/string got want:
  if got != want:
    throw "$label failed. Got=$got Want=$want"

tracker --timeout/Duration?=null -> MessageTracker:
  return MessageTracker --latch=monitor.Latch --timeout=timeout

main:
  insert-get-remove
  update-does-not-evict
  evicts-colliding-slot
  remove-timed-out
  print "Message tracker tests passed"

insert-get-remove:
  m := BoundedTrackerMap --capacity=3
  t1 := tracker
  t2 := tracker
  assert-eq "empty size" m.size 0
  assert-eq "insert one evicted" (m.set 10 t1) null
  assert-eq "insert two evicted" (m.set 20 t2) null
  assert-eq "size after insert" m.size 2
  assert-true "contains 10" (m.contains 10)
  assert-eq "get 10" (m.get 10) t1
  assert-eq "remove missing" (m.remove 99) null
  assert-eq "remove 10" (m.remove 10) t1
  assert-false "removed no longer contained" (m.contains 10)
  assert-eq "size after remove" m.size 1
  assert-eq "remaining tracker" (m.get 20) t2

update-does-not-evict:
  m := BoundedTrackerMap --capacity=2
  t1 := tracker
  t1b := tracker
  t2 := tracker
  t3 := tracker
  m.set 1 t1
  m.set 2 t2
  assert-eq "update returns no eviction" (m.set 1 t1b) null
  assert-eq "updated value" (m.get 1) t1b
  evicted := m.set 3 t3
  assert-eq "colliding key evicted after update" evicted t1b
  assert-false "colliding key gone" (m.contains 1)
  assert-true "second key remains" (m.contains 2)
  assert-true "new key present" (m.contains 3)

evicts-colliding-slot:
  m := BoundedTrackerMap --capacity=2
  t1 := tracker
  t2 := tracker
  t3 := tracker
  t4 := tracker
  m.set 1 t1
  m.set 2 t2
  assert-eq "evict 1" (m.set 3 t3) t1
  assert-false "key 1 gone" (m.contains 1)
  assert-true "key 2 remains" (m.contains 2)
  assert-true "key 3 present" (m.contains 3)
  assert-eq "evict 2" (m.set 4 t4) t2
  assert-false "key 2 gone" (m.contains 2)
  assert-true "key 3 remains" (m.contains 3)
  assert-true "key 4 present" (m.contains 4)

remove-timed-out:
  m := BoundedTrackerMap --capacity=4
  expired1 := tracker --timeout=(Duration --ms=0)
  live := tracker --timeout=(Duration --s=60)
  expired2 := tracker --timeout=(Duration --ms=0)
  m.set 1 expired1
  m.set 2 live
  m.set 3 expired2
  sleep --ms=1
  removed-keys := []
  removed := m.remove-timed-out: | key tracker |
    removed-keys.add key
    tracker.clear
  assert-eq "timed out count" removed 2
  assert-eq "size after timeout removal" m.size 1
  assert-true "live remains" (m.contains 2)
  assert-false "expired 1 gone" (m.contains 1)
  assert-false "expired 3 gone" (m.contains 3)
  assert-eq "removed first key" removed-keys[0] 1
  assert-eq "removed second key" removed-keys[1] 3
