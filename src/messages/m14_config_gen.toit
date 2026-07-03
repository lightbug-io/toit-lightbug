import ..protocol as protocol

// Auto generated class for protocol message
class Config extends protocol.Data:

  static MT := 14
  static MT_NAME := "Config"

  static COMMAND := 3
  static COMMAND_PARTIAL-WIPE := 1
  static COMMAND_FULL-WIPE := 2

  static COMMAND_STRINGS := {
    1: "Partial Wipe",
    2: "Full Wipe",
  }

  static command-from-int value/int -> string:
    return COMMAND_STRINGS.get value --if-absent=(: "unknown")

  static SUMMARY-OF-UINT8-KEYS := 4
  static SUMMARY-OF-UINT16-KEYS := 5
  static KEY := 7
  static KEY_BASESETTINGS := 1
  static KEY_HOMEWIFI := 2
  static KEY_TIMEDSETTINGS := 5
  static KEY_UNIXALARMS := 6
  static KEY_RTKMINUSABLESATDB := 19
  static KEY_RTKMINELEVATION := 20
  static KEY_SECONDARY-SERVER := 27
  static KEY_PRIMARY-SERVER := 28
  static KEY_LINK-2-TIMEOUT := 30
  static KEY_QUIET-MODE := 31
  static KEY_USB-LOCK := 32
  static KEY_LED-RESTING-ARMED-COLOR := 33
  static KEY_BLE-NAME-FILTER-PREFIX := 34
  static KEY_ARMING-MODE := 50
  static KEY_SILO-ID := 32777
  static KEY_SERIAL-NUMBER := 32780

  static KEY_STRINGS := {
    1: "BaseSettings",
    2: "HomeWifi",
    5: "TimedSettings",
    6: "UnixAlarms",
    19: "RtkMinUsableSatDb",
    20: "RtkMinElevation",
    27: "Secondary Server",
    28: "Primary Server",
    30: "Link 2 Timeout",
    31: "Quiet Mode",
    32: "USB Lock",
    33: "LED Resting Armed Color",
    34: "BLE Name Filter Prefix",
    50: "Arming Mode",
    32777: "Silo ID",
    32780: "Serial Number",
  }

  static key-from-int value/int -> string:
    return KEY_STRINGS.get value --if-absent=(: "unknown")

  static PAYLOAD := 9

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
  static data --command/int?=null --summary-of-uint8-keys/int?=null --summary-of-uint16-keys/ByteArray?=null --key/int?=null --payload/ByteArray?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if command != null: data.add-data-uint COMMAND command
    if summary-of-uint8-keys != null: data.add-data-uint SUMMARY-OF-UINT8-KEYS summary-of-uint8-keys
    if summary-of-uint16-keys != null: data.add-data SUMMARY-OF-UINT16-KEYS summary-of-uint16-keys
    if key != null: data.add-data-uint KEY key
    if payload != null: data.add-data PAYLOAD payload
    return data

  /**
   * Creates a Config message without a specific method.
   *
   * This is used for messages that don't require a specific method type
   * (like GET, SET, SUBSCRIBE) but still need to carry data.
   *
   * Parameters:
   * - data: Optional protocol.Data object containing message payload
   *
   * Returns: A Message ready to be sent
   */
  static msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-data MT data

  /**
   * Creates a GET Request message for Config.
   *
   * Returns: A Message ready to be sent
   */
  static get-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-GET base-data

  /**
   * Creates a SET Request message for Config.
   *
   * Returns: A Message ready to be sent
   */
  static set-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-SET base-data

  /**
   * Command
   *
   * Valid values:
   * - COMMAND_PARTIAL-WIPE (1): Wipe some config values, such as WiFi credentials, but not all config
   * Same as reset=1 in old lightbug device config.
   *
   * - COMMAND_FULL-WIPE (2): Wipe all config values, returning the device to a factory new state.
   * Same as reset=2 in old lightbug device config.
   */
  command -> int:
    return get-data-uint COMMAND

  /**
   * A table of uint8 keys known, with the crc8 of the value.
   * eg: 123, 45, 124, 67 means key 123 has a value with crc8 of 45, and key 124 has a value with crc8 of 67.
   * May be sent, with the expectation of receiving config messages with the listed keys and values that need changing
   */
  summary-of-uint8-keys -> int:
    return get-data-uint SUMMARY-OF-UINT8-KEYS

  /**
   * A table of uint16 keys known, with the crc8 of the value.
   * eg: 123, 0, 45, means key 123 has a value with crc8 of 45.
   * May be sent, with the expectation of receiving config messages with the listed keys and values that need changing
   */
  summary-of-uint16-keys -> ByteArray:
    return get-data SUMMARY-OF-UINT16-KEYS

  /**
   * Key
   *
   * Valid values:
   * - KEY_BASESETTINGS (1): 24 bytes of basic device settings (intervals, modes, etc.)
   * - KEY_HOMEWIFI (2): HomeWifi
   * - KEY_TIMEDSETTINGS (5): TimedSettings
   * - KEY_UNIXALARMS (6): UnixAlarms
   * - KEY_RTKMINUSABLESATDB (19): Minimum usable satellite db
   * - KEY_RTKMINELEVATION (20): RtkMinElevation
   * - KEY_SECONDARY-SERVER (27): A FQDN or IP of a secondary server for the second link.
   * - KEY_PRIMARY-SERVER (28): FQDN or IP of the primary server for the first link.
   * - KEY_LINK-2-TIMEOUT (30): Timeout in seconds for the secondary link before it is considered dropped. Triggers the "No Connection" screen and alerts.
   * - KEY_QUIET-MODE (31): When non-zero, suppresses notifications (buzzer, LEDs, etc.).
   * - KEY_USB-LOCK (32): When non-zero, USB access is locked (usb pins are switched to i2c bus).
   * - KEY_LED-RESTING-ARMED-COLOR (33): RGB color when armed = true (3 bytes RGB  + 1 mode). [m,R,G,B] for the status LED when armed. m=2 enables breathing
   * - KEY_BLE-NAME-FILTER-PREFIX (34): Collection of null terminated strings. Expected format is [prefix1]\0[prefix2]\0[prefix3]\0
   * - KEY_ARMING-MODE (50): Bitmask controlling device behaviour when armed. Value 0x00 = default (active when armed).
   *
   * - KEY_SILO-ID (32777): Silo ID for the device, used to determine which silo to connect to.
   * - KEY_SERIAL-NUMBER (32780): Integer representation of the device serial number.
   * Currently only used for some devices and in some contexts.
   */
  key -> int:
    return get-data-uint KEY

  /**
   * Payload for the config.
   * Setting a key to a 0 length value may be used to clear the config value for that key.
   */
  payload -> ByteArray:
    return get-data PAYLOAD

  stringify -> string:
    return {
      "cmd": command,
      "summary8": summary-of-uint8-keys,
      "summary16": summary-of-uint16-keys,
      "key": key,
      "payload": payload,
    }.stringify
