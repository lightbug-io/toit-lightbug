import ..protocol as protocol

class DrawBitmap extends protocol.Data:
  static MT := 10011
  static PAGE-ID := 3
  static BITMAP-X := 21
  static BITMAP-Y := 22
  static BITMAP-WIDTH := 23
  static BITMAP-HEIGHT := 24
  static BITMAP-DATA := 25
  static BITMAP-OVERLAY := 26
  static DONT-DRAW := 27

  static toMsg --pageId/int?=null --bitmapX/int=0 --bitmapY/int=0 --bitmapWidth/int --bitmapHeight/int --bitmapData/ByteArray --bitmapOverlay/bool=false --dontDraw/bool=false -> protocol.Message:
    msg := protocol.Message MT
    if pageId:
      msg.data.add-data-uint PAGE-ID pageId
    msg.data.add-data-uint BITMAP-X bitmapX
    msg.data.add-data-uint BITMAP-Y bitmapY
    msg.data.add-data-uint BITMAP-WIDTH bitmapWidth
    msg.data.add-data-uint BITMAP-HEIGHT bitmapHeight
    msg.data.add-data BITMAP-DATA bitmapData
    if bitmapOverlay:
      msg.data.add-data-uint8 BITMAP-OVERLAY 1
    if dontDraw:
      msg.data.add-data-uint8 DONT-DRAW 1
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data

  pageId -> int:
    return get-data-uint PAGE-ID

  bitmapX -> int:
    return get-data-uint BITMAP-X

  bitmapY -> int:
    return get-data-uint BITMAP-Y

  bitmapWidth -> int:
    return get-data-uint BITMAP-WIDTH

  bitmapHeight -> int:
    return get-data-uint BITMAP-HEIGHT

  bitmapData -> ByteArray:
    return get-data BITMAP-DATA

  bitmapOverlay -> int:
    return get-data-uint8 BITMAP-OVERLAY

  dontDraw -> int:
    return get-data-uint8 DONT-DRAW

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
