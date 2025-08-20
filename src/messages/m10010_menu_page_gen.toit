import ..protocol as protocol

// Auto generated class for protocol message
class MenuPage extends protocol.Data:

  static MT := 10010
  static MT_NAME := "MenuPage"

  static PAGE-ID := 3
  static ITEM-COUNT := 30
  static INITIAL-ITEM-SELECTION := 31
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

  /**
  Creates a protocol.Data object with all available fields for this message type.
  
  This is a comprehensive helper that accepts all possible fields.
  For method-specific usage, consider using the dedicated request/response methods.
  
  Returns: A protocol.Data object with the specified field values
  */
  static data --page-id/int?=null --item-count/int?=null --initial-item-selection/int?=null --item-1/string?=null --item-2/string?=null --item-3/string?=null --item-4/string?=null --item-5/string?=null --item-6/string?=null --item-7/string?=null --item-8/string?=null --item-9/string?=null --item-10/string?=null --item-11/string?=null --item-12/string?=null --item-13/string?=null --item-14/string?=null --item-15/string?=null --item-16/string?=null --item-17/string?=null --item-18/string?=null --item-19/string?=null --item-20/string?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if page-id != null: data.add-data-uint PAGE-ID page-id
    if item-count != null: data.add-data-uint ITEM-COUNT item-count
    if initial-item-selection != null: data.add-data-uint INITIAL-ITEM-SELECTION initial-item-selection
    if item-1 != null: data.add-data-ascii ITEM-1 item-1
    if item-2 != null: data.add-data-ascii ITEM-2 item-2
    if item-3 != null: data.add-data-ascii ITEM-3 item-3
    if item-4 != null: data.add-data-ascii ITEM-4 item-4
    if item-5 != null: data.add-data-ascii ITEM-5 item-5
    if item-6 != null: data.add-data-ascii ITEM-6 item-6
    if item-7 != null: data.add-data-ascii ITEM-7 item-7
    if item-8 != null: data.add-data-ascii ITEM-8 item-8
    if item-9 != null: data.add-data-ascii ITEM-9 item-9
    if item-10 != null: data.add-data-ascii ITEM-10 item-10
    if item-11 != null: data.add-data-ascii ITEM-11 item-11
    if item-12 != null: data.add-data-ascii ITEM-12 item-12
    if item-13 != null: data.add-data-ascii ITEM-13 item-13
    if item-14 != null: data.add-data-ascii ITEM-14 item-14
    if item-15 != null: data.add-data-ascii ITEM-15 item-15
    if item-16 != null: data.add-data-ascii ITEM-16 item-16
    if item-17 != null: data.add-data-ascii ITEM-17 item-17
    if item-18 != null: data.add-data-ascii ITEM-18 item-18
    if item-19 != null: data.add-data-ascii ITEM-19 item-19
    if item-20 != null: data.add-data-ascii ITEM-20 item-20
    return data

  /**
  Creates a Menu Page message without a specific method.
  
  This is used for messages that don't require a specific method type
  (like GET, SET, SUBSCRIBE) but still need to carry data.
  
  Parameters:
  - data: Optional protocol.Data object containing message payload
  
  Returns: A Message ready to be sent
  */
  static msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-data MT data

  /**
    Page ID
  */
  page-id -> int:
    return get-data-uint PAGE-ID

  /**
    Item count
  */
  item-count -> int:
    return get-data-uint ITEM-COUNT

  /**
    An optional item to show as initially selected
  */
  initial-item-selection -> int:
    return get-data-uint INITIAL-ITEM-SELECTION

  /**
    Item 1
  */
  item-1 -> string:
    return get-data-ascii ITEM-1

  /**
    Item 2
  */
  item-2 -> string:
    return get-data-ascii ITEM-2

  /**
    Item 3
  */
  item-3 -> string:
    return get-data-ascii ITEM-3

  /**
    Item 4
  */
  item-4 -> string:
    return get-data-ascii ITEM-4

  /**
    Item 5
  */
  item-5 -> string:
    return get-data-ascii ITEM-5

  /**
    Item 6
  */
  item-6 -> string:
    return get-data-ascii ITEM-6

  /**
    Item 7
  */
  item-7 -> string:
    return get-data-ascii ITEM-7

  /**
    Item 8
  */
  item-8 -> string:
    return get-data-ascii ITEM-8

  /**
    Item 9
  */
  item-9 -> string:
    return get-data-ascii ITEM-9

  /**
    Item 10
  */
  item-10 -> string:
    return get-data-ascii ITEM-10

  /**
    Item 11
  */
  item-11 -> string:
    return get-data-ascii ITEM-11

  /**
    Item 12
  */
  item-12 -> string:
    return get-data-ascii ITEM-12

  /**
    Item 13
  */
  item-13 -> string:
    return get-data-ascii ITEM-13

  /**
    Item 14
  */
  item-14 -> string:
    return get-data-ascii ITEM-14

  /**
    Item 15
  */
  item-15 -> string:
    return get-data-ascii ITEM-15

  /**
    Item 16
  */
  item-16 -> string:
    return get-data-ascii ITEM-16

  /**
    Item 17
  */
  item-17 -> string:
    return get-data-ascii ITEM-17

  /**
    Item 18
  */
  item-18 -> string:
    return get-data-ascii ITEM-18

  /**
    Item 19
  */
  item-19 -> string:
    return get-data-ascii ITEM-19

  /**
    Item 20
  */
  item-20 -> string:
    return get-data-ascii ITEM-20

  stringify -> string:
    return {
      "Page ID": page-id,
      "Item count": item-count,
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
