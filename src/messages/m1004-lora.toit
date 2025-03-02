import ..protocol as protocol

class Lora extends protocol.Data:
  static MT := 1004
  static PAYLOAD := 2
  static SPREAD_FACTOR := 4
  static CODING_RATE := 5
  static BANDWIDTH := 6
  static CENTER_FREQUENCY := 7
  static TX_POWER := 8
  static PREAMBLE_LENGTH := 9
  static RECEIVE_MS := 10
  static SLEEP := 11
  static STATE := 12

  static setMsg --spreadFactor/int --codingRate/int --bandwidth/int --centerFrequency/int --txPower/int --preambleLength/int --sleep/int?=null -> protocol.Message:
    msg := protocol.Message MT
    msg.data.addDataUint8 SPREAD_FACTOR spreadFactor
    msg.data.addDataUint8 CODING_RATE codingRate
    msg.data.addDataUint8 BANDWIDTH bandwidth
    msg.data.addDataUint32 CENTER_FREQUENCY centerFrequency
    msg.data.addDataUint8 TX_POWER txPower
    msg.data.addDataUint8 PREAMBLE_LENGTH preambleLength
    if sleep:
      msg.data.addDataUint8 SLEEP sleep
    msg.header.data.addDataUint8 protocol.Header.TYPE_MESSAGE_METHOD protocol.Header.METHOD_SET
    return msg

  static getMsg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.addDataUint8 protocol.Header.TYPE_MESSAGE_METHOD protocol.Header.METHOD_GET
    return msg
  
  static doMsg --payload/ByteArray --receiveMs/int -> protocol.Message:
    msg := protocol.Message MT
    msg.data.addData PAYLOAD payload
    msg.data.addDataUint32 RECEIVE_MS receiveMs
    msg.header.data.addDataUint8 protocol.Header.TYPE_MESSAGE_METHOD protocol.Header.METHOD_DO
    return msg
  
  static subscribeMsg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.addDataUint8 protocol.Header.TYPE_MESSAGE_METHOD protocol.Header.METHOD_SUBSCRIBE
    return msg
  
  static unsubscribeMsg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.addDataUint8 protocol.Header.TYPE_MESSAGE_METHOD protocol.Header.METHOD_UNSUBSCRIBE
    return msg

  constructor.fromData data/protocol.Data:
    super.fromData data

  payload -> ByteArray:
    return getData PAYLOAD

  spreadFactor -> int:
    return getDataUint8 SPREAD_FACTOR

  codingRate -> int:
    return getDataUint8 CODING_RATE

  bandwidth -> int:
    return getDataUint8 BANDWIDTH

  centerFrequency -> int:
    return getDataUint32 CENTER_FREQUENCY

  txPower -> int:
    return getDataUint8 TX_POWER

  preambleLength -> int:
    return getDataUint8 PREAMBLE_LENGTH

  receiveMs -> int:
    return getDataUint32 RECEIVE_MS

  sleep -> int:
    return getDataUint8 SLEEP

  state -> int:
    return getDataUint STATE

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
