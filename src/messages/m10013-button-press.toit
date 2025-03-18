import ..protocol as protocol

class ButtonPress extends protocol.Data:
  static MT := 10013
  static PAGE-ID := 3
  static BUTTON-ID := 4
  static SELECTION-ID := 5

  constructor.fromData data/protocol.Data:
    super.fromData data

  pageId -> int:
    return getDataUint PAGE-ID

  buttonId -> int:
    return getDataUint BUTTON-ID

  selectionId -> int:
    return getDataUint SELECTION-ID

  stringify -> string:
    return {
      "Page ID": pageId,
      "Button ID": buttonId,
      "Selection ID": selectionId,
    }.stringify
