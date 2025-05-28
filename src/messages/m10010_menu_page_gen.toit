import ..protocol as protocol
import fixed-point show FixedPoint

// Auto generated class for protocol message
class MenuPage extends protocol.Data:

  static MT := 10010

  static ITEM-COUNT := 2
  static PAGE-ID := 3
  static PAGE-TITLE := 4
  static INITIAL-ITEM-SELECTION := 5
  static ITEM-1 := 100
  static ITEM-2 := 101
  static ITEM-3 := 102
  static ITEM-4 := 103
  static ITEM-5 := 104
  static ITEM-6 := 105
  static ITEM-7 := 106
  static ITEM-8 := 107
  static ITEM-9 := 108
  static ITEM-10 := 109
  static ITEM-11 := 110
  static ITEM-12 := 111
  static ITEM-13 := 112
  static ITEM-14 := 113
  static ITEM-15 := 114
  static ITEM-16 := 115
  static ITEM-17 := 116
  static ITEM-18 := 117
  static ITEM-19 := 118
  static ITEM-20 := 119

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

  item-count -> int:
    return get-data-uint ITEM-COUNT

  page-id -> int:
    return get-data-uint PAGE-ID

  page-title -> string:
    return get-data-ascii PAGE-TITLE

  initial-item-selection -> int:
    return get-data-uint INITIAL-ITEM-SELECTION

  item-1 -> string:
    return get-data-ascii ITEM-1

  item-2 -> string:
    return get-data-ascii ITEM-2

  item-3 -> string:
    return get-data-ascii ITEM-3

  item-4 -> string:
    return get-data-ascii ITEM-4

  item-5 -> string:
    return get-data-ascii ITEM-5

  item-6 -> string:
    return get-data-ascii ITEM-6

  item-7 -> string:
    return get-data-ascii ITEM-7

  item-8 -> string:
    return get-data-ascii ITEM-8

  item-9 -> string:
    return get-data-ascii ITEM-9

  item-10 -> string:
    return get-data-ascii ITEM-10

  item-11 -> string:
    return get-data-ascii ITEM-11

  item-12 -> string:
    return get-data-ascii ITEM-12

  item-13 -> string:
    return get-data-ascii ITEM-13

  item-14 -> string:
    return get-data-ascii ITEM-14

  item-15 -> string:
    return get-data-ascii ITEM-15

  item-16 -> string:
    return get-data-ascii ITEM-16

  item-17 -> string:
    return get-data-ascii ITEM-17

  item-18 -> string:
    return get-data-ascii ITEM-18

  item-19 -> string:
    return get-data-ascii ITEM-19

  item-20 -> string:
    return get-data-ascii ITEM-20

  stringify -> string:
    return {
      "Item count": item-count,
      "Page ID": page-id,
      "Page Title": page-title,
      "Initial item selection": initial-item-selection,
      "Item 1": item-1,
      "Item 2": item-2,
      "Item 3": item-3,
      "Item 4": item-4,
      "Item 5": item-5,
      "Item 6": item-6,
      "Item 7": item-7,
      "Item 8": item-8,
      "Item 9": item-9,
      "Item 10": item-10,
      "Item 11": item-11,
      "Item 12": item-12,
      "Item 13": item-13,
      "Item 14": item-14,
      "Item 15": item-15,
      "Item 16": item-16,
      "Item 17": item-17,
      "Item 18": item-18,
      "Item 19": item-19,
      "Item 20": item-20,
    }.stringify
