import ..protocol as protocol

// Auto generated class for protocol message
class GSMControl extends protocol.Data:

  static MT := 31
  static MT_NAME := "GSMControl"

  static ENABLE-FLIGHT-MODE := 1
  static DURATION := 2
  static IS-GSM-ACTIVE := 3
  static REQUEST-CONTROL := 4

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  // Helper to create a data object for this message type.
  static data --enable-flight-mode/bool?=null --duration/int?=null --request-control/bool?=null -> protocol.Data:
    data := protocol.Data
    if enable-flight-mode != null: data.add-data-bool ENABLE-FLIGHT-MODE enable-flight-mode
    if duration != null: data.add-data-uint DURATION duration
    if request-control != null: data.add-data-bool REQUEST-CONTROL request-control
    return data

  // GET
  static get-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  // SET
  static set-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
    return msg

  enable-flight-mode -> bool:
    return get-data-bool ENABLE-FLIGHT-MODE

  duration -> int:
    return get-data-uint DURATION

  is-gsm-active -> bool:
    return get-data-bool IS-GSM-ACTIVE

  request-control -> bool:
    return get-data-bool REQUEST-CONTROL

  stringify -> string:
    return {
      "Enable Flight mode": enable-flight-mode,
      "Duration": duration,
      "Is GSM Active": is-gsm-active,
      "Request Control": request-control,
    }.stringify
