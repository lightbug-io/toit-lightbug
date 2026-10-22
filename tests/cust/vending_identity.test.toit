import monitor
import lightbug.protocol as protocol
import lightbug.messages show DeviceIDs
import lightbug.cust.vending_identity show VendingIdentity
import lightbug.cust.vending_updater show VendingUpdater
import lightbug.cust.vending_protocol show VendingProtocol

class Store:
  values /Map := {:}
  writes /int := 0
  fail /bool := false

  get key/string [--if-absent]:
    return values.get key --if-absent=if-absent

  operator []= key/string value:
    if fail: throw "storage unavailable"
    writes++
    values[key] = value

class Comms:
  reply /any := null
  requests /int := 0

  send msg --withLatch --now --timeout:
    check "DeviceIDs requested" msg.type DeviceIDs.MT
    requests++
    latch := monitor.Latch
    latch.set reply
    return latch

class Vending:
  vending-id /int := 0
  constructor .vending-id:

  update-vending-id-from-serial serial:
    vending-id = VendingProtocol.vending-id-from-serial serial
    return vending-id

  update-vending-id-from-current-id id:
    vending-id = VendingProtocol.vending-id-from-current-id id
    return vending-id

check label/string actual expected:
  if actual != expected: throw "$label: expected $expected, got $actual"

ids-reply --id/int?=null --serial/int?=null:
  return protocol.Message.with-data DeviceIDs.MT (DeviceIDs.data --id=id --serial=serial)

main:
  store := Store
  identity := VendingIdentity store
  vending := Vending identity.vending-id
  updater := VendingUpdater --identity-cache=identity
  comms := Comms
  check "empty identity" vending.vending-id 0x1B00000000

  comms.reply = ids-reply --id=19_315_383
  updater.update-device-id comms vending
  check "fallback identity" vending.vending-id 0x1B0126BAB7
  check "fallback survives reboot" (VendingIdentity store).vending-id vending.vending-id

  // Production parser sees the same little-endian serial as the protected SET.
  raw := protocol.Data.from-bytes #[2, 0, 1, 4, 4, 0xB7, 0xBA, 0x26, 1, 4, 0xF9, 0x59, 0x40, 5]
  comms.reply = protocol.Message.with-data DeviceIDs.MT raw
  updater.update-device-id comms vending
  check "serial identity" vending.vending-id 0x2B000193F9
  saved := store.values["identity"]
  check "full serial persisted" saved["serial"] 88_103_417
  check "device ID persisted alongside serial" saved["id"] 19_315_383
  check "one record per change" store.writes 2
  frame := VendingProtocol.get-stat-data vending.vending-id 20 3.7
  check "kiosk serial bytes" frame[..5] #[0xF9, 0x93, 1, 0, 0x2B]

  identity = VendingIdentity store
  vending = Vending identity.vending-id
  updater = VendingUpdater --identity-cache=identity
  check "serial restored before refresh" vending.vending-id 0x2B000193F9
  updater.update-device-id comms vending
  check "cached serial still refreshed" comms.requests 3
  check "unchanged identity avoids flash write" store.writes 2

  comms.reply = ids-reply --id=42
  updater.update-device-id comms vending
  check "missing serial preserves serial prefix" vending.vending-id 0x2B000193F9
  check "current ID still refreshed" identity.device-id 42
  comms.reply = ids-reply --id=0 --serial=0
  updater.update-device-id comms vending
  check "zero values preserve identity" identity.serial 88_103_417
  check "zero values avoid flash write" store.writes 3
  comms.reply = null
  updater.update-device-id comms vending
  comms.reply = protocol.Message 5
  updater.update-device-id comms vending
  comms.reply = ids-reply --serial=99
  comms.reply.header-add-data-uint8 4 5
  updater.update-device-id comms vending
  check "failed refresh preserves NVM" store.writes 3

  comms.reply = ids-reply --serial=1_000_000
  updater.update-device-id comms vending
  check "zero suffix is a valid serial" vending.vending-id 0x2B00000000
  check "full zero-suffix serial restored" (VendingIdentity store).serial 1_000_000

  // A failed write must not stop live replies or suppress the next save attempt.
  store.fail = true
  comms.reply = ids-reply --serial=88_103_417
  updater.update-device-id comms vending
  check "live identity survives storage failure" vending.vending-id 0x2B000193F9
  check "failed write leaves old durable serial" (VendingIdentity store).serial 1_000_000
  check "failed write retains new serial for retry" identity.serial 88_103_417
  store.fail = false
  comms.reply = ids-reply
  updater.update-device-id comms vending
  check "missing fields still retry failed save" (VendingIdentity store).serial 88_103_417

  malformed := protocol.Data
  malformed.add-data DeviceIDs.ID #[]
  malformed.add-data-uint DeviceIDs.SERIAL 99
  comms.reply = protocol.Message.with-data DeviceIDs.MT malformed
  updater.update-device-id comms vending
  check "malformed ID does not discard valid serial" identity.serial 99

  store.values["identity"] = {"id": "bad", "serial": -1}
  check "invalid stored fields ignored" (VendingIdentity store).vending-id 0x1B00000000
  store.values["identity"] = "bad"
  check "invalid record ignored" (VendingIdentity store).vending-id 0x1B00000000
  print "vending persistent identity tests passed"
