import ..protocol as protocol

class ButtonPress extends protocol.Data:
  static MT := 10013
  static PAGE_ID := 3
  static BUTTON_ID := 4
  static SELECTION_ID := 5

  constructor.fromData data/protocol.Data:
    super.fromData data

  pageId -> int:
    return getDataUint PAGE_ID

  buttonId -> int:
    return getDataUint BUTTON_ID

  selectionId -> int:
    return getDataUint SELECTION_ID

  stringify -> string:
    return {
      "Page ID": pageId,
      "Button ID": buttonId,
      "Selection ID": selectionId,
    }.stringify
