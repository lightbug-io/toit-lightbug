// Host-side PR3 QC runner. Requires jag with Toit v2.0.0-alpha.198 or newer
// and the USB V3 base application.
//
// Run from examples after deploying the base snapshot:
//   jag toit run host/qc.toit /dev/ttyACM0

import io
import lightbug.messages as messages
import lightbug.modules.comms.comms show Comms
import lightbug.modules.comms.console-framing show HexLineReader HexLineWriter
import lightbug.modules.comms.transport show V3Transport
import lightbug.protocol as protocol
import uart

P1-LINK ::= protocol.Header.LINK_ID_P1
STATUS-LED-CONTROL-MT ::= 51
STATUS-LED-DURATION-MS ::= 24 * 60 * 60 * 1_000
HANDSHAKE-ATTEMPTS ::= 3
QC-OPEN-ATTEMPTS ::= 60

main args:
  if args.size != 1:
    print "Usage: toit run host/qc.toit <serial-port>"
    return

  // The dock can be connected before P1/P2 is ready, or unplugged mid-run.
  // Recreate the OS serial handle and Comms instance for every session.
  while true:
    e := catch --trace:
      run-qc-connection args[0]
    if e:
      print "❌ PR3 QC session error: $e; restarting..."
    else:
      print "⚠️ PR3 QC session ended; restarting..."
    sleep --ms=1_000

run-qc-connection path/string:
  port := uart.Port path --baud-rate=115200
  transport := HostSerialTransport port
  comms := Comms
      --transport=transport
      --open=false
      --background=false
      --stopInboundOnDisconnect=true
  print "PR3 USB QC runner connected to $path"
  e := catch:
    run-qc-session comms transport
  // This is harmless when the OS has already invalidated the handle, and
  // ensures the next retry never shares the old serial connection.
  catch: transport.disconnect
  if e: throw e

run-qc-session comms transport/HostSerialTransport:
  device-id := get-p1-device-id-after-attempts comms
  if device-id == 0:
    print "❌ No P1 DeviceIDs response through the dock; restarting handshake"
    return
  print "✅ P1 detected: device-id=$device-id"
  set-p1-status-leds comms --led1=1
  play-p1-status-beeps comms 1

  if not open-p1-link-after-attempts comms:
    print "❌ P1 link did not open; restarting handshake"
    return
  print "✅ P1 link opened"

  if not enable-p1-cloud-link-after-attempts comms:
    print "❌ P1 cloud link did not enable; restarting handshake"
    return
  print "✅ P1 cloud link enabled"
  set-p1-status-leds comms --led1=1 --led2=1
  play-p1-status-beeps comms 2

  inbox := comms.inbox "qc"
  if not wait-for-qc-open-ack comms inbox transport:
    print "❌ QC Open was not acknowledged by the server; restarting handshake"
    return
  print "✅ QC app opened by server"
  // P1 has just completed the P1 -> P2 -> USB forwarding of the server's
  // Open ACK. Give its I2C command path a brief idle window before issuing
  // the local LED/buzzer milestone command.
  sleep --ms=300
  set-p1-status-leds comms --led1=1 --led2=1 --led3=1
  play-p1-status-beeps comms 3
  print "Waiting for server-side QC pass status messages..."
  while true:
    message := receive-qc-message inbox transport
    if is-qc-pass-message message:
      print "✅ QC passed"
      set-p1-status-leds comms --led1=1 --led2=1 --led3=1 --led4=1

// Match the Viper jig: keep asking until the server confirms it has opened the
// QC app, then restart the entire P1/link/cloud sequence after one minute.
// This recovers a P1 cloud link that accepted its enable command but never
// established a usable Chasm connection.
wait-for-qc-open-ack comms inbox transport/HostSerialTransport -> bool:
  attempts := 0
  while attempts < QC-OPEN-ATTEMPTS:
    attempts++
    if attempts % 5 == 1:
      print "⏳ Sending QC Open to Chasm ($attempts/$QC-OPEN-ATTEMPTS)"
    send-qc-open comms
    message := try-receive-qc-message inbox transport --timeout-ms=1_000
    if message != null and is-qc-open-message message:
      return true
  return false

receive-qc-message inbox transport/HostSerialTransport -> protocol.Message:
  while true:
    message := try-receive-qc-message inbox transport --timeout-ms=500
    if message != null: return message

try-receive-qc-message inbox transport/HostSerialTransport --timeout-ms/int -> protocol.Message?:
  message := null
  // Periodically wake up instead of waiting indefinitely in Channel.receive,
  // so a USB EIO can end this session and reopen the serial port.
  e := catch:
    with-timeout --ms=timeout-ms:
      message = inbox.receive
  if e:
    if not transport.connected:
      throw "USB serial link disconnected"
    return null
  if not transport.connected:
    throw "USB serial link disconnected"
  return message

get-p1-device-id-after-attempts comms -> int:
  attempts := 0
  while attempts < HANDSHAKE-ATTEMPTS:
    device-id := get-p1-device-id comms
    if device-id != 0: return device-id
    attempts++
    print "⏳ Waiting for P1 DeviceIDs ($attempts/$HANDSHAKE-ATTEMPTS)"
    sleep --ms=1_000
  return 0

open-p1-link-after-attempts comms -> bool:
  attempts := 0
  while attempts < HANDSHAKE-ATTEMPTS:
    if try-open-p1-link comms: return true
    attempts++
    print "⏳ Opening P1 link ($attempts/$HANDSHAKE-ATTEMPTS)"
    sleep --ms=1_000
  return false

enable-p1-cloud-link-after-attempts comms -> bool:
  attempts := 0
  while attempts < HANDSHAKE-ATTEMPTS:
    if try-enable-p1-cloud-link comms: return true
    attempts++
    print "⏳ Enabling P1 cloud link ($attempts/$HANDSHAKE-ATTEMPTS)"
    sleep --ms=1_000
  return false

get-p1-device-id comms -> int:
  request := messages.DeviceIDs.get-msg
  forward-directly-to-p1 request
  response := (comms.send request --now=true --withLatch=true --timeout=(Duration --s=5)).get
  if response == false or response == null or response.type != messages.DeviceIDs.MT:
    return 0
  return (messages.DeviceIDs.from-data response.data).id

try-open-p1-link comms -> bool:
  request := messages.Open.msg --data=null
  forward-directly-to-p1 request
  return response-ok (comms.send request --now=true --withLatch=true --timeout=(Duration --s=5)).get

try-enable-p1-cloud-link comms -> bool:
  data := protocol.Data
  data.add-data-bool messages.LinkControl.ENABLE true
  request := messages.LinkControl.set-msg --base-data=data
  forward-directly-to-p1 request
  response := (comms.send request --now=true --withLatch=true --timeout=(Duration --s=5)).get
  if not response-ok response:
    return false
  print "P1 cloud-link enable response: type=$(response.type) response-to=$(response.response-to) status=$(response.msg-status) forwarded-for=$(response.forwarded-for) bytes=$(response.bytes)"
  return true

send-qc-open comms:
  request := messages.Open.msg --data=null
  // Same Viper QC fields: server starts the QC app and expires it today.
  request.header-add-data-string 50 "qc"
  request.header-add-data-string 51 "day"
  // P2 relays this via P1; P1 retains Forward To=Chasm for its cloud link.
  request.header-add-data-uint8 protocol.Header.TYPE_FORWARD_TO protocol.Header.LINK_ID_CHASM
  comms.send request --now=true

forward-directly-to-p1 request/protocol.Message -> none:
  request.header-add-data-uint8 protocol.Header.TYPE_FORWARD_TO P1-LINK

// P1's Status LED Control is not generated in the current Toit protocol
// package, so use its established V3 layout from the Viper jig. The timeout
// keeps the selected state visible for one day.
set-p1-status-leds comms --led1/int=0 --led2/int=0 --led3/int=0 --led4/int=0:
  data := protocol.Data
  data.add-data-uint8 5 led1
  data.add-data-uint8 6 led2
  data.add-data-uint8 7 led3
  data.add-data-uint8 8 led4
  request := protocol.Message.with-data STATUS-LED-CONTROL-MT data
  request.header-add-data-uint8 protocol.Header.TYPE_MESSAGE_METHOD protocol.Header.METHOD_SET
  request.header-add-data-uint32 protocol.Header.TYPE_SUBSCRIPTION_DURATION STATUS-LED-DURATION-MS
  forward-directly-to-p1 request
  comms.send request --now=true

// Audible equivalents of the Viper jig's LED milestones. Send one Buzzer
// Sequence command instead of individual Buzzer Control commands: P1 itself
// plays the silent intervals, so USB/I2C scheduling cannot merge the beeps.
play-p1-status-beeps comms count/int:
  frequencies := []
  timings := []
  count.repeat: | index |
    frequencies.add 5.0
    timings.add 100
    if index + 1 < count:
      frequencies.add 0.0
      timings.add 125
  data := protocol.Data
  data.add-data-list-float32 messages.BuzzerSequence.FREQUENCIES frequencies
  data.add-data-list-uint16 messages.BuzzerSequence.TIMINGS timings
  sequence := messages.BuzzerSequence.set-msg --base-data=data
  forward-directly-to-p1 sequence
  // P1 plays this command synchronously and ACKs only after the whole
  // sequence. Waiting therefore makes the local QC milestone audible and
  // diagnosable instead of silently queueing it behind another P1 command.
  response := (comms.send sequence --now=true --withLatch=true --timeout=(Duration --s=5)).get
  if response-ok response:
    print "✅ P1 played $count QC status beep(s)"
  else:
    // The beep may still have played: this is the P1 -> P2 -> USB ACK route,
    // not the command-delivery path. Keep it diagnostic-only.
    print "⚠️ No P1 ACK for $count QC status beep(s); command may still have played"

is-qc-open-message message/protocol.Message -> bool:
  e := catch:
    return message.header.data.has-data 50 and (message.header.data.get-data-ascii 50) == "qc"
  return false

is-qc-pass-message message/protocol.Message -> bool:
  // PR3's server pass signal turns on status LED 4. Also retain the Viper
  // green LED-control form so this host peer remains compatible with it.
  STATUS-LED-4-FIELD ::= 8
  LED-CONTROL-MT ::= 52
  LED-CONTROL-GREEN-FIELD ::= 3
  e := catch:
    if message.type == STATUS-LED-CONTROL-MT:
      return message.data.has-data STATUS-LED-4-FIELD and
          (message.data.get-data-uint8 STATUS-LED-4-FIELD) > 0
    return message.type == LED-CONTROL-MT and
        message.data.has-data LED-CONTROL-GREEN-FIELD and
        (message.data.get-data-uint8 LED-CONTROL-GREEN-FIELD) > 0
  return false

response-ok response -> bool:
  if response == false or response == null:
    return false
  return response.msg-status == null or response.msg-status == protocol.Header.STATUS_OK

class HostSerialTransport implements V3Transport:
  port_ /uart.Port
  reader_ /io.Reader
  writer_ /io.Writer
  state_ /SerialConnectionState

  constructor port/uart.Port:
    port_ = port
    state_ = SerialConnectionState
    reader_ = HexLineReader (DisconnectingReader port.in state_)
    writer_ = HexLineWriter port.out

  prefix -> bool: return false
  connected -> bool: return state_.connected
  connect -> none:
  disconnect -> none:
    state_.mark-disconnected
    port_.close
  in -> io.Reader: return reader_
  out -> io.Writer: return writer_

  mark-disconnected -> none:
    state_.mark-disconnected

class SerialConnectionState:
  connected_ /bool := true

  connected -> bool: return connected_
  mark-disconnected -> none: connected_ = false

// An unplugged host UART throws EIO from Reader.read. Turn that into transport
// state before rethrowing, allowing Comms and the outer QC session to stop
// cleanly instead of restarting the inbound worker against a dead descriptor.
class DisconnectingReader extends io.Reader with io.InMixin:
  source_ /io.Reader
  state_ /SerialConnectionState

  constructor source/io.Reader state/SerialConnectionState:
    source_ = source
    state_ = state

  read_ -> ByteArray?:
    e := catch:
      return source_.read
    if e:
      state_.mark-disconnected
      throw e
    return null
