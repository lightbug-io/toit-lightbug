import ..messages as messages
import .vending_protocol show VendingProtocol
import log

class VendingUpdater:

  logger_/log.Logger

  constructor --logger=log.default:
    logger_ = logger

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
      if ids.has-data messages.DeviceIDs.SERIAL:
        serial-bytes := ids.get-data messages.DeviceIDs.SERIAL
        if serial-bytes.size == 0 or serial-bytes.size > 8:
          logger_.warn "DeviceIDs: malformed serial"
          return
        serial := ids.serial
        // Validate the raw serial before encoding: a nonzero serial whose
        // suffix is zero (e.g. 1_000_000) is still a valid serial identity.
        if serial > 0:
          vending-id := vending.update-vending-id-from-serial serial
          logger_.info "✅ Device serial: $serial -> vending-id=$vending-id"
          return
      // Missing/zero serials must never downgrade a last-known-good serial.
      // The encoded prefix also survives replacing the updater instance.
      if (vending.vending-id >> 32) == VendingProtocol.ID_PREFIX_SERIAL:
        return
      if ids.has-data messages.DeviceIDs.ID:
        id-bytes := ids.get-data messages.DeviceIDs.ID
        if id-bytes.size == 0 or id-bytes.size > 8:
          logger_.warn "DeviceIDs: malformed current ID"
          return
        if ids.id > 0:
          vending-id := vending.update-vending-id-from-current-id ids.id
          logger_.info "✅ Device current ID: $(ids.id) -> vending-id=$vending-id"
    if e:
      logger_.error "❌ DeviceIDs update failed: $e"

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
