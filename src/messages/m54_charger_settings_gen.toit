import ..protocol as protocol

// Auto generated class for protocol message
class ChargerSettings extends protocol.Data:

  static MT := 54
  static MT_NAME := "ChargerSettings"

  static INPUT-CURRENT-LIMIT := 1
  static CHARGE-CURRENT-LIMIT := 2
  static CHARGE-TERMINATION-VOLGATE := 3

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  // Helper to create a data object for this message type.
  static data --input-current-limit/int?=null --charge-current-limit/int?=null --charge-termination-volgate/int?=null -> protocol.Data:
    data := protocol.Data
    if input-current-limit != null: data.add-data-uint INPUT-CURRENT-LIMIT input-current-limit
    if charge-current-limit != null: data.add-data-uint CHARGE-CURRENT-LIMIT charge-current-limit
    if charge-termination-volgate != null: data.add-data-uint CHARGE-TERMINATION-VOLGATE charge-termination-volgate
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

  input-current-limit -> int:
    return get-data-uint INPUT-CURRENT-LIMIT

  charge-current-limit -> int:
    return get-data-uint CHARGE-CURRENT-LIMIT

  charge-termination-volgate -> int:
    return get-data-uint CHARGE-TERMINATION-VOLGATE

  stringify -> string:
    return {
      "Input Current Limit": input-current-limit,
      "Charge Current Limit": charge-current-limit,
      "Charge Termination Volgate": charge-termination-volgate,
    }.stringify
