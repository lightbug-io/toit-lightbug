import ..protocol as protocol

class MenuPage extends protocol.Data:
  static MT := 10010
  static ITEM-COUNT := 2
  static PAGE-ID := 3
  static PAGE-TITLE := 4
  static INITIAL-ITEM-SELECTION := 5
  // TODO maybe just include a different way to make this data!
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

  static toMsg --pageId/int --pageTitle/string?=null --initialItemSelection/int?=null --items/List -> protocol.Message:
    msg := protocol.Message MT
    msg.data.add-data-uint8 ITEM-COUNT items.size
    msg.data.add-data-uint PAGE-ID pageId
    if pageTitle:
      msg.data.add-data-ascii PAGE-TITLE pageTitle
    if initialItemSelection:
      msg.data.add-data-uint8 INITIAL-ITEM-SELECTION initialItemSelection
    i := 0
    items.do: 
     msg.data.add-data-ascii (ITEM-1 + i) it
     i += 1     
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data

  itemCount -> int:
    return get-data-uint8 ITEM-COUNT

  pageId -> int:
    return get-data-uint PAGE-ID

  pageTitle -> string:
    return get-data-ascii PAGE-TITLE

  initialItemSelection -> int:
    return get-data-uint8 INITIAL-ITEM-SELECTION

  items -> List:
    items := []
    i := 0
    20.repeat:
      item := get-data-ascii (ITEM-1 + it)
      if item != "":
        items.add item
    return items

  stringify -> string:
    return {
      "Item Count": itemCount,
      "Page ID": pageId,
      "Page Title": pageTitle,
      "Initial Item Selection": initialItemSelection,
      "Items": items,
    }.stringify
