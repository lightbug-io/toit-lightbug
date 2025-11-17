import ..protocol as protocol

// Auto generated class for protocol message
class BasePage extends protocol.Data:

  static MT := 10008
  static MT_NAME := "BasePage"

  static PAGE-ID := 3
  static PAGE-ID_HOME-PAGE := 1

  static PAGE-ID_STRINGS := {
    1: "Home Page",
  }

  static page-id-from-int value/int -> string:
    return PAGE-ID_STRINGS.get value --if-absent=(: "unknown")

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
   * Creates a protocol.Data object with all available fields for this message type.
   *
   * This is a comprehensive helper that accepts all possible fields.
   * For method-specific usage, consider using the dedicated request/response methods.
   *
   * Returns: A protocol.Data object with the specified field values
   */
  static data --page-id/int?=null --status-bar-enable/bool?=null --redraw-type/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if page-id != null: data.add-data-uint PAGE-ID page-id
    if status-bar-enable != null: data.add-data-bool STATUS-BAR-ENABLE status-bar-enable
    if redraw-type != null: data.add-data-uint REDRAW-TYPE redraw-type
    return data

  /**
   * Creates a Base Page message without a specific method.
   *
   * This is used for messages that don't require a specific method type
   * (like GET, SET, SUBSCRIBE) but still need to carry data.
   *
   * Parameters:
   * - data: Optional protocol.Data object containing message payload
   *
   * Returns: A Message ready to be sent
   */
  static msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-data MT data

  /**
   * The page to draw.
   *
   *
   * Valid values:
   * - PAGE-ID_HOME-PAGE (1): The preset home page programmed into the device
   */
  page-id -> int:
    return get-data-uint PAGE-ID

  /**
   * Show the status bar
   */
  status-bar-enable -> bool:
    return get-data-bool STATUS-BAR-ENABLE

  /**
   * Redraw Type
   *
   * Valid values:
   * - REDRAW-TYPE_AUTO (0): Automatically choose the redraw type, based on page id.
   * No page id provided will assume the same page id as last set.
   * Same page id as last set will do a partial redraw, and leave the buffer intact.
   * Changed page id will clear the buffer and do a full redraw.
   *
   * - REDRAW-TYPE_PARTIALREDRAW (1): Only redraw the parts of the screen changed in this message.
   * Leaves the buffer intact.
   * Will occasionally do a full redraw if the firmware thinks it is needed.
   *
   * - REDRAW-TYPE_FULLREDRAW (2): Clear the screen buffer, and redraw the entire screen
   *
   * - REDRAW-TYPE_BUFFERONLY (3): Do not redraw the screen, only update the buffer.
   * Will clear the buffer if the page id has changed.
   * Similar to Auto, but will not redraw the screen.
   * Similar to ClearDontDraw, but only clears the buffer if the page id has changed.
   *
   * - REDRAW-TYPE_FULLREDRAWWITHOUTCLEAR (4): Redraw the entire screen, without clearing the buffer
   *
   * - REDRAW-TYPE_CLEARDONTDRAW (5): Clear the screen buffer (always), but don't redraw. Similar to BufferOnly, but always clears the buffer.
   */
  redraw-type -> int:
    return get-data-uint REDRAW-TYPE

  stringify -> string:
    return {
      "pageId": page-id,
      "statusBarEnable": status-bar-enable,
      "redrawType": redraw-type,
    }.stringify
