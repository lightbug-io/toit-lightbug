import ..protocol as protocol

// Auto generated class for protocol message
class TextPage extends protocol.Data:

  static MT := 10009
  static MT_NAME := "TextPage"

  static PAGE-ID := 3
  static PAGE-TITLE := 4
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

  static LINE-1 := 100
  static LINE-2 := 101
  static LINE-3 := 102
  static LINE-4 := 103
  static LINE-5 := 104

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
  static data --page-id/int?=null --page-title/string?=null --status-bar-enable/bool?=null --redraw-type/int?=null --line-1/string?=null --line-2/string?=null --line-3/string?=null --line-4/string?=null --line-5/string?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if page-id != null: data.add-data-uint PAGE-ID page-id
    if page-title != null: data.add-data-ascii PAGE-TITLE page-title
    if status-bar-enable != null: data.add-data-bool STATUS-BAR-ENABLE status-bar-enable
    if redraw-type != null: data.add-data-uint REDRAW-TYPE redraw-type
    if line-1 != null: data.add-data-ascii LINE-1 line-1
    if line-2 != null: data.add-data-ascii LINE-2 line-2
    if line-3 != null: data.add-data-ascii LINE-3 line-3
    if line-4 != null: data.add-data-ascii LINE-4 line-4
    if line-5 != null: data.add-data-ascii LINE-5 line-5
    return data

  /**
  Creates a Text Page message without a specific method.
  
  This is used for messages that don't require a specific method type
  (like GET, SET, SUBSCRIBE) but still need to carry data.
  
  Parameters:
  - data: Optional protocol.Data object containing message payload
  
  Returns: A Message ready to be sent
  */
  static msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-data MT data

  /**
    ID of page to display or update
  */
  page-id -> int:
    return get-data-uint PAGE-ID

  /**
    Title of the page
  */
  page-title -> string:
    return get-data-ascii PAGE-TITLE

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

  /**
    Line 1
  */
  line-1 -> string:
    return get-data-ascii LINE-1

  /**
    Line 2
  */
  line-2 -> string:
    return get-data-ascii LINE-2

  /**
    Line 3
  */
  line-3 -> string:
    return get-data-ascii LINE-3

  /**
    Line 4
  */
  line-4 -> string:
    return get-data-ascii LINE-4

  /**
    Line 5
  */
  line-5 -> string:
    return get-data-ascii LINE-5

  stringify -> string:
    return {
      "Page ID": page-id,
      "Page Title": page-title,
      "Status bar Enable": status-bar-enable,
      "Redraw Type": redraw-type,
      "Line 1": line-1,
      "Line 2": line-2,
      "Line 3": line-3,
      "Line 4": line-4,
      "Line 5": line-5,
    }.stringify
