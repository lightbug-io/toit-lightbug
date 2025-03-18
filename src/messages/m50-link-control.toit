import ..protocol as protocol

class LinkControl extends protocol.Data:
  static MT := 50
  static ADDRESS := 1
  static PORT := 2
  static ENABLE := 3

  constructor --ip/string --port/int --enable/bool:
    this.addDataAscii ADDRESS ip
    this.addDataUint16 PORT port
    this.addDataUint8 ENABLE (if enable: 1 else: 0)

  constructor.fromData data/protocol.Data:
    super.fromData data

  msg -> protocol.Message:
    msg := protocol.Message.withData MT this
    msg.header.data.addDataUint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
    return msg