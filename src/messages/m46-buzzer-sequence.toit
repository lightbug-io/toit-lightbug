import ..protocol as protocol

class BuzzerSequence extends protocol.Data:
  static MT := 46
  static FREQUENCIES := 6
  static TIMINGS := 7

  static doMsg frequencies/List timings/List -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.addDataUint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
    msg.data.addDataListFloat32 FREQUENCIES frequencies
    msg.data.addDataListUint16 TIMINGS timings
    return msg

  constructor.fromData data/protocol.Data:
    super.fromData data

  // frequencies -> List:
  //   return getDataListFloat32 FREQUENCIES

  // timings -> List<int>:
  //   return getDataListUint16 TIMINGS

  // stringify -> string:
  //   return {
  //     "Frequencies": frequencies,
  //     "Timings": timings,
  //   }.stringify
