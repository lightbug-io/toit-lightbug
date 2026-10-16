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

  static WAKE-MESSAGE-TYPES ::= 3
  static SLEEP-TRANSITION ::= 11
  static WAKE-MECHANISM ::= 12
  static WAKE-TIMING ::= 50
  static WAKE-CYCLE ::= 51
  static TIMING-FLAGS ::= 52
  static WAKE-REASON ::= 53
  static IRQ-TO-TRIGGER-MS ::= 54
  static TRIGGER-TO-PULSE-MS ::= 55
  static PULSE-TO-AWAKE-MS ::= 56
  static TRIGGER-TO-AWAKE-MS ::= 57
  static WAKE-ATTEMPTS ::= 58
  static P2-APP-START-US ::= 59
  static P2-UART-READY-US ::= 60
  static P2-AWAKE-SENT-US ::= 61
  // Reserved development telemetry; deliberately absent from the public schema.
  static P2-RESET-REASON ::= 62
  static P2-WAKE-CAUSE ::= 63
  static P2-FIRST-REQUEST-US ::= 64
  static P2-FIRST-RESPONSE-US ::= 65
  static P2-FIRST-RX-RESTORED-US ::= 66
  static P2-TX-FLUSH-TO-RX-US ::= 67
  static P2-REQUEST-COUNT ::= 68
  static P2-I2C-READY-US ::= 69
  static P2-TYPE-READY-US ::= 70
  static P2-BUTTON-COUNT ::= 71
  static P2-LAST-BUTTON-ID ::= 72
  static P2-LAST-COMMAND ::= 73

  static AWAKE ::= 0
  static PREPARE-DEEP-SLEEP ::= 1
  static SCL-PULSE ::= 0

  static prepare-deep-sleep-msg --wake-message-types/List=[38, 48] -> protocol.Message:
    if wake-message-types.is-empty: throw "wake-message-types must not be empty"
    data := protocol.Data
    data.add-data-uint8 SLEEP-TRANSITION PREPARE-DEEP-SLEEP
    data.add-data-uint8 WAKE-MECHANISM SCL-PULSE
    data.add-data-list-uint16 WAKE-MESSAGE-TYPES wake-message-types
    return set-msg --base-data=data

  static awake-msg --app-start-us/int?=null --uart-ready-us/int?=null
      --awake-sent-us/int?=null --reset-reason/int?=null --wake-cause/int?=null
      --i2c-ready-us/int?=null --type-ready-us/int?=null -> protocol.Message:
    data := protocol.Data
    data.add-data-uint8 SLEEP-TRANSITION AWAKE
    if app-start-us != null or uart-ready-us != null or awake-sent-us != null:
      if app-start-us == null or uart-ready-us == null or awake-sent-us == null:
        throw "provide all three P2 timestamps"
      [app-start-us, uart-ready-us, awake-sent-us].do:
        if it < 0 or it > 0xffff_ffff: throw "P2 timestamp exceeds uint32"
      data.add-data-uint32 P2-APP-START-US app-start-us
      data.add-data-uint32 P2-UART-READY-US uart-ready-us
      data.add-data-uint32 P2-AWAKE-SENT-US awake-sent-us
    if (reset-reason == null) != (wake-cause == null): throw "provide both P2 reset and wake causes"
    if (i2c-ready-us == null) != (type-ready-us == null): throw "provide both P2 setup timestamps"
    if reset-reason != null and (reset-reason < 0 or reset-reason > 255 or wake-cause < 0 or wake-cause > 255):
      throw "P2 reset or wake cause exceeds uint8"
    add-optional-uint32_ data P2-RESET-REASON reset-reason
    add-optional-uint32_ data P2-WAKE-CAUSE wake-cause
    add-optional-uint32_ data P2-I2C-READY-US i2c-ready-us
    add-optional-uint32_ data P2-TYPE-READY-US type-ready-us
    return set-msg --base-data=data

  static add-optional-uint32_ data/protocol.Data key/int value/int?:
    if value == null: return
    if value < 0 or value > 0xffff_ffff: throw "P2 timing value exceeds uint32"
    data.add-data-uint32 key value

  static report-timing-msg --request-count/int --first-request-us/int?=null
      --first-response-us/int?=null --first-rx-restored-us/int?=null
      --tx-flush-to-rx-us/int?=null --button-count/int=0 --last-button-id/int?=null
      --last-command/int?=null -> protocol.Message:
    data := protocol.Data
    data.add-data-bool WAKE-TIMING true
    add-optional-uint32_ data P2-FIRST-REQUEST-US first-request-us
    add-optional-uint32_ data P2-FIRST-RESPONSE-US first-response-us
    add-optional-uint32_ data P2-FIRST-RX-RESTORED-US first-rx-restored-us
    add-optional-uint32_ data P2-TX-FLUSH-TO-RX-US tx-flush-to-rx-us
    add-optional-uint32_ data P2-REQUEST-COUNT request-count
    add-optional-uint32_ data P2-BUTTON-COUNT button-count
    add-optional-uint32_ data P2-LAST-BUTTON-ID last-button-id
    add-optional-uint32_ data P2-LAST-COMMAND last-command
    return set-msg --base-data=data

  static wake-timing-msg -> protocol.Message:
    data := protocol.Data
    data.add-data-bool WAKE-TIMING true
    return get-msg --base-data=data

  /** Missing samples stay null; zero is a valid measured interval. */
  wake-timing -> Map:
    output := {:}
    {"cycle": WAKE-CYCLE, "flags": TIMING-FLAGS, "reason": WAKE-REASON,
        "attempts": WAKE-ATTEMPTS, "irq_to_trigger_ms": IRQ-TO-TRIGGER-MS,
        "trigger_to_pulse_ms": TRIGGER-TO-PULSE-MS,
        "pulse_to_awake_ms": PULSE-TO-AWAKE-MS,
        "trigger_to_awake_ms": TRIGGER-TO-AWAKE-MS,
        "p2_app_start_us": P2-APP-START-US, "p2_uart_ready_us": P2-UART-READY-US,
        "p2_awake_sent_us": P2-AWAKE-SENT-US, "reset_reason": P2-RESET-REASON,
        "wake_cause": P2-WAKE-CAUSE, "p2_i2c_ready_us": P2-I2C-READY-US,
        "p2_type_ready_us": P2-TYPE-READY-US}.do: | name key |
      output[name] = (has-data key) ? (get-data-uint key) : null
    return output

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
