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

  item-count -> int:
    return get-data-uint ITEM-COUNT

  page-id -> int:
    return get-data-uint PAGE-ID

  page-title -> int:
    return get-data-uint PAGE-TITLE

  initial-item-selection -> int:
    return get-data-uint INITIAL-ITEM-SELECTION

  item-1 -> int:
    return get-data-uint ITEM-1

  item-2 -> int:
    return get-data-uint ITEM-2

  item-3 -> int:
    return get-data-uint ITEM-3

  item-4 -> int:
    return get-data-uint ITEM-4

  item-5 -> int:
    return get-data-uint ITEM-5

  item-6 -> int:
    return get-data-uint ITEM-6

  item-7 -> int:
    return get-data-uint ITEM-7

  item-8 -> int:
    return get-data-uint ITEM-8

  item-9 -> int:
    return get-data-uint ITEM-9

  item-10 -> int:
    return get-data-uint ITEM-10

  item-11 -> int:
    return get-data-uint ITEM-11

  item-12 -> int:
    return get-data-uint ITEM-12

  item-13 -> int:
    return get-data-uint ITEM-13

  item-14 -> int:
    return get-data-uint ITEM-14

  item-15 -> int:
    return get-data-uint ITEM-15

  item-16 -> int:
    return get-data-uint ITEM-16

  item-17 -> int:
    return get-data-uint ITEM-17

  item-18 -> int:
    return get-data-uint ITEM-18

  item-19 -> int:
    return get-data-uint ITEM-19

  item-20 -> int:
    return get-data-uint ITEM-20

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
