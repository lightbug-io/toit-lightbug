import ..protocol as protocol
import fixed-point show FixedPoint

// Auto generated class for protocol message
class TextPage extends protocol.Data:

  static MT := 10009

  static PAGE-ID := 3
  static PAGE-TITLE := 4
  static STATUS-BAR := 5
  static REDRAW-TYPE := 6
  static LINE-1 := 100
  static LINE-2 := 101
  static LINE-3 := 102
  static LINE-4 := 103
  static LINE-5 := 104

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

  page-id -> int:
    return get-data-uint PAGE-ID

  page-title -> string:
    return get-data-ascii PAGE-TITLE

  status-bar -> int:
    return get-data-uint STATUS-BAR

  redraw-type -> int:
    return get-data-uint REDRAW-TYPE

  line-1 -> string:
    return get-data-ascii LINE-1

  line-2 -> string:
    return get-data-ascii LINE-2

  line-3 -> string:
    return get-data-ascii LINE-3

  line-4 -> string:
    return get-data-ascii LINE-4

  line-5 -> string:
    return get-data-ascii LINE-5

  stringify -> string:
    return {
      "Page ID": page-id,
      "Page Title": page-title,
      "Status bar": status-bar,
      "Redraw Type": redraw-type,
      "Line 1": line-1,
      "Line 2": line-2,
      "Line 3": line-3,
      "Line 4": line-4,
      "Line 5": line-5,
    }.stringify
