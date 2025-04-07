import ..protocol as protocol

class GsmOwnership extends protocol.Data:
  static MT := 32
  
  static DURATION_MINUTES := 2
  static REQUEST_CONTROL := 4

  static set-msg request-control/int duration/int -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
    msg.data.add-data-uint8 REQUEST-CONTROL request-control
    msg.data.add-data-uint32 DURATION-MINUTES duration
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data


