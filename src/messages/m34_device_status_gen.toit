import ..protocol as protocol
import fixed-point show FixedPoint

// Auto generated class for protocol message
class DeviceStatus extends protocol.Data:

  static MT := 34

  static BATTERY := 1
  static SIGNAL-STRENGTH := 2
  static MODE := 3
  static NETWORK-TYPE := 4
  static NETWORK-MNC := 5
  static NETWORK-MCC := 6
  static FIRMWARE-VERSION := 7

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  // GET
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static get-msg --data/protocol.Data? -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  // SET
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static set-msg --data/protocol.Data? -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
    return msg

  // SUBSCRIBE to a message with an optional interval in milliseconds
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static subscribe-msg --ms/int -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SUBSCRIBE
    if ms != null:
      msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-INTERVAL ms
    return msg

  // UNSUBSCRIBE
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static unsubscribe-msg --data/protocol.Data? -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-UNSUBSCRIBE
    return msg

  // DO
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static do-msg --data/protocol.Data? -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
    return msg

  battery -> int:
    return get-data-uint BATTERY

  signal-strength -> int:
    return get-data-uint SIGNAL-STRENGTH

  mode -> int:
    return get-data-uint MODE

  network-type -> int:
    return get-data-uint NETWORK-TYPE

  network-mnc -> int:
    return get-data-uint NETWORK-MNC

  network-mcc -> int:
    return get-data-uint NETWORK-MCC

  firmware-version -> int:
    return get-data-uint FIRMWARE-VERSION

  stringify -> string:
    return {
      "Battery": battery,
      "Signal Strength": signal-strength,
      "Mode": mode,
      "Network type": network-type,
      "Network MNC": network-mnc,
      "Network MCC": network-mcc,
      "Firmware Version": firmware-version,
    }.stringify
