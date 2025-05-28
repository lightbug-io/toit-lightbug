import ..protocol as protocol
import fixed-point show FixedPoint

// Auto generated class for protocol message
class UbloxProtectionLevel extends protocol.Data:

  static MT := 53

  static PL-VALID := 1
  static PL-X := 2
  static PL-Y := 3
  static PL-Z := 4
  static HORIZONTAL-ORIENTATION := 5
  static TMIR-COEFFICIENT := 6
  static TMIR-EXPONENT := 7

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

  pl-valid -> int:
    return get-data-uint PL-VALID

  pl-x -> int:
    return get-data-uint PL-X

  pl-y -> int:
    return get-data-uint PL-Y

  pl-z -> int:
    return get-data-uint PL-Z

  horizontal-orientation -> int:
    return get-data-uint HORIZONTAL-ORIENTATION

  tmir-coefficient -> int:
    return get-data-uint TMIR-COEFFICIENT

  tmir-exponent -> int:
    return get-data-int TMIR-EXPONENT

  stringify -> string:
    return {
      "PL Valid": pl-valid,
      "PL X": pl-x,
      "PL Y": pl-y,
      "PL Z": pl-z,
      "Horizontal Orientation": horizontal-orientation,
      "TMIR Coefficient": tmir-coefficient,
      "TMIR Exponent": tmir-exponent,
    }.stringify
