import ..protocol as protocol

class BuzzerSequence extends protocol.Data:
  static MT := 46
  static FREQUENCIES := 6
  static TIMINGS := 7

  static doMsg frequencies/List timings/List -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
    msg.data.add-data-list-float32 FREQUENCIES frequencies
    msg.data.add-data-list-uint16 TIMINGS timings
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data

  // frequencies -> List:
  //   return get-dataListFloat32 FREQUENCIES

  // timings -> List<int>:
  //   return get-data-list-uint16 TIMINGS

  // stringify -> string:
  //   return {
  //     "Frequencies": frequencies,
  //     "Timings": timings,
  //   }.stringify
