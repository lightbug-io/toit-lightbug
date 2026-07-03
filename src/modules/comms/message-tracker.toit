import monitor
import io.byte-order show LITTLE-ENDIAN

/**
Tracking state for a single message awaiting response.
*/
class MessageTracker:
  latch/monitor.Latch? := null
  on-good-ack/Lambda? := null
  on-bad-ack/Lambda? := null
  on-good-response/Lambda? := null
  on-bad-response/Lambda? := null
  on-timeout/Lambda? := null
  timeout-at/Time? := null

  constructor
      --latch/monitor.Latch?=null
      --on-good-ack/Lambda?=null
      --on-bad-ack/Lambda?=null
      --on-good-response/Lambda?=null
      --on-bad-response/Lambda?=null
      --on-timeout/Lambda?=null
      --timeout/Duration?=null:
    this.latch = latch
    this.on-good-ack = on-good-ack
    this.on-bad-ack = on-bad-ack
    this.on-good-response = on-good-response
    this.on-bad-response = on-bad-response
    this.on-timeout = on-timeout
    if timeout:
      this.timeout-at = Time.now + timeout

  /** Returns true if any callbacks or latch are registered. */
  has-tracking -> bool:
    return latch != null or on-good-ack != null or on-bad-ack != null or on-good-response != null or on-bad-response != null or on-timeout != null

  /** Check if this tracker has timed out. */
  is-timed-out -> bool:
    if timeout-at == null: return false
    return (Duration.since timeout-at) > (Duration --s=0)

  /** Clear all references to help GC. */
  clear -> none:
    latch = null
    on-good-ack = null
    on-bad-ack = null
    on-good-response = null
    on-bad-response = null
    on-timeout = null
    timeout-at = null


/**
A bounded map for tracking messages awaiting responses.

Message IDs are stored in fixed slots using key % capacity. With the default
sequential message id generator this evicts the matching old slot after the
bounded window wraps, avoiding unbounded memory growth without a Map/List pair.
*/
class BoundedTrackerMap:
  capacity_/int
  ids_/ByteArray
  occupied_/ByteArray
  trackers_/List := []
  count_/int := 0

  constructor --capacity/int=64:
    capacity_ = capacity
    ids_ = ByteArray capacity * 4
    occupied_ = ByteArray capacity
    for i := 0; i < capacity_; i++:
      trackers_.add null

  /** Get a tracker by message ID. Returns null if not found. */
  get key/int -> MessageTracker?:
    index := find-index_ key
    if index < 0:
      return null
    return trackers_[index]

  /** Check if a key exists. */
  contains key/int -> bool:
    return (find-index_ key) >= 0

  /** Number of tracked messages. */
  size -> int:
    return count_

  /**
  Add or update a tracker. Evicts oldest if at capacity.
  Returns any evicted tracker (for cleanup) or null.
  */
  set key/int value/MessageTracker -> MessageTracker?:
    evicted/MessageTracker? := null

    // If key already exists, just update value (no change to order).
    index := slot-for_ key
    if occupied_[index] != 0 and (id-at_ index) == key:
      trackers_[index] = value
      return null

    if occupied_[index] != 0:
      evicted = trackers_[index]
      clear-index_ index
      count_--

    set-id_ index key
    occupied_[index] = 1
    trackers_[index] = value
    count_++
    return evicted

  /** Remove a tracker by key. Returns the removed tracker or null. */
  remove key/int -> MessageTracker?:
    idx := find-index_ key
    if idx < 0:
      return null
    tracker := trackers_[idx]
    clear-index_ idx
    count_--
    return tracker

  /** Iterate over all entries. Block receives (key, tracker). */
  do [block] -> none:
    for i := 0; i < capacity_; i++:
      if occupied_[i] == 0:
        continue
      key := id-at_ i
      tracker := trackers_[i]
      if tracker:
        block.call key tracker

  /** Remove all entries matching a predicate. Returns removed count. */
  remove-where [predicate] -> int:
    removed := 0
    for i := 0; i < capacity_; i++:
      if occupied_[i] == 0:
        continue
      key := id-at_ i
      tracker := trackers_[i]
      if tracker and (predicate.call key tracker):
        clear-index_ i
        count_--
        removed++
    return removed

  remove-timed-out [block] -> int:
    removed := 0
    for i := 0; i < capacity_; i++:
      if occupied_[i] == 0:
        continue
      key := id-at_ i
      tracker := trackers_[i]
      if tracker and tracker.is-timed-out:
        clear-index_ i
        count_--
        removed++
        block.call key tracker
    return removed

  id-at_ index/int -> int:
    return LITTLE-ENDIAN.uint32 ids_ (index * 4)

  set-id_ index/int key/int -> none:
    LITTLE-ENDIAN.put-uint32 ids_ (index * 4) key

  clear-index_ index/int -> none:
    occupied_[index] = 0
    trackers_[index] = null

  find-index_ key/int -> int:
    index := slot-for_ key
    if occupied_[index] != 0 and (id-at_ index) == key:
      return index
    return -1

  slot-for_ key/int -> int:
    if capacity_ <= 0:
      return 0
    slot := key % capacity_
    if slot < 0:
      slot = -slot
    return slot
