import ..protocol as protocol

class ButtonPress extends protocol.Data:
  static MT := 38
  static BUTTON-ID := 1
  static DURATION := 2 // in ms
  
  constructor.from-data data/protocol.Data:
    super.from-data data

  static subscribe-msg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SUBSCRIBE
    return msg

  static unsubscribe-msg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-UNSUBSCRIBE
    return msg

  button-id -> int:
    return get-data-uint BUTTON-ID

  duration -> int:
    return get-data-uint DURATION

  stringify -> string:
    return {
      "Button ID": button-id,
      "Duration": duration,
    }.stringify
