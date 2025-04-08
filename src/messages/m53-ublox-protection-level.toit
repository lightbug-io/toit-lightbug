import ..protocol as protocol

class UbloxProtectionLevel extends protocol.Data:
  static MT := 53
  static PL-VALID := 1
  static PL-X := 2
  static PL-Y := 3
  static PL-Z := 4
  static PL-HORIZ-ORIENT := 5
  static PL-TMIR-COEFF := 6
  static PL-TMIR-EXP := 7

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  static get-msg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  valid -> int:
    return get-data-uint PL-VALID
  x -> int:
    return get-data-uint PL-X
  y -> int:
    return get-data-uint PL-Y
  z -> int:
    return get-data-uint PL-Z
  horizontal-orientation -> int:
    return get-data-uint PL-HORIZ-ORIENT
  tm-irradiation-coefficient -> int:
    return get-data-uint PL-TMIR-COEFF
  tm-irradiation-exponent -> int:
    return get-data-uint PL-TMIR-EXP

  stringify -> string:
    return {
        "valid": valid,
        "x": x,
        "y": y,
        "z": z,
        "horizontal-orientation": horizontal-orientation,
        "tm-irradiation-coefficient": tm-irradiation-coefficient,
        "tm-irradiation-exponent": tm-irradiation-exponent
    }.stringify
