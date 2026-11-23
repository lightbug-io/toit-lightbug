// Tests calibration guidance and charging restoration.
// Run as part of the RH2 motion host test suite.

import motion-fusion show Vector3
import ...examples.motion.calibration show Guide charge-limit-request
import ...examples.motion.calibration show Capture Correction Quality CalibrationStore
import .magnetic-fixture show points
import lightbug.messages as messages
import lightbug.protocol as protocol
import monitor

class Ink:
  pages := []
  present id title lines: pages.add [id, title, lines]
  show id title lines: pages.add [id, title, lines]

class Keys:
  choices/List
  index/int := 0
  constructor .choices:
  clear:
  wait page/int -> int:
    if index >= choices.size: throw "Unexpected calibration prompt"
    choice := choices[index]
    index++
    return choice

class Bucket:
  value/any := null
  pending/any := null
  writes/int := 0
  fail/bool := false
  get key [--if-absent]:
    current := key == "paused-charge-limit" ? pending : value
    return current == null ? if-absent.call key : current
  operator []= key value:
    if fail: throw "FLASH_UNAVAILABLE"
    if key == "paused-charge-limit": pending = value
    else: this.value = value
    writes++

class TestGuide extends Guide:
  passes/int := 0
  bad-validation/bool := false
  cancel/bool := false
  constructor screen keys store:
    super null null screen keys store
  calibrate_ -> Quality: return collect_ (Capture)
  collect_ capture/Capture -> Quality:
    if cancel: throw "Calibration cancelled"
    passes++
    samples := points
    samples.size.repeat: | index |
      raw := samples[index]
      v := bad-validation and index % 5 == 0 ? (raw.plus (Vector3 30 0 0)) : raw
      capture.add v
    return capture.fit-checked --allow-imperfect

class ChargeComms:
  limit/int := 1536
  fail-restore/bool := false
  send request --now --withLatch --timeout:
    result := monitor.Latch
    response := protocol.Message messages.ChargerSettings.MT
    method := request.header-get-data-uint protocol.Header.TYPE_MESSAGE_METHOD
    if method == protocol.Header.METHOD_SET:
      value := request.data.get-data-uint16 messages.ChargerSettings.CHARGE-CURRENT-LIMIT
      if fail-restore and value != 0: response.header-add-data-uint8 protocol.Header.TYPE_MESSAGE_STATUS 1
      else: limit = value
    else:
      response.data.add-data-uint16 messages.ChargerSettings.CHARGE-CURRENT-LIMIT limit
    result.set response
    return result

class ChargeDevice:
  comms := ChargeComms

class ChargingGuide extends Guide:
  cancel/bool := false
  charge/ChargeDevice
  constructor .charge:
    super charge null (Ink) (Keys []) (CalibrationStore (Bucket))
  collect_ capture/Capture -> Quality:
    if charge.comms.limit != 0: throw "Charging was not paused"
    if cancel: throw "Calibration cancelled"
    (points).do: capture.add it
    return capture.fit-checked --allow-imperfect

main:
  [0, 1024].do: | limit |
    request := charge-limit-request limit
    if request.type != messages.ChargerSettings.MT: throw "Wrong charger message type"
    if (request.header-get-data-uint protocol.Header.TYPE_MESSAGE_METHOD) != protocol.Header.METHOD_SET: throw "Wrong charger method"
    if request.header-has-data protocol.Header.TYPE_FORWARD_TO: throw "Charger request must be local to P1"
    value := request.data.get-data messages.ChargerSettings.CHARGE-CURRENT-LIMIT
    if value.size != 2 or (request.data.get-data-uint16 messages.ChargerSettings.CHARGE-CURRENT-LIMIT) != limit:
      throw "Charge limit requires two-byte mA encoding"
  charge := ChargeDevice
  charged-guide := ChargingGuide charge
  if (charged-guide.calibrate_).correction == null or charge.comms.limit != 1536: throw "Charge limit not restored"
  charged-guide.cancel = true
  if (catch: charged-guide.calibrate_) != "Calibration cancelled" or charge.comms.limit != 1536: throw "Charge limit not restored after cancel"
  charge.comms.fail-restore = true
  if (catch: charged-guide.calibrate_) == null or not charged-guide.restore-failed_: throw "Charge restore failure not reported"
  // A new app launch recovers the persisted limit before even offering skip.
  interrupted := Bucket
  interrupted.pending = 1536
  charge.comms.limit = 0
  charge.comms.fail-restore = false
  recovery := Guide charge null (Ink) (Keys [1]) (CalibrationStore interrupted)
  if recovery.run != null or charge.comms.limit != 1536 or interrupted.pending != null:
    throw "Interrupted calibration did not recover on app launch"
  interrupted.pending = 1536
  charge.comms.limit = 0
  charge.comms.fail-restore = true
  recovery = Guide charge null (Ink) (Keys [1]) (CalibrationStore interrupted)
  if (catch: recovery.run) == null or not recovery.restore-failed_ or interrupted.pending != 1536:
    throw "Failed recovery lost its original limit"
  charge.comms.fail-restore = false
  unavailable := Bucket
  unavailable.fail = true
  charge.comms.limit = 1536
  recovery = Guide charge null (Ink) (Keys []) (CalibrationStore unavailable)
  if (catch: recovery.calibrate_) != "FLASH_UNAVAILABLE" or charge.comms.limit != 1536 or unavailable.pending != null:
    throw "Failed recovery storage changed charger state"
  no-storage := Guide charge null (Ink) (Keys []) null
  if (catch: no-storage.calibrate_) != "Charge recovery storage unavailable":
    throw "Calibration paused charging without a durable recovery record"
  ink := Ink
  keys := Keys [1]
  guide := TestGuide ink keys null
  if guide.run != null or guide.passes != 0: throw "Skip collected or enabled heading"
  bucket := Bucket
  store := CalibrationStore bucket
  keys = Keys [0, 0]
  guide = TestGuide ink keys store
  correction := guide.run
  if correction == null or bucket.writes != 1 or guide.passes != 1:
    throw "Valid fit/check/save flow failed"
  if ink.pages.last[1] != "Saved": throw "Save success not displayed"
  saved := bucket.value
  guide = TestGuide ink (Keys [0]) store
  if guide.run == null or guide.passes != 0 or bucket.writes != 1:
    throw "Saved calibration not reused without another write"
  guide = TestGuide ink (Keys [2, 1]) store
  guide.bad-validation = true
  if guide.run != null or bucket.value != saved or bucket.writes != 1:
    throw "Skipped calibration replaced saved coefficients"
  bucket = Bucket
  bucket.fail = true
  guide = TestGuide ink (Keys [0, 0, 0]) (CalibrationStore bucket)
  if guide.run == null or bucket.writes != 0 or ink.pages.last[1] != "Save failed":
    throw "Session-only fallback claimed a persisted calibration"
  guide = TestGuide ink (Keys [0]) null
  guide.cancel = true
  if guide.run != null: throw "Cancelled calibration enabled heading"
  print "Calibration guide skip, capture, validation, save, reuse, and failure tests passed"
