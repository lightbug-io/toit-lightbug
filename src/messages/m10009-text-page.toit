import ..protocol as protocol

class TextPage extends protocol.Data:
  static MT := 10009
  static PAGE_ID := 3
  static PAGE_TITLE := 4
  static STATUS_BAR := 5
  static LINE_1 := 100
  static LINE_2 := 101
  static LINE_3 := 102
  static LINE_4 := 103
  static LINE_5 := 104

  static toMsg --pageId/int --pageTitle/string?=null --statusBar/bool?=false --line1/string?=null --line2/string?=null --line3/string?=null --line4/string?=null --line5/string?=null -> protocol.Message:
    msg := protocol.Message MT
    msg.data.addDataUintn PAGE_ID pageId
    if pageTitle:
        msg.data.addDataS PAGE_TITLE pageTitle
    if statusBar:
        msg.data.addDataUint8 STATUS_BAR 1
    if line1:
        msg.data.addDataS LINE_1 line1
    if line2:
        msg.data.addDataS LINE_2 line2
    if line3:
        msg.data.addDataS LINE_3 line3
    if line4:
        msg.data.addDataS LINE_4 line4
    if line5:
        msg.data.addDataS LINE_5 line5
    msg.header.data.addDataUint8 protocol.Header.TYPE_MESSAGE_METHOD protocol.Header.METHOD_SET
    return msg

  constructor.fromData data/protocol.Data:
    super.fromData data

  pageId -> int:
    return getDataUintn PAGE_ID

  pageTitle -> string:
    return getDataS PAGE_TITLE

  statusBar -> int:
    return getDataUint8 STATUS_BAR

  line1 -> string:
    return getDataS LINE_1

  line2 -> string:
    return getDataS LINE_2

  line3 -> string:
    return getDataS LINE_3

  line4 -> string:
    return getDataS LINE_4

  line5 -> string:
    return getDataS LINE_5

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
