import ..protocol as protocol

// Auto generated class for protocol message
class GPSControl extends protocol.Data:

  static MT := 39
  static MT_NAME := "GPSControl"

  static GPS-ENABLE := 1
  static GPS-ENABLE_DISABLED := 0
  static GPS-ENABLE_ENABLED := 1
  static RTK-ENABLE-CORRECTION := 2
  static RTK-ENABLE-CORRECTION_DISABLED := 0
  static RTK-ENABLE-CORRECTION_ENABLED := 1
  static START-MODE := 3
  static START-MODE_NORMAL := 1
  static START-MODE_COLD := 2
  static START-MODE_WARM := 3
  static START-MODE_HOT := 4

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  // GET
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static get-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  // SET
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static set-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
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
  static unsubscribe-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-UNSUBSCRIBE
    return msg

  // DO
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static do-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
    return msg

  // Creates a message with no method set
  static msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-data MT data

  gps-enable -> int:
    return get-data-uint GPS-ENABLE

  rtk-enable-correction -> int:
    return get-data-uint RTK-ENABLE-CORRECTION

  start-mode -> int:
    return get-data-uint START-MODE

  stringify -> string:
    return {
      "GPS Enable": gps-enable,
      "RTK Enable Correction": rtk-enable-correction,
      "Start Mode": start-mode,
    }.stringify
