import ..protocol as protocol

class LinkControl extends protocol.Data:
  static MT := 50
  static ADDRESS := 1
  static PORT := 2
  static ENABLE := 3

  constructor --ip/string --port/int --enable/bool:
    this.add-data-s ADDRESS ip
    this.add-data-uint16 PORT port
    this.add-data-uint8 ENABLE (if enable: 1 else: 0)

  constructor.from-data data/protocol.Data:
    super.from-data data

  msg -> protocol.Message:
    msg := protocol.Message.with-data MT this
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
    return msg
