import ..protocol as protocol

class PresetPage extends protocol.Data:
  static MT := 10008

  static toMsg -> protocol.Message:
    msg := protocol.Message MT
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data
