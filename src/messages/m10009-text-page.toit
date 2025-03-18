import ..protocol as protocol

class TextPage extends protocol.Data:
  static MT := 10009
  static PAGE-ID := 3
  static PAGE-TITLE := 4
  static STATUS-BAR := 5
  static LINE-1 := 100
  static LINE-2 := 101
  static LINE-3 := 102
  static LINE-4 := 103
  static LINE-5 := 104

  static toMsg --pageId/int --pageTitle/string?=null --statusBar/bool?=false --line1/string?=null --line2/string?=null --line3/string?=null --line4/string?=null --line5/string?=null -> protocol.Message:
    msg := protocol.Message MT
    msg.data.addDataUint PAGE-ID pageId
    if pageTitle:
        msg.data.addDataAscii PAGE-TITLE pageTitle
    if statusBar:
        msg.data.addDataUint8 STATUS-BAR 1
    if line1:
        msg.data.addDataAscii LINE-1 line1
    if line2:
        msg.data.addDataAscii LINE-2 line2
    if line3:
        msg.data.addDataAscii LINE-3 line3
    if line4:
        msg.data.addDataAscii LINE-4 line4
    if line5:
        msg.data.addDataAscii LINE-5 line5
    msg.header.data.addDataUint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
    return msg

  constructor.fromData data/protocol.Data:
    super.fromData data

  pageId -> int:
    return getDataUint PAGE-ID

  pageTitle -> string:
    return getDataAscii PAGE-TITLE

  statusBar -> int:
    return getDataUint8 STATUS-BAR

  line1 -> string:
    return getDataAscii LINE-1

  line2 -> string:
    return getDataAscii LINE-2

  line3 -> string:
    return getDataAscii LINE-3

  line4 -> string:
    return getDataAscii LINE-4

  line5 -> string:
    return getDataAscii LINE-5

  stringify -> string:
    return {
      "Page ID": pageId,
      "Page Title": pageTitle,
      "Status Bar": statusBar,
      "Line 1": line1,
      "Line 2": line2,
      "Line 3": line3,
      "Line 4": line4,
      "Line 5": line5,
    }.stringify
