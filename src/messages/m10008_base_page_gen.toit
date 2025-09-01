import ..protocol as protocol

// Auto generated class for protocol message
class BasePage extends protocol.Data:

  static MT := 10008
  static MT_NAME := "BasePage"

  static PAGE-ID := 3
  static STATUS-BAR-ENABLE := 5
  static REDRAW-TYPE := 6
  static REDRAW-TYPE_AUTO := 0
  static REDRAW-TYPE_PARTIALREDRAW := 1
  static REDRAW-TYPE_FULLREDRAW := 2
  static REDRAW-TYPE_BUFFERONLY := 3
  static REDRAW-TYPE_FULLREDRAWWITHOUTCLEAR := 4
  static REDRAW-TYPE_CLEARDONTDRAW := 5

  static REDRAW-TYPE_STRINGS := {
    0: "Auto",
    1: "PartialRedraw",
    2: "FullRedraw",
    3: "BufferOnly",
    4: "FullRedrawWithoutClear",
    5: "ClearDontDraw",
  }

  static redraw-type-from-int value/int -> string:
    return REDRAW-TYPE_STRINGS.get value --if-absent=(: "unknown")


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
  static data --page-id/int?=null --status-bar-enable/bool?=null --redraw-type/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if page-id != null: data.add-data-uint PAGE-ID page-id
    if status-bar-enable != null: data.add-data-bool STATUS-BAR-ENABLE status-bar-enable
    if redraw-type != null: data.add-data-uint REDRAW-TYPE redraw-type
    return data

  /**
  Creates a Base Page message without a specific method.
  
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
    Show the status bar
  */
  status-bar-enable -> bool:
    return get-data-bool STATUS-BAR-ENABLE

  /**
    Redraw Type
    
    Valid values:
    - REDRAW-TYPE_AUTO (0): Automatically choose the redraw type
    - REDRAW-TYPE_PARTIALREDRAW (1): Only redraw the parts of the screen changed in this message
    - REDRAW-TYPE_FULLREDRAW (2): Clear the screen buffer, and redraw the entire screen
    - REDRAW-TYPE_BUFFERONLY (3): Update the buffer only, do not redraw
    - REDRAW-TYPE_FULLREDRAWWITHOUTCLEAR (4): Redraw the entire screen, without clearing the buffer
    - REDRAW-TYPE_CLEARDONTDRAW (5): Clear the screen buffer, but don't redraw
  */
  redraw-type -> int:
    return get-data-uint REDRAW-TYPE

  stringify -> string:
    return {
      "Page ID": page-id,
      "Status bar Enable": status-bar-enable,
      "Redraw Type": redraw-type,
    }.stringify
