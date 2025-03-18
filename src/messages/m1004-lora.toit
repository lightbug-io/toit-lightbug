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

  static setMsg --spreadFactor/int --codingRate/int --bandwidth/int --centerFrequency/int --txPower/int --preambleLength/int --sleep/int?=null -> protocol.Message:
    msg := protocol.Message MT
    msg.data.add-data-uint8 SPREAD-FACTOR spreadFactor
    msg.data.add-data-uint8 CODING-RATE codingRate
    msg.data.add-data-uint8 BANDWIDTH bandwidth
    msg.data.add-data-uint32 CENTER-FREQUENCY centerFrequency
    msg.data.add-data-uint8 TX-POWER txPower
    msg.data.add-data-uint8 PREAMBLE-LENGTH preambleLength
    if sleep:
      msg.data.add-data-uint8 SLEEP sleep
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
    return msg

  static getMsg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg
  
  static doMsg --payload/ByteArray --receiveMs/int -> protocol.Message:
    msg := protocol.Message MT
    msg.data.add-data PAYLOAD payload
    msg.data.add-data-uint32 RECEIVE-MS receiveMs
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
    return msg
  
  static subscribeMsg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SUBSCRIBE
    return msg
  
  static unsubscribeMsg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-UNSUBSCRIBE
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data

  payload -> ByteArray:
    return get-data PAYLOAD

  spreadFactor -> int:
    return get-data-uint8 SPREAD-FACTOR

  codingRate -> int:
    return get-data-uint8 CODING-RATE

  bandwidth -> int:
    return get-data-uint8 BANDWIDTH

  centerFrequency -> int:
    return get-data-uint32 CENTER-FREQUENCY

  txPower -> int:
    return get-data-uint8 TX-POWER

  preambleLength -> int:
    return get-data-uint8 PREAMBLE-LENGTH

  receiveMs -> int:
    return get-data-uint32 RECEIVE-MS

  sleep -> int:
    return get-data-uint8 SLEEP

  state -> int:
    return get-data-uint STATE

  stringify -> string:
    return {
      "Payload": payload,
      "Spread Factor": spreadFactor,
      "Coding Rate": codingRate,
      "Bandwidth": bandwidth,
      "Center Frequency": centerFrequency,
      "TX Power": txPower,
      "Preamble Length": preambleLength,
      "Receive Ms": receiveMs,
      "Sleep": sleep,
      "State": state,
    }.stringify
