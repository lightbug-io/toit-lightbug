import lightbug.devices as devices
import lightbug.messages as messages
import lightbug.protocol as protocol
import lightbug.util.bytes show stringify-all-bytes
import lightbug.util.docs show jag-define message-bytes-to-docs-url

// Reproduces a reported buzzer bug: sending a new BuzzerControl (MT42) while
// a previous one is still running does not override it, so the new sound is
// silently dropped until the first buzzer's duration elapses. Fixed in a
// future firmware release; this example proves the bug and the workaround
// below for older firmware still in the field.
//
// TODO once fixed in FW, this and the nearby examples should be updated (and this comment)
//
// Run on device: add -D cancel-first=1 to send a 0-duration BuzzerControl
// before the second sound. That is the current workaround, and it should
// make the Siren audible immediately instead of being dropped.
//
// No local WiFi/BLE to the device? Start `squish chasm proxy --device <ID>`
// and run m42_buzzer_override.proxy.toit (or .proxy-cancel-first.toit for the
// workaround) instead (jag's -D isn't supported with -d host yet, so those
// variants hardcode devices.Proxy / the workaround). These are also the first
// examples of the squish chasm proxy transport (devices.Proxy).

BEEP-DURATION-MS ::= 10_000
OVERRIDE-AFTER-MS ::= 3_000
SIREN-DURATION-MS ::= 5_000
INTENSITY ::= 1

main:
  run (devices.I2C --background=false --log-level=devices.ERROR-LEVEL)

run device/devices.Device --cancel-first/bool=(define-present "cancel-first"):

  beep := buzzer-msg --sound-type=messages.BuzzerControl.SOUND-TYPE_BEEP-BEEP --duration-ms=BEEP-DURATION-MS
  cancel := buzzer-msg --sound-type=messages.BuzzerControl.SOUND-TYPE_BEEP-BEEP --duration-ms=0
  siren := buzzer-msg --sound-type=messages.BuzzerControl.SOUND-TYPE_SIREN --duration-ms=SIREN-DURATION-MS

  print "Buzzer override demo"
  print "Sends a $(BEEP-DURATION-MS)ms Beep Beep, then a Siren $(OVERRIDE-AFTER-MS)ms later while the Beep Beep is still running."
  print "Expected: the Siren should be heard immediately."
  print "Bug: the Siren is silently dropped until the Beep Beep's duration elapses."
  if cancel-first:
    print "Workaround enabled: a 0-duration BuzzerControl will be sent first to cancel the active Beep Beep."
  print ""

  print-frame "MT42 SET BuzzerControl: Beep Beep, duration=$(BEEP-DURATION-MS)ms" beep
  if cancel-first:
    print-frame "MT42 SET BuzzerControl: duration=0 (cancels active buzzer)" cancel
  print-frame "MT42 SET BuzzerControl: Siren, duration=$(SIREN-DURATION-MS)ms" siren

  send-and-wait device "Beep Beep" beep
  sleep --ms=OVERRIDE-AFTER-MS

  if cancel-first:
    send-and-wait device "cancel active buzzer" cancel

  send-and-wait device "Siren" siren

  print ""
  print "Listen to the device now."
  print "Without -D cancel-first=1 the Siren should not be audible until the Beep Beep's $(BEEP-DURATION-MS)ms duration elapses."

buzzer-msg --sound-type/int --duration-ms/int -> protocol.Message:
  data := messages.BuzzerControl.data --duration=duration-ms --sound-type=sound-type --intensity=INTENSITY
  return messages.BuzzerControl.set-msg --base-data=data

print-frame label/string msg/protocol.Message:
  bytes := msg.bytes-for-protocol
  print "$label"
  print "  bytes: $(stringify-all-bytes bytes)"
  print "  parse: $(message-bytes-to-docs-url bytes)"
  print ""

send-and-wait device/devices.Device label/string msg/protocol.Message:
  print "Sending $label"
  (device.comms.send msg
      --now=true
      --withLatch=true
      --timeout=(Duration --s=15)
      --onAck=(:: |ack| print "  ack: $ack")
      --onNack=(:: |nack| print "  nack: $nack")
      --onResponse=(:: |response| print "  response: $response")
      --onError=(:: |error| print "  error: $error")
      --onTimeout=(:: |id| print "  timeout waiting for message id $id")).get

define-present key/string -> bool:
  return (jag-define key) != null
