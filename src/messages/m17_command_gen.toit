import ..protocol as protocol

// Auto generated class for protocol message
class Command extends protocol.Data:

  static MT := 17
  static MT_NAME := "Command"

  static ARM-MODE := 1
  static ARM-MODE_DISARM := 0
  static ARM-MODE_ARM := 1

  static ARM-MODE_STRINGS := {
    0: "Disarm",
    1: "Arm",
  }

  static arm-mode-from-int value/int -> string:
    return ARM-MODE_STRINGS.get value --if-absent=(: "unknown")

  static DEEP-SLEEP := 2

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
  static data --arm-mode/int?=null --deep-sleep/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if arm-mode != null: data.add-data-uint ARM-MODE arm-mode
    if deep-sleep != null: data.add-data-uint DEEP-SLEEP deep-sleep
    return data

  /**
   * Creates a GET Request message for Command.
   *
   * Returns: A Message ready to be sent
   */
  static get-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-GET base-data

  /**
   * Creates a SET Request message for Command.
   *
   * Returns: A Message ready to be sent
   */
  static set-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-SET base-data

  /**
   * 0 = disarm, 1 = arm. Only available on devices that can be armed.
   *
   * Valid values:
   * - ARM-MODE_DISARM (0): Disarm
   * - ARM-MODE_ARM (1): Arm
   */
  arm-mode -> int:
    return get-data-uint ARM-MODE

  /**
   * 1 = trigger deep sleep / shipping mode.
   */
  deep-sleep -> int:
    return get-data-uint DEEP-SLEEP

  stringify -> string:
    return {
      "armMode": arm-mode,
      "deepSleep": deep-sleep,
    }.stringify
