import ..protocol as protocol

// Auto generated class for protocol message
class Close extends protocol.Data:

  static MT := 12
  static MT_NAME := "Close"

  static ARM-STATE := 6

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
  static data --arm-state/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if arm-state != null: data.add-data-uint ARM-STATE arm-state
    return data

  /**
   * Creates a Close message without a specific method.
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
   * Arm state of the device at the time of close. Only values 0 and 1 are used presently;
   * all other values are reserved.
   * Primary use is with the "Wake On Move" setting (config key ArmingMode = 50),
   * so that the remote can determine if the device is "sleeping" (armed) or "off" (disarmed).
   * 0 = disarmed/off, 1 = armed/sleeping.
   */
  arm-state -> int:
    return get-data-uint ARM-STATE

  stringify -> string:
    return {
      "armState": arm-state,
    }.stringify
