/** Small state shared by the live LoRa app and its timing tests. */
class LoraFlow:
  next-tx-us_/int := 0
  pending-manual-mode_/string? := null
  pending-generation_/int := 0
  render-pending_/bool := false
  last-render-us_/int := 0
  last-flash-us_/int := 0

  tx-wait-us now-us/int -> int:
    return now-us < next-tx-us_ ? next-tx-us_ - now-us : 0

  reserve-tx now-us/int gap-ms/int -> bool:
    if (tx-wait-us now-us) > 0: return false
    next-tx-us_ = now-us + gap-ms * 1000
    return true

  queue-manual mode/string -> bool:
    was-empty := pending-manual-mode_ == null
    pending-manual-mode_ = mode
    return was-empty

  pending-manual-mode -> string?:
    return pending-manual-mode_

  take-manual -> string?:
    mode := pending-manual-mode_
    pending-manual-mode_ = null
    return mode

  pending-generation -> int:
    return pending-generation_

  cancel-manual:
    pending-manual-mode_ = null
    pending-generation_++

  note-receive:
    render-pending_ = true

  should-flash now-us/int min-interval-us/int -> bool:
    if last-flash-us_ != 0 and now-us - last-flash-us_ < min-interval-us:
      return false
    last-flash-us_ = now-us
    return true

  reset-flash:
    last-flash-us_ = 0

  render-pending -> bool:
    return render-pending_

  render-wait-us now-us/int min-interval-us/int -> int:
    if last-render-us_ == 0: return 0
    due-us := last-render-us_ + min-interval-us
    return now-us < due-us ? due-us - now-us : 0

  mark-rendered now-us/int:
    last-render-us_ = now-us
    render-pending_ = false

  cancel-render:
    render-pending_ = false

/** Keep the wire ping readable by apps predating tagged profiles. */
class LoraWire:
  static ping-body -> string:
    return "ping"

  static is-ping body/string -> bool:
    return body == "ping" or body.starts-with "ping:"

  static is-legacy-pong body/string -> bool:
    return body == "pong"

  static pong-profile body/string -> string?:
    if body.starts-with "pong:": return body[5..body.size]
    return null
