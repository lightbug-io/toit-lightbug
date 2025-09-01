import ..protocol as protocol

// Auto generated class for protocol message
class DrawElement extends protocol.Data:

  static MT := 10011
  static MT_NAME := "DrawElement"

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

  static X := 7
  static Y := 8
  static WIDTH := 9
  static HEIGHT := 10
  static TYPE := 11
  static TYPE_BOX := 0
  static TYPE_CIRCLE := 1
  static TYPE_LINE := 2
  static TYPE_BITMAP := 3

  static TYPE_STRINGS := {
    0: "Box",
    1: "Circle",
    2: "Line",
    3: "Bitmap",
  }

  static type-from-int value/int -> string:
    return TYPE_STRINGS.get value --if-absent=(: "unknown")

  static STYLE := 12
  static STYLE_BLACKONCLEAR := 0
  static STYLE_WHITEONBLACK := 1
  static STYLE_BLACKOUTLINE := 2
  static STYLE_WHITEOUTLINE := 3

  static STYLE_STRINGS := {
    0: "BlackOnClear",
    1: "WhiteOnBlack",
    2: "BlackOutline",
    3: "WhiteOutline",
  }

  static style-from-int value/int -> string:
    return STYLE_STRINGS.get value --if-absent=(: "unknown")

  static FONTSIZE := 13
  static FONTSIZE_SMALL := 0
  static FONTSIZE_MEDIUM := 1
  static FONTSIZE_LARGE := 2

  static FONTSIZE_STRINGS := {
    0: "Small",
    1: "Medium",
    2: "Large",
  }

  static fontsize-from-int value/int -> string:
    return FONTSIZE_STRINGS.get value --if-absent=(: "unknown")

  static TEXTALIGN := 14
  static TEXTALIGN_LEFT := 0
  static TEXTALIGN_MIDDLE := 1
  static TEXTALIGN_RIGHT := 2

  static TEXTALIGN_STRINGS := {
    0: "Left",
    1: "Middle",
    2: "Right",
  }

  static textalign-from-int value/int -> string:
    return TEXTALIGN_STRINGS.get value --if-absent=(: "unknown")

  static LINEWIDTH := 15
  static PADDING := 16
  static RADIUS := 17
  static LINETYPE := 18
  static LINETYPE_SOLID := 0
  static LINETYPE_DASHED := 1

  static LINETYPE_STRINGS := {
    0: "Solid",
    1: "Dashed",
  }

  static linetype-from-int value/int -> string:
    return LINETYPE_STRINGS.get value --if-absent=(: "unknown")

  static BITMAP := 25
  static TEXT := 100

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
  static data --page-id/int?=null --status-bar-enable/bool?=null --redraw-type/int?=null --x/int?=null --y/int?=null --width/int?=null --height/int?=null --type/int?=null --style/int?=null --fontsize/int?=null --textalign/int?=null --linewidth/int?=null --padding/int?=null --radius/int?=null --linetype/int?=null --bitmap/ByteArray?=null --text/string?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if page-id != null: data.add-data-uint PAGE-ID page-id
    if status-bar-enable != null: data.add-data-bool STATUS-BAR-ENABLE status-bar-enable
    if redraw-type != null: data.add-data-uint REDRAW-TYPE redraw-type
    if x != null: data.add-data-uint X x
    if y != null: data.add-data-uint Y y
    if width != null: data.add-data-uint WIDTH width
    if height != null: data.add-data-uint HEIGHT height
    if type != null: data.add-data-uint TYPE type
    if style != null: data.add-data-uint STYLE style
    if fontsize != null: data.add-data-uint FONTSIZE fontsize
    if textalign != null: data.add-data-uint TEXTALIGN textalign
    if linewidth != null: data.add-data-uint LINEWIDTH linewidth
    if padding != null: data.add-data-uint PADDING padding
    if radius != null: data.add-data-uint RADIUS radius
    if linetype != null: data.add-data-uint LINETYPE linetype
    if bitmap != null: data.add-data BITMAP bitmap
    if text != null: data.add-data-ascii TEXT text
    return data

  /**
  Creates a Draw Element message without a specific method.
  
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

  /**
    X coordinate for the start of the element. If padded, this is the start of the padded area.
  */
  x -> int:
    return get-data-uint X

  /**
    Y coordinate for the start of the element. If padded, this is the start of the padded area.
  */
  y -> int:
    return get-data-uint Y

  /**
    Width of the element. If padded this does not include the padding.
  */
  width -> int:
    return get-data-uint WIDTH

  /**
    Height of the element. If padded this does not include the padding.
  */
  height -> int:
    return get-data-uint HEIGHT

  /**
    Type of element to draw
    
    Valid values:
    - TYPE_BOX (0): Draw a Box.
Requires x, y (top left corner), width and height.
Can include style, and padding
Can include text and a font size and alignment.
Can have corners rounded with the radius parameter.
Can have a border with the line width parameter.

    - TYPE_CIRCLE (1): Draw a circle.
Requires x, y (top left corner) and width.
Can have a border with the line width parameter.

    - TYPE_LINE (2): Draw a line.
Requires x, y (start point), width and height (end point).
Can have line width and line type (dashed or solid).

    - TYPE_BITMAP (3): Draw a bitmap, from provided data.
Requires x, y (top left corner), width, height and bitmap data.

  */
  type -> int:
    return get-data-uint TYPE

  /**
    Style of the element to draw. Default is BlackOnClear.
    
    Valid values:
    - STYLE_BLACKONCLEAR (0): BlackOnClear
    - STYLE_WHITEONBLACK (1): WhiteOnBlack
    - STYLE_BLACKOUTLINE (2): BlackOutline
    - STYLE_WHITEOUTLINE (3): WhiteOutline
  */
  style -> int:
    return get-data-uint STYLE

  /**
    Size of the font to use. Default is Medium.
    
    Valid values:
    - FONTSIZE_SMALL (0): Small
    - FONTSIZE_MEDIUM (1): Medium
    - FONTSIZE_LARGE (2): Large
  */
  fontsize -> int:
    return get-data-uint FONTSIZE

  /**
    Alignment of the text. Default is Middle.
    
    Valid values:
    - TEXTALIGN_LEFT (0): Left
    - TEXTALIGN_MIDDLE (1): Middle
    - TEXTALIGN_RIGHT (2): Right
  */
  textalign -> int:
    return get-data-uint TEXTALIGN

  /**
    Default is 1. Max is 8.
  */
  linewidth -> int:
    return get-data-uint LINEWIDTH

  /**
    Padding inside the element (in terms of x and y). Default is 0.
  */
  padding -> int:
    return get-data-uint PADDING

  /**
    For use with circle, or corner rounding. Default is 0.
  */
  radius -> int:
    return get-data-uint RADIUS

  /**
    Default is Solid.
    
    Valid values:
    - LINETYPE_SOLID (0): Solid
    - LINETYPE_DASHED (1): Dashed
  */
  linetype -> int:
    return get-data-uint LINETYPE

  /**
    Bitmap
  */
  bitmap -> ByteArray:
    return get-data BITMAP

  /**
    Text
  */
  text -> string:
    return get-data-ascii TEXT

  stringify -> string:
    return {
      "Page ID": page-id,
      "Status bar Enable": status-bar-enable,
      "Redraw Type": redraw-type,
      "X": x,
      "Y": y,
      "Width": width,
      "Height": height,
      "Type": type,
      "Style": style,
      "FontSize": fontsize,
      "TextAlign": textalign,
      "LineWidth": linewidth,
      "Padding": padding,
      "Radius": radius,
      "LineType": linetype,
      "Bitmap": bitmap,
      "Text": text,
    }.stringify
