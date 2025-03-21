import ..protocol as protocol

class MenuPage extends protocol.Data:
  static MT := 10010
  static PAGE-ID := 3
  static PAGE-TITLE := 4
  static REDRAW-TYPE := 6
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

  static to-msg --page-id/int --page-title/string?=null --item-initial-selection/int?=null --items/List --redraw-type/int=0 -> protocol.Message:
    msg := protocol.Message MT
    msg.data.add-data-uint8 ITEM-COUNT items.size
    msg.data.add-data-uint PAGE-ID page-id
    if page-title:
      msg.data.add-data-ascii PAGE-TITLE page-title
    if item-initial-selection:
      msg.data.add-data-uint8 INITIAL-ITEM-SELECTION item-initial-selection
    msg.data.add-data-uint REDRAW-TYPE redraw-type
    i := 0
    items.do: 
     msg.data.add-data-ascii (ITEM-1 + i) it
     i += 1     
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data

  item-count -> int:
    return get-data-uint8 ITEM-COUNT

  page-id -> int:
    return get-data-uint PAGE-ID

  page-title -> string:
    return get-data-ascii PAGE-TITLE

  item-initial-selection -> int:
    return get-data-uint8 INITIAL-ITEM-SELECTION

  items -> List:
    items := []
    i := 0
    13.repeat:
      item := get-data-ascii (ITEM-1 + it)
      if item != "":
        items.add item
    return items

  redraw-type -> int:
    return get-data-uint REDRAW-TYPE

  stringify -> string:
    return {
      "Item Count": item-count,
      "Page ID": page-id,
      "Page Title": page-title,
      "Initial Item Selection": item-initial-selection,
      "Items": items,
      "Redraw Type": redraw-type,
    }.stringify
