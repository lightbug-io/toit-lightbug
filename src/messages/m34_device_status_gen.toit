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
  static DEVICE-TYPE := 10

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
  static data --battery/int?=null --signal-strength/int?=null --mode/int?=null --network-type/int?=null --network-mnc/int?=null --network-mcc/int?=null --firmware-version/int?=null --device-type/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if battery != null: data.add-data-uint BATTERY battery
    if signal-strength != null: data.add-data-uint SIGNAL-STRENGTH signal-strength
    if mode != null: data.add-data-uint MODE mode
    if network-type != null: data.add-data-uint NETWORK-TYPE network-type
    if network-mnc != null: data.add-data-uint NETWORK-MNC network-mnc
    if network-mcc != null: data.add-data-uint NETWORK-MCC network-mcc
    if firmware-version != null: data.add-data-uint FIRMWARE-VERSION firmware-version
    if device-type != null: data.add-data-uint DEVICE-TYPE device-type
    return data

  /**
   * Creates a GET Request message for Device Status.
   *
   * Returns: A Message ready to be sent
   */
  static get-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-GET base-data

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
   * - NETWORK-TYPE_GSM-(2G) (2): GSM (2G)
   * - NETWORK-TYPE_WCDMA-(3G) (3): WCDMA (3G)
   * - NETWORK-TYPE_LTE-(4G) (4): LTE (4G)
   */
  network-type -> int:
    return get-data-uint NETWORK-TYPE

  /**
   * Network MNC
   */
  network-mnc -> int:
    return get-data-uint NETWORK-MNC

  /**
   * Network MCC
   */
  network-mcc -> int:
    return get-data-uint NETWORK-MCC

  /**
   * Firmware Version
   */
  firmware-version -> int:
    return get-data-uint FIRMWARE-VERSION

  /**
   * Type of device, relates to the SN prefix
   */
  device-type -> int:
    return get-data-uint DEVICE-TYPE

  stringify -> string:
    return {
      "Battery": battery,
      "Signal Strength": signal-strength,
      "Mode": mode,
      "Network type": network-type,
      "Network MNC": network-mnc,
      "Network MCC": network-mcc,
      "Firmware Version": firmware-version,
      "Device Type": device-type,
    }.stringify
