import ..messages as messages
import .vending show Vending
import log

class VendingUpdater:

  logger_/log.Logger

  constructor --logger=log.default:
    logger_ = logger

  static REQUEST-TIMEOUT := (Duration --s=10)

  update-vending-cache-from-device comms vending/Vending:
    update-device-id comms vending
    update-temperature comms vending
    update-battery comms vending

  update-device-id comms vending/Vending:
    if vending.vending-id != Vending.VENDING_ID_DEFAULT:
      return
    e := catch:
      resp := (comms.send messages.DeviceIDs.get-msg --withLatch=true --now=true --timeout=REQUEST-TIMEOUT).get
      if not resp:
        logger_.warn "DeviceIDs: no response"
        return
      ids := messages.DeviceIDs.from-data resp.data
      vending-id := vending.update-vending-id-from-current-id ids.id
      logger_.info "✅ Device IDs: id=$(ids.id) imei=$(ids.imei) iccid=$(ids.iccid) -> vending-id=$(vending-id)"
    if e:
      logger_.error "❌ DeviceIDs update failed: $e"

  update-temperature comms vending/Vending:
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

  update-battery comms vending/Vending:
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
