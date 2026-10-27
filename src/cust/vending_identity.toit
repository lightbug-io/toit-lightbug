import .vending_protocol show VendingProtocol

/** Persist both raw identities together; the kiosk only receives the serial suffix. */
class VendingIdentity:
  store_ /any
  dirty_ /bool := false
  device-id /int := 0
  serial /int := 0

  constructor store:
    store_ = store
    saved := store_.get "identity" --if-absent=(: null)
    if saved is Map:
      device-id = positive-int_ (saved.get "id" --if-absent=(: null))
      serial = positive-int_ (saved.get "serial" --if-absent=(: null))

  vending-id -> int:
    if serial > 0: return VendingProtocol.vending-id-from-serial serial
    return VendingProtocol.vending-id-from-current-id device-id

  update --device-id/int?=null --serial/int?=null:
    next-id := device-id != null and device-id > 0 ? device-id : this.device-id
    next-serial := serial != null and serial > 0 ? serial : this.serial
    if next-id != this.device-id or next-serial != this.serial:
      this.device-id = next-id
      this.serial = next-serial
      dirty_ = true
    if not dirty_: return
    // One record avoids mismatched ID/serial pairs across interrupted writes.
    // Keep failed writes pending even if the next reply omits its serial.
    store_["identity"] = {"id": this.device-id, "serial": this.serial}
    dirty_ = false

  static positive-int_ value -> int:
    return value is int and value > 0 ? value : 0
