import ..protocol as protocol

// Auto generated class for protocol message
class GPSControl extends protocol.Data:

  static MT := 39
  static MT_NAME := "GPSControl"

  static GPS-IS-ON := 1
  static CORRECTIONS-ENABLED := 2
  static CORRECTIONS-ENABLED_DISABLED := 0
  static CORRECTIONS-ENABLED_FULL-RTCM-STREAM := 1

  static CORRECTIONS-ENABLED_STRINGS := {
    0: "Disabled",
    1: "Full RTCM stream",
  }

  static corrections-enabled-from-int value/int -> string:
    return CORRECTIONS-ENABLED_STRINGS.get value --if-absent=(: "unknown")

  static START-MODE := 3
  static START-MODE_NORMAL := 1
  static START-MODE_COLD := 2
  static START-MODE_WARM := 3
  static START-MODE_HOT := 4

  static START-MODE_STRINGS := {
    1: "Normal",
    2: "Cold",
    3: "Warm",
    4: "Hot",
  }

  static start-mode-from-int value/int -> string:
    return START-MODE_STRINGS.get value --if-absent=(: "unknown")


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
  static data --corrections-enabled/int?=null --start-mode/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if corrections-enabled != null: data.add-data-uint CORRECTIONS-ENABLED corrections-enabled
    if start-mode != null: data.add-data-uint START-MODE start-mode
    return data

  /**
   * Creates a GET Request message for GPS Control.
   *
   * Returns: A Message ready to be sent
   */
  static get-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-GET base-data

  /**
   * Creates a GET Response message for GPS Control.
   *
   * Parameters:
   * - corrections-enabled: Request and apply correction data to the GPS, such as RTK.
   *  (valid values: Disabled, Full RTCM stream)
   *
   * Returns: A Message ready to be sent
   */
  static get-msg-response -> protocol.Message
      --corrections-enabled/int?=null
      --base-data/protocol.Data?=protocol.Data:
    data-obj := data --corrections-enabled=corrections-enabled --base-data=base-data
    return protocol.Message.with-method MT protocol.Header.METHOD-GET data-obj

  /**
   * Creates a SET Request message for GPS Control.
   *
   * Parameters:
   * - corrections-enabled: Request and apply correction data to the GPS, such as RTK.
   *  (valid values: Disabled, Full RTCM stream)
   * - start-mode: Start mode of the GPS module.
   *  (valid values: Normal, Cold, Warm, Hot)
   *
   * Returns: A Message ready to be sent
   */
  static set-msg -> protocol.Message
      --corrections-enabled/int?=null
      --start-mode/int?=null
      --base-data/protocol.Data?=protocol.Data:
    data-obj := data --corrections-enabled=corrections-enabled --start-mode=start-mode --base-data=base-data
    return protocol.Message.with-method MT protocol.Header.METHOD-SET data-obj

  /**
   * Creates a SET Response message for GPS Control.
   *
   * Returns: A Message ready to be sent
   */
  static set-msg-response --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-SET base-data

  /**
   * Status of the GPS, is it on?
   */
  gps-is-on -> bool:
    return get-data-bool GPS-IS-ON

  /**
   * Request and apply correction data to the GPS, such as RTK.
   *
   * Valid values:
   * - CORRECTIONS-ENABLED_DISABLED (0): Disabled
   * - CORRECTIONS-ENABLED_FULL-RTCM-STREAM (1): Full RTCM stream
   */
  corrections-enabled -> int:
    return get-data-uint CORRECTIONS-ENABLED

  /**
   * Start mode of the GPS module.
   *
   * Valid values:
   * - START-MODE_NORMAL (1): Normal
   * - START-MODE_COLD (2): Cold
   * - START-MODE_WARM (3): Warm
   * - START-MODE_HOT (4): Hot
   */
  start-mode -> int:
    return get-data-uint START-MODE

  stringify -> string:
    return {
      "GPS is on": gps-is-on,
      "Corrections Enabled": corrections-enabled,
      "Start Mode": start-mode,
    }.stringify
