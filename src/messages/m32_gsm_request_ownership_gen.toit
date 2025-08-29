import ..protocol as protocol

// Auto generated class for protocol message
class GSMRequestOwnership extends protocol.Data:

  static MT := 32
  static MT_NAME := "GSMRequestOwnership"

  static DURATION := 2
  static REQUEST-CONTROL := 4

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
  static data --duration/int?=null --request-control/bool?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if duration != null: data.add-data-uint DURATION duration
    if request-control != null: data.add-data-bool REQUEST-CONTROL request-control
    return data

  /**
  Creates a SET Request message for GSM Request Ownership.
  
  Returns: A Message ready to be sent
  */
  static set-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-SET base-data

  /**
  Creates a GET Request message for GSM Request Ownership.
  
  Returns: A Message ready to be sent
  */
  static get-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-GET base-data

  /**
    in mins
  */
  duration -> int:
    return get-data-uint DURATION

  /**
    Request Control
  */
  request-control -> bool:
    return get-data-bool REQUEST-CONTROL

  stringify -> string:
    return {
      "Duration": duration,
      "Request Control": request-control,
    }.stringify
