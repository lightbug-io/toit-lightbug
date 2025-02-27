import ..protocol as protocol

class DrawBitmap extends protocol.Data:
  static MT := 10011
  static PAGE_ID := 3
  static BITMAP_X := 21
  static BITMAP_Y := 22
  static BITMAP_WIDTH := 23
  static BITMAP_HEIGHT := 24
  static BITMAP_DATA := 25
  static BITMAP_OVERLAY := 26
  static DONT_DRAW := 27

  static setMsg --pageId/int --bitmapX/int --bitmapY/int --bitmapWidth/int --bitmapHeight/int --bitmapData/ByteArray --bitmapOverlay/int --dontDraw/int -> protocol.Message:
    msg := protocol.Message MT
    msg.data.addDataUintn PAGE_ID pageId
    msg.data.addDataUintn BITMAP_X bitmapX
    msg.data.addDataUintn BITMAP_Y bitmapY
    msg.data.addDataUintn BITMAP_WIDTH bitmapWidth
    msg.data.addDataUintn BITMAP_HEIGHT bitmapHeight
    msg.data.addData BITMAP_DATA bitmapData
    msg.data.addDataUint8 BITMAP_OVERLAY bitmapOverlay
    msg.data.addDataUint8 DONT_DRAW dontDraw
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

  bitmapX -> int:
    return getDataUintn BITMAP_X

  bitmapY -> int:
    return getDataUintn BITMAP_Y

  bitmapWidth -> int:
    return getDataUintn BITMAP_WIDTH

  bitmapHeight -> int:
    return getDataUintn BITMAP_HEIGHT

  bitmapData -> ByteArray:
    return getData BITMAP_DATA

  bitmapOverlay -> int:
    return getDataUint8 BITMAP_OVERLAY

  dontDraw -> int:
    return getDataUint8 DONT_DRAW

  stringify -> string:
    return {
      "Page ID": pageId,
      "Bitmap X": bitmapX,
      "Bitmap Y": bitmapY,
      "Bitmap Width": bitmapWidth,
      "Bitmap Height": bitmapHeight,
      "Bitmap Data": bitmapData,
      "Bitmap Overlay": bitmapOverlay,
      "Don't Draw": dontDraw,
    }.stringify
