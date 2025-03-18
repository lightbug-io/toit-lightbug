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
      msg.data.addDataUint PAGE-ID pageId
    msg.data.addDataUint BITMAP-X bitmapX
    msg.data.addDataUint BITMAP-Y bitmapY
    msg.data.addDataUint BITMAP-WIDTH bitmapWidth
    msg.data.addDataUint BITMAP-HEIGHT bitmapHeight
    msg.data.addData BITMAP-DATA bitmapData
    if bitmapOverlay:
      msg.data.addDataUint8 BITMAP-OVERLAY 1
    if dontDraw:
      msg.data.addDataUint8 DONT-DRAW 1
    msg.header.data.addDataUint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
    return msg

  constructor.fromData data/protocol.Data:
    super.fromData data

  pageId -> int:
    return getDataUint PAGE-ID

  bitmapX -> int:
    return getDataUint BITMAP-X

  bitmapY -> int:
    return getDataUint BITMAP-Y

  bitmapWidth -> int:
    return getDataUint BITMAP-WIDTH

  bitmapHeight -> int:
    return getDataUint BITMAP-HEIGHT

  bitmapData -> ByteArray:
    return getData BITMAP-DATA

  bitmapOverlay -> int:
    return getDataUint8 BITMAP-OVERLAY

  dontDraw -> int:
    return getDataUint8 DONT-DRAW

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
