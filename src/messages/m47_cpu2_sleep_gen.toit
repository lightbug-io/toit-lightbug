import ..protocol as protocol

// Auto generated class for protocol message
class CPU2Sleep extends protocol.Data:

  static MT := 47
  static MT_NAME := "CPU2Sleep"

  static WAKE-ON-EVENT := 2
  static WIFI-OVERRIDE-MODE := 10
  static WIFI-OVERRIDE-MODE_FORCE-OFF := 0
  static WIFI-OVERRIDE-MODE_FORCE-ON := 1
  static WIFI-OVERRIDE-MODE_CLEAR-OVERRIDE := 2

  static WIFI-OVERRIDE-MODE_STRINGS := {
    0: "Force Off",
    1: "Force On",
    2: "Clear Override",
  }

  static wifi-override-mode-from-int value/int -> string:
    return WIFI-OVERRIDE-MODE_STRINGS.get value --if-absent=(: "unknown")


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
  static data --wake-on-event/bool?=null --wifi-override-mode/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if wake-on-event != null: data.add-data-bool WAKE-ON-EVENT wake-on-event
    if wifi-override-mode != null: data.add-data-uint WIFI-OVERRIDE-MODE wifi-override-mode
    return data

  /**
   * Creates a GET Request message for CPU2 Sleep.
   *
   * Returns: A Message ready to be sent
   */
  static get-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-GET base-data

  /**
   * Creates a SET Request message for CPU2 Sleep.
   *
   * Returns: A Message ready to be sent
   */
  static set-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-SET base-data

  /**
   * Should CPU1 wake up CPU2 on new events / messages
   */
  wake-on-event -> bool:
    return get-data-bool WAKE-ON-EVENT

  /**
   * Forced WiFi override mode.
   *
   * Valid values:
   * - WIFI-OVERRIDE-MODE_FORCE-OFF (0): Force WiFi off for the Duration timeout (or indefinitely if Duration is omitted).
   * - WIFI-OVERRIDE-MODE_FORCE-ON (1): Force WiFi on for the Duration timeout (or indefinitely if Duration is omitted).
   * - WIFI-OVERRIDE-MODE_CLEAR-OVERRIDE (2): Clear any forced WiFi override and return to normal WiFi power behavior.
   */
  wifi-override-mode -> int:
    return get-data-uint WIFI-OVERRIDE-MODE

  stringify -> string:
    return {
      "wakeOnEvent": wake-on-event,
      "wifiOnOff": wifi-override-mode,
    }.stringify
