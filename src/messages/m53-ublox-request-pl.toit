import ..protocol as protocol

class UbloxPlData extends protocol.Data:
  static MT := 53
  static PL_VALID := 1
  static PL_X := 2
  static PL_Y := 3
  static PL_Z := 4
  static PL_HORIZ_ORIENT := 5
  static PL_TMIR_COEFF := 6
  static PL_TMIR_EXP := 7

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  static get-msg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg