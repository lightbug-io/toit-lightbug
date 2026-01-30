import monitor

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

When the map reaches capacity, the oldest entries (by insertion order) are
evicted to make room for new ones. This prevents unbounded memory growth.
*/
class BoundedTrackerMap:
  map_/Map := {:}
  keys_/List := []  // Track insertion order for LRU eviction.
  capacity_/int

  constructor --capacity/int=64:
    capacity_ = capacity

  /** Get a tracker by message ID. Returns null if not found. */
  get key/int -> MessageTracker?:
    return map_.get key

  /** Check if a key exists. */
  contains key/int -> bool:
    return map_.contains key

  /** Number of tracked messages. */
  size -> int:
    return map_.size

  /**
  Add or update a tracker. Evicts oldest if at capacity.
  Returns any evicted tracker (for cleanup) or null.
  */
  set key/int value/MessageTracker -> MessageTracker?:
    evicted/MessageTracker? := null

    // If key already exists, just update value (no change to order).
    if map_.contains key:
      map_[key] = value
      return null

    // Evict oldest if at capacity.
    if map_.size >= capacity_ and keys_.size > 0:
      oldest-key := keys_.remove --at=0
      evicted = map_.get oldest-key
      map_.remove oldest-key

    map_[key] = value
    keys_.add key
    return evicted

  /** Remove a tracker by key. Returns the removed tracker or null. */
  remove key/int -> MessageTracker?:
    tracker := map_.get key
    if tracker:
      map_.remove key
      // Remove from keys list (linear scan, but list is bounded).
      idx := keys_.index-of key
      if idx >= 0:
        keys_.remove --at=idx
    return tracker

  /** Iterate over all entries. Block receives (key, tracker). */
  do [block] -> none:
    // Copy keys to avoid modification during iteration.
    keys := keys_.copy
    keys.do: | key |
      tracker := map_.get key
      if tracker:
        block.call key tracker

  /** Remove all entries matching a predicate. Returns removed count. */
  remove-where [predicate] -> int:
    removed := 0
    // Collect keys to remove first to avoid modification during iteration.
    to-remove := []
    keys_.do: | key |
      tracker := map_.get key
      if tracker and (predicate.call key tracker):
        to-remove.add key

    to-remove.do: | key |
      remove key
      removed++
    return removed
