import ..protocol as protocol
import fixed-point show FixedPoint

// Auto generated class for protocol message
class DrawBitmap extends protocol.Data:

  static MT := 10011

  static PAGE-ID := 3
  static REDRAW-TYPE := 6
  static X := 21
  static Y := 22
  static WIDTH := 23
  static HEIGHT := 24
  static DATA := 25

  constructor:
    super

  // GET
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static get-msg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  // SET
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static set-msg -> protocol.Message:
    msg := protocol.Message MT
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
  static unsubscribe-msg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-UNSUBSCRIBE
    return msg

  // DO
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static do-msg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
    return msg

  page-id -> int:
    return get-data-uint PAGE-ID

  redraw-type -> int:
    return get-data-uint REDRAW-TYPE

  x -> int:
    return get-data-uint X

  y -> int:
    return get-data-uint Y

  width -> int:
    return get-data-uint WIDTH

  height -> int:
    return get-data-uint HEIGHT

  data -> int:
    return get-data-uint DATA

  stringify -> string:
    return {
      "Page ID": page-id,
      "Redraw Type": redraw-type,
      "X": x,
      "Y": y,
      "Width": width,
      "Height": height,
      "Data": data,
    }.stringify
