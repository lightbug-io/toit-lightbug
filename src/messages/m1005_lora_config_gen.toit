import ..protocol as protocol

// Auto generated class for protocol message
class LoRaConfig extends protocol.Data:

  static MT := 1005
  static MT_NAME := "LoRaConfig"

  static CONFIG-SLOT := 1
  static SPREAD-FACTOR := 2
  static CODING-RATE := 3
  static BANDWIDTH := 4
  static CENTER-FREQUENCY := 5
  static TX-POWER := 6
  static PREAMBLE-LENGTH := 7
  static CRC-ON := 8
  static IQ-INVERTED := 9
  static FIXED-LENGTH := 10
  static PAYLOAD-LENGTH := 11
  static MAX-PAYLOAD-LENGTH := 12
  static SYMBOL-TIMEOUT := 13
  static PUBLIC-NETWORK := 14

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  /**
   * Creates a protocol.Data object with all available fields for this message type.
   *
   * This is a comprehensive helper that accepts all possible fields.
   * For method-specific usage, consider using the dedicated request/response methods.
   *
   * Returns: A protocol.Data object with the specified field values
   */
  static data --config-slot/int?=null --spread-factor/int?=null --coding-rate/int?=null --bandwidth/int?=null --center-frequency/int?=null --tx-power/int?=null --preamble-length/int?=null --crc-on/bool?=null --iq-inverted/bool?=null --fixed-length/bool?=null --payload-length/int?=null --max-payload-length/int?=null --symbol-timeout/int?=null --public-network/bool?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if config-slot != null: data.add-data-uint CONFIG-SLOT config-slot
    if spread-factor != null: data.add-data-uint SPREAD-FACTOR spread-factor
    if coding-rate != null: data.add-data-uint CODING-RATE coding-rate
    if bandwidth != null: data.add-data-uint BANDWIDTH bandwidth
    if center-frequency != null: data.add-data-uint CENTER-FREQUENCY center-frequency
    if tx-power != null: data.add-data-uint TX-POWER tx-power
    if preamble-length != null: data.add-data-uint PREAMBLE-LENGTH preamble-length
    if crc-on != null: data.add-data-bool CRC-ON crc-on
    if iq-inverted != null: data.add-data-bool IQ-INVERTED iq-inverted
    if fixed-length != null: data.add-data-bool FIXED-LENGTH fixed-length
    if payload-length != null: data.add-data-uint PAYLOAD-LENGTH payload-length
    if max-payload-length != null: data.add-data-uint MAX-PAYLOAD-LENGTH max-payload-length
    if symbol-timeout != null: data.add-data-uint SYMBOL-TIMEOUT symbol-timeout
    if public-network != null: data.add-data-bool PUBLIC-NETWORK public-network
    return data

  /**
   * Creates a GET Request message for LoRa Config.
   *
   * Returns: A Message ready to be sent
   */
  static get-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-GET base-data

  /**
   * Creates a SET Request message for LoRa Config.
   *
   * Returns: A Message ready to be sent
   */
  static set-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-SET base-data

  /**
   * Config Slot
   */
  config-slot -> int:
    return get-data-uint CONFIG-SLOT

  /**
   * 7..12
   */
  spread-factor -> int:
    return get-data-uint SPREAD-FACTOR

  /**
   * 1..4 maps to 4/5,4/6,4/7,4/8
   */
  coding-rate -> int:
    return get-data-uint CODING-RATE

  /**
   * 0..2 maps to 125/250/500kHz
   */
  bandwidth -> int:
    return get-data-uint BANDWIDTH

  /**
   * 860000000..950000000
   *
   * Unit: hz
   */
  center-frequency -> int:
    return get-data-uint CENTER-FREQUENCY

  /**
   * 0..22
   */
  tx-power -> int:
    return get-data-uint TX-POWER

  /**
   * 4..128
   */
  preamble-length -> int:
    return get-data-uint PREAMBLE-LENGTH

  /**
   * CRC On
   */
  crc-on -> bool:
    return get-data-bool CRC-ON

  /**
   * IQ Inverted
   */
  iq-inverted -> bool:
    return get-data-bool IQ-INVERTED

  /**
   * Fixed Length
   */
  fixed-length -> bool:
    return get-data-bool FIXED-LENGTH

  /**
   * 0..64
   */
  payload-length -> int:
    return get-data-uint PAYLOAD-LENGTH

  /**
   * 1..64
   */
  max-payload-length -> int:
    return get-data-uint MAX-PAYLOAD-LENGTH

  /**
   * Symbol Timeout
   */
  symbol-timeout -> int:
    return get-data-uint SYMBOL-TIMEOUT

  /**
   * Public Network
   */
  public-network -> bool:
    return get-data-bool PUBLIC-NETWORK

  stringify -> string:
    return {
      "configSlot": config-slot,
      "spreadFactor": spread-factor,
      "codingRate": coding-rate,
      "bandwidth": bandwidth,
      "centerFrequency": center-frequency,
      "txPower": tx-power,
      "preambleLength": preamble-length,
      "crcOn": crc-on,
      "iqInverted": iq-inverted,
      "fixedLength": fixed-length,
      "payloadLength": payload-length,
      "maxPayloadLength": max-payload-length,
      "symbolTimeout": symbol-timeout,
      "publicNetwork": public-network,
    }.stringify
