import ..protocol as protocol

class ButtonPress extends protocol.Data:
  static MT := 10013
  static PAGE_ID := 3
  static BUTTON_ID := 4
  static SELECTION_ID := 5

  static setMsg --pageId/int --buttonId/int --selectionId/int?=null -> protocol.Message:
    msg := protocol.Message MT
    msg.data.addDataUintn PAGE_ID pageId
    msg.data.addDataUintn BUTTON_ID buttonId
    if selectionId:
      msg.data.addDataUintn SELECTION_ID selectionId
    msg.header.data.addDataUint8 protocol.Header.TYPE_MESSAGE_METHOD protocol.Header.METHOD_SET
    return msg

  static getMsg --pageId/int -> protocol.Message:
    msg := protocol.Message MT
    msg.data.addDataUintn PAGE_ID pageId
    msg.header.data.addDataUint8 protocol.Header.TYPE_MESSAGE_METHOD protocol.Header.METHOD_GET
    return msg

  constructor.fromData data/protocol.Data:
    super.fromData data

  pageId -> int:
    return getDataUintn PAGE_ID

  buttonId -> int:
    return getDataUintn BUTTON_ID

  selectionId -> int:
    return getDataUintn SELECTION_ID

  stringify -> string:
    return {
      "Page ID": pageId,
      "Button ID": buttonId,
      "Selection ID": selectionId,
    }.stringify
