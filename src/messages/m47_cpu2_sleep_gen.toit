import ..protocol as protocol

// Auto generated class for protocol message
class CPU2Sleep extends protocol.Data:

  static MT := 47
  static MT_NAME := "CPU2Sleep"

  static INTERVAL := 1
  static WAKE-ON-EVENT := 2

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
  static data --interval/int?=null --wake-on-event/bool?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if interval != null: data.add-data-uint INTERVAL interval
    if wake-on-event != null: data.add-data-bool WAKE-ON-EVENT wake-on-event
    return data

  /**
   * Creates a DO Request message for CPU2 Sleep.
   */
  
  /**
   * Returns: A Message ready to be sent
   */
  static do-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-DO base-data

  /**
   * Interval in ms to turn off the CPU2 for, before turning it back on
   */
  interval -> int:
    return get-data-uint INTERVAL

  /**
   * Should CPU1 wake up CPU2 on new events / messages
   */
  wake-on-event -> bool:
    return get-data-bool WAKE-ON-EVENT

  stringify -> string:
    return {
      "Interval": interval,
      "Wake on Event": wake-on-event,
    }.stringify
