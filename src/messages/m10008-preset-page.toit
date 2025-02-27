import ..protocol as protocol

class PresetPage extends protocol.Data:
  static MT := 10008

  static toMsg -> protocol.Message:
    msg := protocol.Message MT
    return msg

  constructor.fromData data/protocol.Data:
    super.fromData data
