import ..protocol as protocol

class ButtonPress extends protocol.Data:
  static MT := 10013
  static PAGE-ID := 3
  static BUTTON-ID := 4
  static SELECTION-ID := 5

  constructor.from-data data/protocol.Data:
    super.from-data data

  page-id -> int:
    return get-data-uint PAGE-ID

  button-id -> int:
    return get-data-uint BUTTON-ID

  selection-id -> int:
    return get-data-uint SELECTION-ID

  stringify -> string:
    return {
      "Page ID": page-id,
      "Button ID": button-id,
      "Selection ID": selection-id,
    }.stringify
