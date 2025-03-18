import ..protocol as protocol

class Lora extends protocol.Data:
  static MT := 1004
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

  static set-msg --spread-factor/int --coding-rate/int --bandwidth/int --center-frequency/int --tx-power/int --preamble-length/int --sleep/int?=null -> protocol.Message:
    msg := protocol.Message MT
    msg.data.add-data-uint8 SPREAD-FACTOR spread-factor
    msg.data.add-data-uint8 CODING-RATE coding-rate
    msg.data.add-data-uint8 BANDWIDTH bandwidth
    msg.data.add-data-uint32 CENTER-FREQUENCY center-frequency
    msg.data.add-data-uint8 TX-POWER tx-power
    msg.data.add-data-uint8 PREAMBLE-LENGTH preamble-length
    if sleep:
      msg.data.add-data-uint8 SLEEP sleep
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
    return msg

  static get-msg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg
  
  static do-msg --payload/ByteArray --receive-ms/int -> protocol.Message:
    msg := protocol.Message MT
    msg.data.add-data PAYLOAD payload
    msg.data.add-data-uint32 RECEIVE-MS receive-ms
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
    return msg
  
  static subscribe-msg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SUBSCRIBE
    return msg
  
  static unsubscribe-msg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-UNSUBSCRIBE
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data

  payload -> ByteArray:
    return get-data PAYLOAD

  spread-factor -> int:
    return get-data-uint8 SPREAD-FACTOR

  coding-rate -> int:
    return get-data-uint8 CODING-RATE

  bandwidth -> int:
    return get-data-uint8 BANDWIDTH

  center-frequency -> int:
    return get-data-uint32 CENTER-FREQUENCY

  tx-power -> int:
    return get-data-uint8 TX-POWER

  preamble-length -> int:
    return get-data-uint8 PREAMBLE-LENGTH

  receive-ms -> int:
    return get-data-uint32 RECEIVE-MS

  sleep -> int:
    return get-data-uint8 SLEEP

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
