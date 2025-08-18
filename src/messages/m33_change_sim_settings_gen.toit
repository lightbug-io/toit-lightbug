import ..protocol as protocol

// Auto generated class for protocol message
class ChangeSIMsettings extends protocol.Data:

  static MT := 33
  static MT_NAME := "ChangeSIMsettings"

  static ACTIVE-SIM := 1
  static ACTIVE-SIM_SIM1 := 0
  static ACTIVE-SIM_SIM2 := 1

  static ACTIVE-SIM_STRINGS := {
    0: "SIM1",
    1: "SIM2",
  }

  static active-sim-from-int value/int -> string:
    return ACTIVE-SIM_STRINGS.get value --if-absent=(: "unknown")

  static SIM2-APN := 2
  static SIM2-APN-USERNAME := 3
  static SIM2-APN-PASSWORD := 4
  static SIM2-ICCID := 8

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  // Helper to create a data object for this message type.
  static data --active-sim/int?=null --sim2-apn/string?=null --sim2-apn-username/string?=null --sim2-apn-password/string?=null -> protocol.Data:
    data := protocol.Data
    if active-sim != null: data.add-data-uint ACTIVE-SIM active-sim
    if sim2-apn != null: data.add-data-ascii SIM2-APN sim2-apn
    if sim2-apn-username != null: data.add-data-ascii SIM2-APN-USERNAME sim2-apn-username
    if sim2-apn-password != null: data.add-data-ascii SIM2-APN-PASSWORD sim2-apn-password
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

  active-sim -> int:
    return get-data-uint ACTIVE-SIM

  sim2-apn -> string:
    return get-data-ascii SIM2-APN

  sim2-apn-username -> string:
    return get-data-ascii SIM2-APN-USERNAME

  sim2-apn-password -> string:
    return get-data-ascii SIM2-APN-PASSWORD

  sim2-iccid -> bool:
    return get-data-bool SIM2-ICCID

  stringify -> string:
    return {
      "Active SIM": active-sim,
      "SIM2 APN": sim2-apn,
      "SIM2 APN Username": sim2-apn-username,
      "SIM2 APN Password": sim2-apn-password,
      "SIM2 ICCID": sim2-iccid,
    }.stringify
