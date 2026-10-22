import ..messages as messages
import .vending_protocol show VendingProtocol
import log

class VendingUpdater:

  logger_/log.Logger
  identity-cache_ /any

  constructor --logger=log.default --identity-cache=null:
    logger_ = logger
    identity-cache_ = identity-cache

  static REQUEST-TIMEOUT := (Duration --s=10)

  update-vending-cache-from-device comms vending:
    update-device-id comms vending
    update-temperature comms vending
    update-battery comms vending

  update-device-id comms vending:
    // Called on every existing updater cycle, even after an ID was cached.
    e := catch:
      resp := (comms.send messages.DeviceIDs.get-msg --withLatch=true --now=true --timeout=REQUEST-TIMEOUT).get
      if not resp:
        logger_.warn "DeviceIDs: no response"
        return
      // ACKs and errors can also resolve the request latch.
      if resp.type != messages.DeviceIDs.MT or not resp.msg-ok:
        logger_.warn "DeviceIDs: unexpected or unsuccessful response"
        return
      ids := messages.DeviceIDs.from-data resp.data
      current-id := identity-field_ ids messages.DeviceIDs.ID
      serial := identity-field_ ids messages.DeviceIDs.SERIAL
      // Validate the raw serial: a nonzero serial with suffix zero is valid.
      if serial != null:
        vending-id := vending.update-vending-id-from-serial serial
        logger_.info "✅ Device serial: $serial -> vending-id=$vending-id"
      // Missing/zero serials must never downgrade a last-known-good serial.
      // The encoded prefix also survives replacing the updater instance.
      else if (vending.vending-id >> 32) != VendingProtocol.ID_PREFIX_SERIAL and current-id != null:
        vending-id := vending.update-vending-id-from-current-id current-id
        logger_.info "✅ Device current ID: $current-id -> vending-id=$vending-id"
      if identity-cache_ != null:
        identity-cache_.update --device-id=current-id --serial=serial
    if e:
      logger_.error "❌ DeviceIDs update failed: $e"

  identity-field_ ids key/int -> int?:
    if not ids.has-data key: return null
    bytes := ids.get-data key
    if bytes.size == 0 or bytes.size > 8:
      logger_.warn "DeviceIDs: malformed identity field $key"
      return null
    value := ids.get-data-uint key
    return value > 0 ? value : null

  update-temperature comms vending:
    e := catch:
      resp := (comms.send messages.Temperature.get-msg --withLatch=true --now=true --timeout=REQUEST-TIMEOUT).get
      if not resp:
        logger_.warn "Temperature: no response"
        return
      temperature := (messages.Temperature.from-data resp.data).temperature
      vending.update-cache --temperature=temperature
      logger_.info "✅ Temperature: $temperature C"
    if e:
      logger_.error "❌ Temperature failed: $e"

  update-battery comms vending:
    // BatteryStatus provides direct voltage used by vending replies.
    e := catch:
      battery-resp := (comms.send messages.BatteryStatus.get-msg --withLatch=true --now=true --timeout=REQUEST-TIMEOUT).get
      if not battery-resp:
        logger_.warn "BatteryStatus: no response"
        return

      battery := messages.BatteryStatus.from-data battery-resp.data
      vending.update-cache --voltage=battery.voltage
      logger_.info "✅ BatteryStatus: voltage=$(battery.voltage)V percent=$(battery.percent)%"
    if e:
      logger_.error "❌ Battery update failed: $e"
