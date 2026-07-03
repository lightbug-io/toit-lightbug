import ..protocol as protocol

// Auto generated class for protocol message
class DeviceStatus extends protocol.Data:

  static MT := 34
  static MT_NAME := "DeviceStatus"

  static BATTERY := 1
  static SIGNAL-STRENGTH := 2
  static MODE := 3
  static MODE_SLEEP := 0
  static MODE_AWAKE := 1

  static MODE_STRINGS := {
    0: "Sleep",
    1: "Awake",
  }

  static mode-from-int value/int -> string:
    return MODE_STRINGS.get value --if-absent=(: "unknown")

  static NETWORK-TYPE := 4
  static NETWORK-TYPE_NO-NETWORK := 0
  static NETWORK-TYPE_GSM := 2
  static NETWORK-TYPE_WCDMA := 3
  static NETWORK-TYPE_LTE := 4

  static NETWORK-TYPE_STRINGS := {
    0: "No network",
    2: "GSM (2G)",
    3: "WCDMA (3G)",
    4: "LTE (4G)",
  }

  static network-type-from-int value/int -> string:
    return NETWORK-TYPE_STRINGS.get value --if-absent=(: "unknown")

  static NETWORK-MNC := 5
  static NETWORK-MCC := 6
  static FIRMWARE-VERSION := 7
  static BATTERY-VOLTAGE := 8
  static DEVICE-TEMPERATURE := 9
  static DEVICE-TYPE := 10
  static CONFIG-CHECKSUM := 11

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
  static data --battery/int?=null --signal-strength/int?=null --mode/int?=null --network-type/int?=null --network-mnc/int?=null --network-mcc/int?=null --firmware-version/int?=null --battery-voltage/int?=null --device-temperature/int?=null --device-type/int?=null --config-checksum/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if battery != null: data.add-data-uint BATTERY battery
    if signal-strength != null: data.add-data-uint SIGNAL-STRENGTH signal-strength
    if mode != null: data.add-data-uint MODE mode
    if network-type != null: data.add-data-uint NETWORK-TYPE network-type
    if network-mnc != null: data.add-data-uint NETWORK-MNC network-mnc
    if network-mcc != null: data.add-data-uint NETWORK-MCC network-mcc
    if firmware-version != null: data.add-data-uint FIRMWARE-VERSION firmware-version
    if battery-voltage != null: data.add-data-uint BATTERY-VOLTAGE battery-voltage
    if device-temperature != null: data.add-data-int DEVICE-TEMPERATURE device-temperature
    if device-type != null: data.add-data-uint DEVICE-TYPE device-type
    if config-checksum != null: data.add-data-uint CONFIG-CHECKSUM config-checksum
    return data

  /**
   * Creates a GET Request message for Device Status.
   *
   * Returns: A Message ready to be sent
   */
  static get-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-GET base-data

  // Subscribe to a message with an optional interval in milliseconds
  static subscribe-msg --interval/int?=null --duration/int?=null --timeout/int?=null -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SUBSCRIBE
    // Subscription header options - only add when provided
    if interval != null:
      msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-INTERVAL interval
    if duration != null:
      msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-DURATION duration
    if timeout != null:
      msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-TIMEOUT timeout
    return msg

  /**
   * Creates a UNSUBSCRIBE Request message for Device Status.
   *
   * Returns: A Message ready to be sent
   */
  static unsubscribe-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-UNSUBSCRIBE base-data

  /**
   * Battery level
   *
   * Unit: %
   */
  battery -> int:
    return get-data-uint BATTERY

  /**
   * Signal strength
   *
   * Unit: %
   */
  signal-strength -> int:
    return get-data-uint SIGNAL-STRENGTH

  /**
   * Device mode
   *
   * Valid values:
   * - MODE_SLEEP (0): Sleep
   * - MODE_AWAKE (1): Awake
   */
  mode -> int:
    return get-data-uint MODE

  /**
   * Network type
   *
   * Valid values:
   * - NETWORK-TYPE_NO-NETWORK (0): No network
   * - NETWORK-TYPE_GSM (2): GSM (2G)
   * - NETWORK-TYPE_WCDMA (3): WCDMA (3G)
   * - NETWORK-TYPE_LTE (4): LTE (4G)
   */
  network-type -> int:
    return get-data-uint NETWORK-TYPE

  /**
   * MNC of the currently connected network.
   * Can be 0 if not connected.
   * See <a href="https://mcc-mnc.net/" target="_blank">mcc-mnc.net</a>
   */
  network-mnc -> int:
    return get-data-uint NETWORK-MNC

  /**
   * MCC of the currently connected network.
   * Can be 0 if not connected.
   * See <a href="https://mcc-mnc.net/" target="_blank">mcc-mnc.net</a>
   */
  network-mcc -> int:
    return get-data-uint NETWORK-MCC

  /**
   * Firmware version as a single integer, e.g. 2287
   */
  firmware-version -> int:
    return get-data-uint FIRMWARE-VERSION

  /**
   * Battery voltage in millivolts
   *
   * Unit: mV
   */
  battery-voltage -> int:
    return get-data-uint BATTERY-VOLTAGE

  // [unit: C]
  device-temperature -> float:
    return (get-data-int DEVICE-TEMPERATURE) / 100.0

  // [unit: cC] Temperature in centi-degrees Celsius
  device-temperature-raw -> int:
    return get-data-int DEVICE-TEMPERATURE

  /**
   * Type of device, relates to the SN prefix.
   * For devices released from 2025 onwards, this is documented on the device specification page.
   */
  device-type -> int:
    return get-data-uint DEVICE-TYPE

  /**
   * Checksum of the base device config, used to determine if the device config has changed since last time it was read.
   * This will likely be removed in favor of a more robust config versioning system in future (config messages and summaries).
   */
  config-checksum -> int:
    return get-data-uint CONFIG-CHECKSUM

  stringify -> string:
    return {
      "bat": battery,
      "signalStrength": signal-strength,
      "mode": mode,
      "networkType": network-type,
      "mnc": network-mnc,
      "mcc": network-mcc,
      "fw": firmware-version,
      "batVoltage": battery-voltage,
      "temperature": device-temperature,
      "deviceType": device-type,
      "configCsum": config-checksum,
    }.stringify
