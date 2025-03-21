import ..protocol as protocol

class TextPage extends protocol.Data:
  static MT := 10009
  static PAGE-ID := 3
  static PAGE-TITLE := 4
  static STATUS-BAR := 5
  static REDRAW-TYPE := 6
  static LINE-1 := 100
  static LINE-2 := 101
  static LINE-3 := 102
  static LINE-4 := 103
  static LINE-5 := 104

  static to-msg
      --page-id/int
      --page-title/string?=null
      --status-bar/bool?=false
      --line1/string?=null
      --line2/string?=null
      --line3/string?=null
      --line4/string?=null
      --line5/string?=null
      --redraw-type/int=0 -> protocol.Message:
    msg := protocol.Message MT
    msg.data.add-data-uint PAGE-ID page-id
    if page-title:
        msg.data.add-data-ascii PAGE-TITLE page-title
    if status-bar:
        msg.data.add-data-uint8 STATUS-BAR 1
    msg.data.add-data-uint REDRAW-TYPE redraw-type
    if line1:
        msg.data.add-data-ascii LINE-1 line1
    if line2:
        msg.data.add-data-ascii LINE-2 line2
    if line3:
        msg.data.add-data-ascii LINE-3 line3
    if line4:
        msg.data.add-data-ascii LINE-4 line4
    if line5:
        msg.data.add-data-ascii LINE-5 line5
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data

  page-id -> int:
    return get-data-uint PAGE-ID

  page-title -> string:
    return get-data-ascii PAGE-TITLE

  status-bar -> int:
    return get-data-uint8 STATUS-BAR

  line1 -> string:
    return get-data-ascii LINE-1

  line2 -> string:
    return get-data-ascii LINE-2

  line3 -> string:
    return get-data-ascii LINE-3

  line4 -> string:
    return get-data-ascii LINE-4

  line5 -> string:
    return get-data-ascii LINE-5

  redraw-type -> int:
    return get-data-uint REDRAW-TYPE

  stringify -> string:
    return {
      "Page ID": page-id,
      "Page Title": page-title,
      "Status Bar": status-bar,
      "Line 1": line1,
      "Line 2": line2,
      "Line 3": line3,
      "Line 4": line4,
      "Line 5": line5,
      "Redraw Type": redraw-type,
    }.stringify
