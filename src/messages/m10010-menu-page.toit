import ..protocol as protocol

class MenuPage extends protocol.Data:
  static MT := 10010
  static ITEM_COUNT := 2
  static PAGE_ID := 3
  static PAGE_TITLE := 4
  static INITIAL_ITEM_SELECTION := 5
  // TODO maybe just include a different way to make this data!
  static ITEM_1 := 100
  static ITEM_2 := 101
  static ITEM_3 := 102
  static ITEM_4 := 103
  static ITEM_5 := 104
  static ITEM_6 := 105
  static ITEM_7 := 106
  static ITEM_8 := 107
  static ITEM_9 := 108
  static ITEM_10 := 109
  static ITEM_11 := 110
  static ITEM_12 := 111
  static ITEM_13 := 112
  static ITEM_14 := 113
  static ITEM_15 := 114
  static ITEM_16 := 115
  static ITEM_17 := 116
  static ITEM_18 := 117
  static ITEM_19 := 118
  static ITEM_20 := 119

  static toMsg --pageId/int --pageTitle/string?=null --initialItemSelection/int?=null --items/List -> protocol.Message:
    msg := protocol.Message MT
    msg.data.addDataUint8 ITEM_COUNT items.size
    msg.data.addDataUint PAGE_ID pageId
    if pageTitle:
      msg.data.addDataAscii PAGE_TITLE pageTitle
    if initialItemSelection:
      msg.data.addDataUint8 INITIAL_ITEM_SELECTION initialItemSelection
    i := 0
    items.do: 
     msg.data.addDataAscii (ITEM_1 + i) it
     i += 1     
    return msg

  constructor.fromData data/protocol.Data:
    super.fromData data

  itemCount -> int:
    return getDataUint8 ITEM_COUNT

  pageId -> int:
    return getDataUint PAGE_ID

  pageTitle -> string:
    return getDataAscii PAGE_TITLE

  initialItemSelection -> int:
    return getDataUint8 INITIAL_ITEM_SELECTION

  items -> List:
    items := []
    i := 0
    20.repeat:
      item := getDataAscii (ITEM_1 + it)
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
