import ..protocol as protocol

class CPU1Reset extends protocol.Data:
  static MT := 49

  static do-msg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data

  stringify -> string:
    return {}.stringify
