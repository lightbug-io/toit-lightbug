import ..protocol as protocol

// Auto generated class for protocol message
class DrawBitmap extends protocol.Data:

  static MT := 10011
  static MT_NAME := "DrawBitmap"

  static PAGE-ID := 3
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

  static X := 7
  static Y := 8
  static WIDTH := 9
  static HEIGHT := 10
  static BITMAP := 25

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
  static data --page-id/int?=null --redraw-type/int?=null --x/int?=null --y/int?=null --width/int?=null --height/int?=null --bitmap/ByteArray?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if page-id != null: data.add-data-uint PAGE-ID page-id
    if redraw-type != null: data.add-data-uint REDRAW-TYPE redraw-type
    if x != null: data.add-data-uint X x
    if y != null: data.add-data-uint Y y
    if width != null: data.add-data-uint WIDTH width
    if height != null: data.add-data-uint HEIGHT height
    if bitmap != null: data.add-data BITMAP bitmap
    return data

  /**
  Creates a Draw Bitmap message without a specific method.
  
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
    X coordinate for the start of the bitmap
  */
  x -> int:
    return get-data-uint X

  /**
    Y coordinate for the start of the bitmap
  */
  y -> int:
    return get-data-uint Y

  /**
    Width of the bitmap
  */
  width -> int:
    return get-data-uint WIDTH

  /**
    Height of the bitmap
  */
  height -> int:
    return get-data-uint HEIGHT

  /**
    Bitmap
  */
  bitmap -> ByteArray:
    return get-data BITMAP

  stringify -> string:
    return {
      "Page ID": page-id,
      "Redraw Type": redraw-type,
      "X": x,
      "Y": y,
      "Width": width,
      "Height": height,
      "Bitmap": bitmap,
    }.stringify
