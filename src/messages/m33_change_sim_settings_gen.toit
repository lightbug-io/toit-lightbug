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

  /**
  Creates a protocol.Data object with all available fields for this message type.
  
  This is a comprehensive helper that accepts all possible fields.
  For method-specific usage, consider using the dedicated request/response methods.
  
  Returns: A protocol.Data object with the specified field values
  */
  static data --active-sim/int?=null --sim2-apn/string?=null --sim2-apn-username/string?=null --sim2-apn-password/string?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if active-sim != null: data.add-data-uint ACTIVE-SIM active-sim
    if sim2-apn != null: data.add-data-ascii SIM2-APN sim2-apn
    if sim2-apn-username != null: data.add-data-ascii SIM2-APN-USERNAME sim2-apn-username
    if sim2-apn-password != null: data.add-data-ascii SIM2-APN-PASSWORD sim2-apn-password
    return data

  /**
  Creates a GET Request message for Change SIM settings.
  
  Returns: A Message ready to be sent
  */
  static get-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-GET base-data

  /**
  Creates a SET Request message for Change SIM settings.
  
  Returns: A Message ready to be sent
  */
  static set-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-SET base-data

  /**
    Activate the specified SIM
    
    Valid values:
    - ACTIVE-SIM_SIM1 (0): SIM1
    - ACTIVE-SIM_SIM2 (1): SIM2
  */
  active-sim -> int:
    return get-data-uint ACTIVE-SIM

  /**
    SIM2 APN
  */
  sim2-apn -> string:
    return get-data-ascii SIM2-APN

  /**
    SIM2 APN Username
  */
  sim2-apn-username -> string:
    return get-data-ascii SIM2-APN-USERNAME

  /**
    SIM2 APN Password
  */
  sim2-apn-password -> string:
    return get-data-ascii SIM2-APN-PASSWORD

  /**
    SIM2 ICCID
  */
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
