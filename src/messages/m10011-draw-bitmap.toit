import ..protocol as protocol

class DrawBitmap extends protocol.Data:
  static MT := 10011
  static PAGE-ID := 3
  static REDRAW-TYPE := 6
  static BITMAP-X := 7
  static BITMAP-Y := 8
  static BITMAP-WIDTH := 9
  static BITMAP-HEIGHT := 10
  static BITMAP-DATA := 25
  static BITMAP-OVERLAY := 26

  static to-msg --page-id/int?=null --bitmap-x/int=0 --bitmap-y/int=0 --bitmap-width/int --bitmap-height/int --bitmap-data/ByteArray --bitmap-overlay/bool=false --redraw-type/int=0 -> protocol.Message:
    msg := protocol.Message MT
    if page-id:
      msg.data.add-data-uint PAGE-ID page-id
    msg.data.add-data-uint BITMAP-X bitmap-x
    msg.data.add-data-uint BITMAP-Y bitmap-y
    msg.data.add-data-uint BITMAP-WIDTH bitmap-width
    msg.data.add-data-uint BITMAP-HEIGHT bitmap-height
    msg.data.add-data BITMAP-DATA bitmap-data
    if bitmap-overlay:
      msg.data.add-data-uint8 BITMAP-OVERLAY 1
    msg.data.add-data-uint REDRAW-TYPE redraw-type
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data

  page-id -> int:
    return get-data-uint PAGE-ID

  bitmap-x -> int:
    return get-data-uint BITMAP-X

  bitmap-y -> int:
    return get-data-uint BITMAP-Y

  bitmap-width -> int:
    return get-data-uint BITMAP-WIDTH

  bitmap-height -> int:
    return get-data-uint BITMAP-HEIGHT

  bitmap-data -> ByteArray:
    return get-data BITMAP-DATA

  bitmap-overlay -> int:
    return get-data-uint8 BITMAP-OVERLAY

  redraw-type -> int:
    return get-data-uint REDRAW-TYPE

  stringify -> string:
    return {
      "Page ID": page-id,
      "Bitmap X": bitmap-x,
      "Bitmap Y": bitmap-y,
      "Bitmap Width": bitmap-width,
      "Bitmap Height": bitmap-height,
      "Bitmap Data": bitmap-data,
      "Bitmap Overlay": bitmap-overlay,
      "Redraw Type": redraw-type,
    }.stringify
