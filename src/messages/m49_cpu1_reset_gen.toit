import ..protocol as protocol

// Auto generated class for protocol message
class CPU1Reset extends protocol.Data:

  static MT := 49
  static MT_NAME := "CPU1Reset"

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  // DO
  static do-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
    return msg

  stringify -> string:
    return {
    }.stringify
