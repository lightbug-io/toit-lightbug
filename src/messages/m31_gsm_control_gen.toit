import ..protocol as protocol
import fixed-point show FixedPoint

// Auto generated class for protocol message
class GSMControl extends protocol.Data:

  static MT := 31

  static FLIGHT-MODE := 1
  static DURATION := 2
  static GSM-ACTIVE := 3
  static REQUEST-CONTROL := 4

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  // GET
  static get-msg --data/protocol.Data? -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  // SET
  static set-msg --data/protocol.Data? -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
    return msg

  flight-mode -> int:
    return get-data-uint FLIGHT-MODE

  duration -> int:
    return get-data-uint DURATION

  gsm-active -> int:
    return get-data-uint GSM-ACTIVE

  request-control -> int:
    return get-data-uint REQUEST-CONTROL

  stringify -> string:
    return {
      "Flight mode": flight-mode,
      "Duration": duration,
      "GSM Active": gsm-active,
      "Request Control": request-control,
    }.stringify
