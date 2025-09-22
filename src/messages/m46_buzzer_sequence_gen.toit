import ..protocol as protocol

// Auto generated class for protocol message
class BuzzerSequence extends protocol.Data:

  static MT := 46
  static MT_NAME := "BuzzerSequence"

  static FREQUENCIES := 6
  static TIMINGS := 7

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
  static data --frequencies/float?=null --timings/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if frequencies != null: data.add-data-float FREQUENCIES frequencies
    if timings != null: data.add-data-uint TIMINGS timings
    return data

  /**
  Creates a Buzzer Sequence message without a specific method.
  
  This is used for messages that don't require a specific method type
  (like GET, SET, SUBSCRIBE) but still need to carry data.
  
  Parameters:
  - data: Optional protocol.Data object containing message payload
  
  Returns: A Message ready to be sent
  */
  static msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-data MT data

  /**
    Array of frequencies in Hz as floats
  */
  frequencies -> float:
    return get-data-float FREQUENCIES

  /**
    Array of timings in ms as uint16
  */
  timings -> int:
    return get-data-uint TIMINGS

  stringify -> string:
    return {
      "Frequencies": frequencies,
      "Timings": timings,
    }.stringify
