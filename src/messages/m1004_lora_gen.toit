import ..protocol as protocol

// Auto generated class for protocol message
class LORA extends protocol.Data:

  static MT := 1004
  static MT_NAME := "LORA"

  static PAYLOAD := 2
  static SPREAD-FACTOR := 4
  static CODING-RATE := 5
  static BANDWIDTH := 6
  static CENTER-FREQUENCY := 7
  static TX-POWER := 8
  static PREAMBLE-LENGTH := 9
  static RECEIVE-MS := 10
  static SLEEP := 11
  static STATE := 12

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
  static data --payload/ByteArray?=null --spread-factor/int?=null --coding-rate/int?=null --bandwidth/int?=null --center-frequency/int?=null --tx-power/int?=null --preamble-length/int?=null --receive-ms/int?=null --sleep/bool?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if payload != null: data.add-data PAYLOAD payload
    if spread-factor != null: data.add-data-uint SPREAD-FACTOR spread-factor
    if coding-rate != null: data.add-data-uint CODING-RATE coding-rate
    if bandwidth != null: data.add-data-uint BANDWIDTH bandwidth
    if center-frequency != null: data.add-data-uint CENTER-FREQUENCY center-frequency
    if tx-power != null: data.add-data-uint TX-POWER tx-power
    if preamble-length != null: data.add-data-uint PREAMBLE-LENGTH preamble-length
    if receive-ms != null: data.add-data-uint RECEIVE-MS receive-ms
    if sleep != null: data.add-data-bool SLEEP sleep
    return data

  /**
  Creates a LORA message without a specific method.
  
  This is used for messages that don't require a specific method type
  (like GET, SET, SUBSCRIBE) but still need to carry data.
  
  Parameters:
  - data: Optional protocol.Data object containing message payload
  
  Returns: A Message ready to be sent
  */
  static msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-data MT data

  /**
  Creates a SET Request message for LORA.
  
  Returns: A Message ready to be sent
  */
  static set-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-SET base-data

  /**
  Creates a GET Request message for LORA.
  
  Returns: A Message ready to be sent
  */
  static get-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-GET base-data

  /**
  Creates a DO Request message for LORA.
  
  Returns: A Message ready to be sent
  */
  static do-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-DO base-data

  // Subscribe to a message with an optional interval in milliseconds
  static subscribe-msg --ms/int -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SUBSCRIBE
    if ms != null:
      msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-INTERVAL ms
    return msg

  /**
  Creates a UNSUBSCRIBE Request message for LORA.
  
  Returns: A Message ready to be sent
  */
  static unsubscribe-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-UNSUBSCRIBE base-data

  /**
    Payload
  */
  payload -> ByteArray:
    return get-data PAYLOAD

  /**
    8-12
  */
  spread-factor -> int:
    return get-data-uint SPREAD-FACTOR

  /**
    1-4. [1: 4/5, 2: 4/6, 3: 4/7, 4: 4/8]
  */
  coding-rate -> int:
    return get-data-uint CODING-RATE

  /**
    0-2. [0: 125 kHz, 1: 250 kHz, 2: 500 kHz]
  */
  bandwidth -> int:
    return get-data-uint BANDWIDTH

  /**
    860000000-925000000. value in hz
  */
  center-frequency -> int:
    return get-data-uint CENTER-FREQUENCY

  /**
    0-22
  */
  tx-power -> int:
    return get-data-uint TX-POWER

  /**
    4-128
  */
  preamble-length -> int:
    return get-data-uint PREAMBLE-LENGTH

  /**
    How long to listen for after a transmit, in ms
  */
  receive-ms -> int:
    return get-data-uint RECEIVE-MS

  /**
    True will tell the LORA to stop all activity now
  */
  sleep -> bool:
    return get-data-bool SLEEP

  /**
    State
  */
  state -> int:
    return get-data-uint STATE

  stringify -> string:
    return {
      "Payload": payload,
      "Spread Factor": spread-factor,
      "Coding Rate": coding-rate,
      "Bandwidth": bandwidth,
      "Center Frequency": center-frequency,
      "TX Power": tx-power,
      "Preamble Length": preamble-length,
      "Receive Ms": receive-ms,
      "Sleep": sleep,
      "State": state,
    }.stringify
