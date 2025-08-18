import ..protocol as protocol

// Auto generated class for protocol message
class DrawBitmap extends protocol.Data:

  static MT := 10011
  static MT_NAME := "DrawBitmap"

  static PAGE-ID := 3
  static REDRAW-TYPE := 6
  static REDRAW-TYPE_AUTO := 0
  static REDRAW-TYPE_PARTIALREDRAW := 1
  static REDRAW-TYPE_FULLREDRAW := 2
  static REDRAW-TYPE_BUFFERONLY := 3
  static REDRAW-TYPE_FULLREDRAWWITHOUTCLEAR := 4
  static REDRAW-TYPE_CLEARDONTDRAW := 5

  static REDRAW-TYPE_STRINGS := {
    0: "Auto",
    1: "PartialRedraw",
    2: "FullRedraw",
    3: "BufferOnly",
    4: "FullRedrawWithoutClear",
    5: "ClearDontDraw",
  }

  static redraw-type-from-int value/int -> string:
    return REDRAW-TYPE_STRINGS.get value --if-absent=(: "unknown")

  static X := 7
  static Y := 8
  static WIDTH := 9
  static HEIGHT := 10
  static BITMAP := 25

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  // Helper to create a data object for this message type.
  static data --page-id/int?=null --redraw-type/int?=null --x/int?=null --y/int?=null --width/int?=null --height/int?=null --bitmap/ByteArray?=null -> protocol.Data:
    data := protocol.Data
    if page-id != null: data.add-data-uint PAGE-ID page-id
    if redraw-type != null: data.add-data-uint REDRAW-TYPE redraw-type
    if x != null: data.add-data-uint X x
    if y != null: data.add-data-uint Y y
    if width != null: data.add-data-uint WIDTH width
    if height != null: data.add-data-uint HEIGHT height
    if bitmap != null: data.add-data BITMAP bitmap
    return data

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

  bitmap -> ByteArray:
    return get-data BITMAP

  stringify -> string:
    return {
      "Page ID": page-id,
      "Redraw Type": redraw-type,
      "X": x,
      "Y": y,
      "Width": width,
      "Height": height,
      "Bitmap": bitmap,
    }.stringify
