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

  // GET
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static get-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  // SET
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static set-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
    return msg

  // SUBSCRIBE to a message with an optional interval in milliseconds
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static subscribe-msg --ms/int -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SUBSCRIBE
    if ms != null:
      msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-INTERVAL ms
    return msg

  // UNSUBSCRIBE
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static unsubscribe-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-UNSUBSCRIBE
    return msg

  // DO
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static do-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
    return msg

  // Creates a message with no method set
  static msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-data MT data

  payload -> int:
    return get-data-uint PAYLOAD

  spread-factor -> int:
    return get-data-uint SPREAD-FACTOR

  coding-rate -> int:
    return get-data-uint CODING-RATE

  bandwidth -> int:
    return get-data-uint BANDWIDTH

  center-frequency -> int:
    return get-data-uint CENTER-FREQUENCY

  tx-power -> int:
    return get-data-uint TX-POWER

  preamble-length -> int:
    return get-data-uint PREAMBLE-LENGTH

  receive-ms -> int:
    return get-data-uint RECEIVE-MS

  sleep -> int:
    return get-data-uint SLEEP

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
